package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type SetorHandler struct{ db *pgxpool.Pool }

func NewSetorHandler(db *pgxpool.Pool) *SetorHandler { return &SetorHandler{db: db} }

type Setor struct {
	Slug         string         `json:"slug"`
	Nome         string         `json:"nome"`
	Faixas       map[string]any `json:"faixas"`
	Categorias   []string       `json:"categorias"`
	CamposExtras map[string]any `json:"campos_extras"`
}

func (h *SetorHandler) List(c *gin.Context) {
	rows, err := h.db.Query(c.Request.Context(), `
		select slug, nome, faixas, categorias, campos_extras, icone, cor, tagline
		  from setores where ativo = true
		 order by nome
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()
	out := []map[string]any{}
	for rows.Next() {
		var slug, nome, icone, cor string
		var tagline *string
		var faixas, categorias, campos any
		if err := rows.Scan(&slug, &nome, &faixas, &categorias, &campos, &icone, &cor, &tagline); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		out = append(out, map[string]any{
			"slug":          slug,
			"nome":          nome,
			"faixas":        faixas,
			"categorias":    categorias,
			"campos_extras": campos,
			"icone":         icone,
			"cor":           cor,
			"tagline":       tagline,
		})
	}
	c.JSON(http.StatusOK, out)
}
