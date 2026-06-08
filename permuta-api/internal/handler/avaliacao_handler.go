package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type AvaliacaoHandler struct{ db *pgxpool.Pool }

func NewAvaliacaoHandler(db *pgxpool.Pool) *AvaliacaoHandler {
	return &AvaliacaoHandler{db: db}
}

type novaAvaliacaoReq struct {
	NegociacaoID uuid.UUID `json:"negociacao_id" binding:"required"`
	Nota         int       `json:"nota"          binding:"required,min=1,max=5"`
	Comentario   string    `json:"comentario"    binding:"omitempty,max=500"`
}

// POST /avaliacoes — só funciona se a negociação está 'aceita' e o user é participante.
func (h *AvaliacaoHandler) Create(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	var req novaAvaliacaoReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var uidA, uidB uuid.UUID
	var status string
	err := h.db.QueryRow(c.Request.Context(), `
		select uid_a, uid_b, status from negociacoes where id = $1
	`, req.NegociacaoID).Scan(&uidA, &uidB, &status)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "negociação não encontrada"})
		return
	}
	if status != "aceita" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "negociação não foi aceita ainda"})
		return
	}
	if uid != uidA && uid != uidB {
		c.JSON(http.StatusForbidden, gin.H{"error": "você não participa dessa negociação"})
		return
	}
	para := uidA
	if uid == uidA {
		para = uidB
	}

	var id uuid.UUID
	err = h.db.QueryRow(c.Request.Context(), `
		insert into avaliacoes (de_id, para_id, negociacao_id, nota, comentario)
		values ($1,$2,$3,$4,$5)
		on conflict (de_id, negociacao_id) do update
		   set nota = excluded.nota, comentario = excluded.comentario
		returning id
	`, uid, para, req.NegociacaoID, req.Nota, req.Comentario).Scan(&id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{
		"id": id, "de_id": uid, "para_id": para,
		"negociacao_id": req.NegociacaoID,
		"nota":          req.Nota, "comentario": req.Comentario,
	})
}
