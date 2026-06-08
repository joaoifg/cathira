package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type AuthHandler struct{ db *pgxpool.Pool }

func NewAuthHandler(db *pgxpool.Pool) *AuthHandler { return &AuthHandler{db: db} }

type meReq struct {
	Nome    string  `json:"nome"    binding:"required,min=2,max=80"`
	FotoURL *string `json:"foto_url"`
	Cidade  *string `json:"cidade"`
}

// POST /auth/me — upsert do profile a partir do JWT do Supabase.
// Idempotente: pode ser chamado a cada login para sincronizar nome/foto.
func (h *AuthHandler) Me(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	var req meReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	_, err := h.db.Exec(c.Request.Context(), `
		insert into profiles (id, nome, foto_url, cidade)
		values ($1,$2,$3,$4)
		on conflict (id) do update
		   set nome     = excluded.nome,
		       foto_url = coalesce(excluded.foto_url, profiles.foto_url),
		       cidade   = coalesce(excluded.cidade,   profiles.cidade)
	`, uid, req.Nome, req.FotoURL, req.Cidade)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"id": uid})
}
