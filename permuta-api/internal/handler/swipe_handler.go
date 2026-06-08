package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
	"github.com/joaohenriqueoci/permuta-api/internal/service"
)

type SwipeHandler struct{ svc *service.MatchService }

func NewSwipeHandler(s *service.MatchService) *SwipeHandler { return &SwipeHandler{svc: s} }

func (h *SwipeHandler) Create(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	var in domain.Swipe
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	res, err := h.svc.Swipe(c.Request.Context(), uid, in)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, res)
}
