package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
	"github.com/joaohenriqueoci/permuta-api/internal/service"
)

type NegociacaoHandler struct {
	svc *service.NegociacaoService
	db  *pgxpool.Pool
}

func NewNegociacaoHandler(s *service.NegociacaoService, db *pgxpool.Pool) *NegociacaoHandler {
	return &NegociacaoHandler{svc: s, db: db}
}

func (h *NegociacaoHandler) List(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	out, err := h.svc.List(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, out)
}

// GET /negociacoes/:id — devolve a negociação + dados de cada lado:
//   - perfil do outro
//   - lotes envolvidos
//   - todos os itens dos dois lotes (pra a mesa saber o que pode entrar)
func (h *NegociacaoHandler) Detalhe(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	ctx := c.Request.Context()

	n, err := h.svc.Get(ctx, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "negociação não encontrada"})
		return
	}
	if uid != n.UidA && uid != n.UidB {
		c.JSON(http.StatusForbidden, gin.H{"error": "você não participa dessa negociação"})
		return
	}

	type itemMini struct {
		ID              uuid.UUID `json:"id"`
		Titulo          string    `json:"titulo"`
		Categoria       string    `json:"categoria"`
		ValorReferencia float64   `json:"valor_referencia"`
		Fotos           []string  `json:"fotos"`
		LoteID          uuid.UUID `json:"lote_id"`
	}
	type loteMini struct {
		ID             uuid.UUID `json:"id"`
		Titulo         string    `json:"titulo"`
		DonoID         uuid.UUID `json:"dono_id"`
		DonoNome       string    `json:"dono_nome"`
		SetorPrincipal string    `json:"setor_principal"`
	}

	rows, err := h.db.Query(ctx, `
		select i.id, i.titulo, i.categoria, i.valor_referencia, i.fotos, i.lote_id
		  from itens i
		 where i.lote_id in ($1, $2)
		 order by i.lote_id, i.criado_em
	`, n.LoteA, n.LoteB)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()
	itensA := []itemMini{}
	itensB := []itemMini{}
	for rows.Next() {
		var it itemMini
		if err := rows.Scan(&it.ID, &it.Titulo, &it.Categoria, &it.ValorReferencia, &it.Fotos, &it.LoteID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if it.LoteID == n.LoteA {
			itensA = append(itensA, it)
		} else {
			itensB = append(itensB, it)
		}
	}

	loteRows, err := h.db.Query(ctx, `
		select l.id, l.titulo, l.dono_id, p.nome, l.setor_principal
		  from lotes l
		  join profiles p on p.id = l.dono_id
		 where l.id in ($1, $2)
	`, n.LoteA, n.LoteB)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer loteRows.Close()
	var lotes []loteMini
	for loteRows.Next() {
		var l loteMini
		if err := loteRows.Scan(&l.ID, &l.Titulo, &l.DonoID, &l.DonoNome, &l.SetorPrincipal); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		lotes = append(lotes, l)
	}

	var loteA, loteB loteMini
	for _, l := range lotes {
		if l.ID == n.LoteA {
			loteA = l
		} else {
			loteB = l
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"negociacao": n,
		"lote_a":     loteA,
		"lote_b":     loteB,
		"itens_a":    itensA,
		"itens_b":    itensB,
		"meu_lado":   ladoDo(uid, n),
	})
}

func ladoDo(uid uuid.UUID, n domain.Negociacao) string {
	if uid == n.UidA {
		return "a"
	}
	return "b"
}

func (h *NegociacaoHandler) AtualizarMesa(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var in domain.AtualizarMesaReq
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	n, err := h.svc.AtualizarMesa(c.Request.Context(), id, uid, in)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, n)
}

func (h *NegociacaoHandler) Aceitar(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	n, err := h.svc.Aceitar(c.Request.Context(), id, uid)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, n)
}
