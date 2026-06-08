package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type MensagemHandler struct{ db *pgxpool.Pool }

func NewMensagemHandler(db *pgxpool.Pool) *MensagemHandler { return &MensagemHandler{db: db} }

type novaMensagemReq struct {
	Texto string `json:"texto" binding:"required,min=1,max=2000"`
}

// POST /negociacoes/:id/mensagens
func (h *MensagemHandler) Send(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	negID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var req novaMensagemReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var participa bool
	if err := h.db.QueryRow(c.Request.Context(), `
		select exists(select 1 from negociacoes where id=$1 and $2 in (uid_a, uid_b))
	`, negID, uid).Scan(&participa); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if !participa {
		c.JSON(http.StatusForbidden, gin.H{"error": "você não participa dessa negociação"})
		return
	}

	var id uuid.UUID
	var criadoEm any
	err = h.db.QueryRow(c.Request.Context(), `
		insert into mensagens (negociacao_id, sender_id, texto)
		values ($1,$2,$3) returning id, criado_em
	`, negID, uid, req.Texto).Scan(&id, &criadoEm)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{
		"id": id, "negociacao_id": negID, "sender_id": uid,
		"texto": req.Texto, "criado_em": criadoEm,
	})
}

// GET /negociacoes/:id/mensagens
func (h *MensagemHandler) List(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	negID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var participa bool
	if err := h.db.QueryRow(c.Request.Context(), `
		select exists(select 1 from negociacoes where id=$1 and $2 in (uid_a, uid_b))
	`, negID, uid).Scan(&participa); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if !participa {
		c.JSON(http.StatusForbidden, gin.H{"error": "não autorizado"})
		return
	}

	rows, err := h.db.Query(c.Request.Context(), `
		select id, sender_id, texto, tipo, lido, criado_em
		  from mensagens where negociacao_id = $1
		 order by criado_em asc
	`, negID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()
	out := []map[string]any{}
	for rows.Next() {
		var id, sender uuid.UUID
		var texto, tipo string
		var lido bool
		var criadoEm any
		if err := rows.Scan(&id, &sender, &texto, &tipo, &lido, &criadoEm); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		out = append(out, map[string]any{
			"id": id, "sender_id": sender, "texto": texto, "tipo": tipo,
			"lido": lido, "criado_em": criadoEm,
		})
	}
	c.JSON(http.StatusOK, out)
}
