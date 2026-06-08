package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/config"
)

// DevHandler expõe um login fake pra desenvolvimento. Só é montado quando
// cfg.DevMode == true. Cria (ou recupera) um usuário em auth.users via Supabase
// Admin API, garante um profile e devolve um JWT HS256 assinado com o mesmo
// JWT secret que o middleware valida.
type DevHandler struct {
	cfg config.Config
	db  *pgxpool.Pool
	hc  *http.Client
}

func NewDevHandler(cfg config.Config, db *pgxpool.Pool) *DevHandler {
	return &DevHandler{
		cfg: cfg,
		db:  db,
		hc:  &http.Client{Timeout: 10 * time.Second},
	}
}

type devLoginReq struct {
	Nome  string `json:"nome"`
	Email string `json:"email"` // opcional; se vier, loga como esse user já existente
}

type devLoginResp struct {
	Token  string    `json:"token"`
	UserID uuid.UUID `json:"user_id"`
	Email  string    `json:"email"`
	Nome   string    `json:"nome"`
}

// POST /dev/login  {nome?: string}
//
// Idempotente: chama várias vezes com o mesmo nome e devolve o mesmo user_id.
// Token expira em 7 dias — suficiente pra dev.
func (h *DevHandler) Login(c *gin.Context) {
	var req devLoginReq
	_ = c.ShouldBindJSON(&req)
	nome := strings.TrimSpace(req.Nome)
	if nome == "" {
		nome = "Dev User"
	}
	email := strings.TrimSpace(req.Email)
	if email == "" {
		email = fmt.Sprintf("dev+%s@local.test", slug(nome))
	}

	ctx := c.Request.Context()

	uid, err := h.findOrCreateUser(ctx, email, nome)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ensure user: " + err.Error()})
		return
	}

	if _, err := h.db.Exec(ctx, `
		insert into profiles (id, nome) values ($1,$2)
		on conflict (id) do update set nome = excluded.nome
	`, uid, nome); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "upsert profile: " + err.Error()})
		return
	}

	token, err := h.mintJWT(uid, email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "mint jwt: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, devLoginResp{
		Token: token, UserID: uid, Email: email, Nome: nome,
	})
}

func (h *DevHandler) findOrCreateUser(ctx context.Context, email, nome string) (uuid.UUID, error) {
	// 1. já existe? (lookup direto via SQL — temos acesso superuser)
	var id uuid.UUID
	err := h.db.QueryRow(ctx, `select id from auth.users where email = $1`, email).Scan(&id)
	if err == nil {
		return id, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, err
	}

	// 2. cria via Admin API (cuida de todas as colunas obrigatórias)
	body, _ := json.Marshal(map[string]any{
		"email":         email,
		"password":      "dev-only-" + uuid.NewString(),
		"email_confirm": true,
		"user_metadata": map[string]string{"nome": nome, "source": "dev_login"},
	})
	url := strings.TrimRight(h.cfg.SupabaseURL, "/") + "/auth/v1/admin/users"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return uuid.Nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", h.cfg.SupabaseSecretKey)
	req.Header.Set("Authorization", "Bearer "+h.cfg.SupabaseSecretKey)

	resp, err := h.hc.Do(req)
	if err != nil {
		return uuid.Nil, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return uuid.Nil, fmt.Errorf("admin api %d: %s", resp.StatusCode, string(raw))
	}

	var out struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(raw, &out); err != nil {
		return uuid.Nil, fmt.Errorf("decode admin resp: %w", err)
	}
	return uuid.Parse(out.ID)
}

func (h *DevHandler) mintJWT(uid uuid.UUID, email string) (string, error) {
	now := time.Now()
	claims := jwt.MapClaims{
		"sub":   uid.String(),
		"email": email,
		"role":  "authenticated",
		"aud":   "authenticated",
		"iss":   "permuta-dev",
		"iat":   now.Unix(),
		"exp":   now.Add(7 * 24 * time.Hour).Unix(),
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return tok.SignedString([]byte(h.cfg.SupabaseJWTSecret))
}

func slug(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	var b strings.Builder
	for _, r := range s {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9':
			b.WriteRune(r)
		case r == ' ', r == '-', r == '_':
			b.WriteByte('-')
		}
	}
	out := b.String()
	if out == "" {
		out = "dev"
	}
	return out
}
