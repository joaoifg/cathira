package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
	"github.com/joaohenriqueoci/permuta-api/internal/service"
)

type LoteHandler struct{ svc *service.LoteService }

func NewLoteHandler(s *service.LoteService) *LoteHandler { return &LoteHandler{svc: s} }

func (h *LoteHandler) Create(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	var in domain.NovoLote
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	l, err := h.svc.Create(c.Request.Context(), uid, in)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, l)
}

func (h *LoteHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	lote, itens, err := h.svc.Get(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "lote não encontrado"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"lote": lote, "itens": itens})
}

func (h *LoteHandler) Meus(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	out, err := h.svc.MyLotes(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, out)
}

func (h *LoteHandler) Feed(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	var q domain.FeedQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := h.svc.Feed(c.Request.Context(), uid, q)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, res)
}
