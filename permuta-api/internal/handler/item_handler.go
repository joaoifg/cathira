package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
	"github.com/joaohenriqueoci/permuta-api/internal/service"
)

type ItemHandler struct{ svc *service.LoteService }

func NewItemHandler(s *service.LoteService) *ItemHandler { return &ItemHandler{svc: s} }

func (h *ItemHandler) AddToLote(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	loteID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id de lote inválido"})
		return
	}
	var in domain.NovoItem
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	it, err := h.svc.AddItem(c.Request.Context(), uid, loteID, in)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, it)
}

func (h *ItemHandler) Create(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	var in domain.NovoItem
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	it, err := h.svc.CreateItem(c.Request.Context(), uid, in)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, it)
}

func (h *ItemHandler) Meus(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	out, err := h.svc.MyItens(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, out)
}

type moveItemReq struct {
	LoteID *uuid.UUID `json:"lote_id"`
}

// PATCH /itens/:id — move pra outro lote ou solta (lote_id = null).
func (h *ItemHandler) Move(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	itemID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var req moveItemReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	it, err := h.svc.MoveItem(c.Request.Context(), uid, itemID, req.LoteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, it)
}
