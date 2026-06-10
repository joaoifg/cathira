package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type DescobertaItensHandler struct{ db *pgxpool.Pool }

func NewDescobertaItensHandler(db *pgxpool.Pool) *DescobertaItensHandler {
	return &DescobertaItensHandler{db: db}
}

// GET /descoberta/itens?setor=&valor_min=&valor_max=&cidade=&limit=
// Devolve itens disponíveis pra "swipar", excluindo:
//   - itens do próprio usuário
//   - itens já visualizados (já tem swipe)
//   - itens trocados ou em negociação
//
// Ordena destacados primeiro.
func (h *DescobertaItensHandler) Feed(c *gin.Context) {
	uid, _ := middleware.UserID(c)

	setor := c.Query("setor")
	cidade := c.Query("cidade")
	valorMin, _ := strconv.ParseFloat(c.DefaultQuery("valor_min", "0"), 64)
	valorMax, _ := strconv.ParseFloat(c.DefaultQuery("valor_max", "0"), 64)
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "30"))
	if limit < 1 || limit > 100 {
		limit = 30
	}

	ctx := c.Request.Context()
	rows, err := h.db.Query(ctx, `
		select i.id, i.titulo, i.descricao, i.fotos, i.setor_slug, i.categoria,
		       i.valor_referencia, i.lote_id, l.titulo,
		       i.dono_id,
		       coalesce(p.nome, '—') as dono_nome,
		       p.cidade as dono_cidade,
		       coalesce(p.reputacao, 0)::float8 as dono_reputacao,
		       (i.destaque_ate is not null and i.destaque_ate > now()) as em_destaque
		  from itens i
		  join profiles p on p.id = i.dono_id
		  left join lotes l on l.id = i.lote_id
		 where i.status = 'disponivel'
		   and i.dono_id <> $1
		   and ($2 = '' or i.setor_slug = $2)
		   and ($3 = 0 or i.valor_referencia >= $3)
		   and ($4 = 0 or i.valor_referencia <= $4)
		   and ($5 = '' or coalesce(p.cidade,'') ilike '%' || $5 || '%')
		   and i.id not in (select to_item from swipes_itens where from_id = $1)
		 order by (i.destaque_ate is not null and i.destaque_ate > now()) desc,
		          i.criado_em desc
		 limit $6
	`, uid, setor, valorMin, valorMax, cidade, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	out := []map[string]any{}
	for rows.Next() {
		var id, donoID uuid.UUID
		var titulo, setorSlug, categoria, donoNome string
		var descricao, loteTitulo *string
		var loteID *uuid.UUID
		var donoCidade *string
		var fotos []string
		var valorRef, donoRep float64
		var emDestaque bool
		if err := rows.Scan(&id, &titulo, &descricao, &fotos, &setorSlug,
			&categoria, &valorRef, &loteID, &loteTitulo, &donoID, &donoNome,
			&donoCidade, &donoRep, &emDestaque); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		out = append(out, map[string]any{
			"id":               id,
			"titulo":           titulo,
			"descricao":        descricao,
			"fotos":            fotos,
			"setor_slug":       setorSlug,
			"categoria":        categoria,
			"valor_referencia": valorRef,
			"lote_id":          loteID,
			"lote_titulo":      loteTitulo,
			"dono_id":          donoID,
			"dono_nome":        donoNome,
			"dono_cidade":      donoCidade,
			"dono_reputacao":   donoRep,
			"em_destaque":      emDestaque,
		})
	}

	c.JSON(http.StatusOK, out)
}

type swipeItemReq struct {
	ToItem  uuid.UUID `json:"to_item"  binding:"required"`
	Decisao string    `json:"decisao"  binding:"required,oneof=like pass"`
}

// POST /swipes-itens — registra decisão de swipe sobre um item.
// Quando 'like', também cria um interesse pendente que o dono pode aceitar
// ou recusar pra abrir a Mesa exploradora.
func (h *DescobertaItensHandler) Swipe(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	var req swipeItemReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := c.Request.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, `
		insert into swipes_itens (from_id, to_item, decisao) values ($1,$2,$3)
		on conflict (from_id, to_item) do update set decisao = excluded.decisao
	`, uid, req.ToItem, req.Decisao); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var interesseID *uuid.UUID
	if req.Decisao == "like" {
		// Cria interesse pendente endereçado ao dono do item.
		var donoID uuid.UUID
		if err := tx.QueryRow(ctx, `select dono_id from itens where id = $1`,
			req.ToItem).Scan(&donoID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if donoID == uid {
			c.JSON(http.StatusBadRequest, gin.H{"error": "não dá pra curtir item próprio"})
			return
		}
		var id uuid.UUID
		err := tx.QueryRow(ctx, `
			insert into interesses_itens (de_id, para_id, item_id) values ($1,$2,$3)
			on conflict (de_id, item_id) do update set
			  status = case when interesses_itens.status = 'recusado' then 'pendente' else interesses_itens.status end,
			  resolvido_em = null
			returning id
		`, uid, donoID, req.ToItem).Scan(&id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		interesseID = &id
	}

	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resp := gin.H{"ok": true}
	if interesseID != nil {
		resp["interesse_id"] = interesseID
	}
	c.JSON(http.StatusOK, resp)
}
