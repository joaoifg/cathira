package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type DestaqueHandler struct{ db *pgxpool.Pool }

func NewDestaqueHandler(db *pgxpool.Pool) *DestaqueHandler {
	return &DestaqueHandler{db: db}
}

type destacarReq struct {
	Dias int `json:"dias" binding:"required,min=1,max=365"`
}

// Tabela fixa de preços (em centavos). Pra MVP — depois substitui por
// configurável no banco ou pricing dinâmico.
var precoCentavos = map[int]int{
	30:  990,  // R$ 9,90
	60:  1990, // R$ 19,90
	180: 3990, // R$ 39,90
}

// POST /itens/:id/destacar  {dias: 30|60|180}
func (h *DestaqueHandler) DestacarItem(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	itemID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var req destacarReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	preco, ok := precoCentavos[req.Dias]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "duração inválida (use 30, 60 ou 180)"})
		return
	}

	ctx := c.Request.Context()
	// Confirma propriedade.
	var donoID uuid.UUID
	if err := h.db.QueryRow(ctx, `select dono_id from itens where id = $1`, itemID).Scan(&donoID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "item não encontrado"})
		return
	}
	if donoID != uid {
		c.JSON(http.StatusForbidden, gin.H{"error": "item não é seu"})
		return
	}

	tx, err := h.db.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer tx.Rollback(ctx)

	novoVencimento := time.Now().AddDate(0, 0, req.Dias)
	if _, err := tx.Exec(ctx, `
		update itens set destaque_ate = greatest(coalesce(destaque_ate, now()), $1)
		 where id = $2
	`, novoVencimento, itemID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if _, err := tx.Exec(ctx, `
		insert into destaques_pagamentos (alvo_tipo, alvo_id, comprador_id, dias, valor_centavos, status)
		values ('item', $1, $2, $3, $4, 'mock')
	`, itemID, uid, req.Dias, preco); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"alvo_tipo":      "item",
		"alvo_id":        itemID,
		"destaque_ate":   novoVencimento,
		"valor_centavos": preco,
		"dias":           req.Dias,
		"status":         "mock",
		"mensagem":       "Destaque ativado (sem cobrança real — placeholder).",
	})
}

// POST /lotes/:id/destacar  {dias: 30|60|180}
func (h *DestaqueHandler) DestacarLote(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	loteID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var req destacarReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	preco, ok := precoCentavos[req.Dias]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "duração inválida (use 30, 60 ou 180)"})
		return
	}

	ctx := c.Request.Context()
	var donoID uuid.UUID
	if err := h.db.QueryRow(ctx, `select dono_id from lotes where id = $1`, loteID).Scan(&donoID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "lote não encontrado"})
		return
	}
	if donoID != uid {
		c.JSON(http.StatusForbidden, gin.H{"error": "lote não é seu"})
		return
	}

	tx, err := h.db.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer tx.Rollback(ctx)

	novoVencimento := time.Now().AddDate(0, 0, req.Dias)
	if _, err := tx.Exec(ctx, `
		update lotes set destaque_ate = greatest(coalesce(destaque_ate, now()), $1)
		 where id = $2
	`, novoVencimento, loteID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if _, err := tx.Exec(ctx, `
		insert into destaques_pagamentos (alvo_tipo, alvo_id, comprador_id, dias, valor_centavos, status)
		values ('lote', $1, $2, $3, $4, 'mock')
	`, loteID, uid, req.Dias, preco); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"alvo_tipo":      "lote",
		"alvo_id":        loteID,
		"destaque_ate":   novoVencimento,
		"valor_centavos": preco,
		"dias":           req.Dias,
		"status":         "mock",
		"mensagem":       "Destaque ativado (sem cobrança real — placeholder).",
	})
}
