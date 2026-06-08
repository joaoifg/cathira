package handler

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/joaohenriqueoci/permuta-api/internal/config"
	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type UploadHandler struct {
	cfg config.Config
	hc  *http.Client
}

func NewUploadHandler(cfg config.Config) *UploadHandler {
	return &UploadHandler{cfg: cfg, hc: &http.Client{Timeout: 30 * time.Second}}
}

// POST /dev/upload (multipart)
//   file: bytes
//   path: opcional, default <user_uuid>/<timestamp>-<filename>
// Proxia pra Storage do Supabase usando SECRET_KEY (bypass RLS). Devolve a URL pública.
func (h *UploadHandler) Upload(c *gin.Context) {
	uid, _ := middleware.UserID(c)

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "campo 'file' obrigatório: " + err.Error()})
		return
	}
	defer file.Close()

	if header.Size > 5*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "arquivo maior que 5MB"})
		return
	}
	ct := header.Header.Get("Content-Type")
	if !strings.HasPrefix(ct, "image/") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "apenas imagens"})
		return
	}

	path := c.PostForm("path")
	if path == "" {
		ts := time.Now().UnixMilli()
		path = fmt.Sprintf("%s/%d-%s", uid.String(), ts, safeFilename(header.Filename))
	}

	buf := &bytes.Buffer{}
	if _, err := io.Copy(buf, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	url := strings.TrimRight(h.cfg.SupabaseURL, "/") +
		"/storage/v1/object/itens/" + path
	req, _ := http.NewRequestWithContext(c.Request.Context(), http.MethodPost, url, buf)
	req.Header.Set("Content-Type", ct)
	req.Header.Set("apikey", h.cfg.SupabaseSecretKey)
	req.Header.Set("Authorization", "Bearer "+h.cfg.SupabaseSecretKey)

	resp, err := h.hc.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "storage: " + err.Error()})
		return
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		c.JSON(http.StatusBadGateway, gin.H{"error": fmt.Sprintf("storage %d: %s", resp.StatusCode, string(body))})
		return
	}

	publicURL := strings.TrimRight(h.cfg.SupabaseURL, "/") +
		"/storage/v1/object/public/itens/" + path

	c.JSON(http.StatusOK, gin.H{
		"path": path,
		"url":  publicURL,
	})
}

func safeFilename(s string) string {
	var b strings.Builder
	for _, r := range strings.ToLower(s) {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9', r == '.', r == '-', r == '_':
			b.WriteRune(r)
		default:
			b.WriteByte('-')
		}
	}
	out := b.String()
	if len(out) > 80 {
		out = out[len(out)-80:]
	}
	return out
}
