package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PerfilHandler struct{ db *pgxpool.Pool }

func NewPerfilHandler(db *pgxpool.Pool) *PerfilHandler { return &PerfilHandler{db: db} }

// GET /perfis/:id — devolve perfil público + inventário + lotes abertos.
// Usado pra renderizar a "página da pessoa" quando alguém toca no nome dela
// num card. É leitura pública (não filtra nada por dono autenticado).
func (h *PerfilHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	ctx := c.Request.Context()

	type perfil struct {
		ID         uuid.UUID `json:"id"`
		Nome       string    `json:"nome"`
		FotoURL    *string   `json:"foto_url,omitempty"`
		Cidade     *string   `json:"cidade,omitempty"`
		Reputacao  float64   `json:"reputacao"`
		NumTrocas  int       `json:"num_trocas"`
	}
	var p perfil
	err = h.db.QueryRow(ctx, `
		select id, nome, foto_url, cidade,
		       coalesce(reputacao, 0)::float8,
		       coalesce(num_trocas, 0)
		  from profiles where id = $1
	`, id).Scan(&p.ID, &p.Nome, &p.FotoURL, &p.Cidade, &p.Reputacao, &p.NumTrocas)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "perfil não encontrado"})
		return
	}

	// Inventário: itens disponíveis (não trocados) com info do lote (se tiver).
	type itemPub struct {
		ID              uuid.UUID  `json:"id"`
		Titulo          string     `json:"titulo"`
		Descricao       *string    `json:"descricao,omitempty"`
		Fotos           []string   `json:"fotos"`
		SetorSlug       string     `json:"setor_slug"`
		Categoria       string     `json:"categoria"`
		ValorReferencia float64    `json:"valor_referencia"`
		LoteID          *uuid.UUID `json:"lote_id,omitempty"`
		LoteTitulo      *string    `json:"lote_titulo,omitempty"`
	}
	rows, err := h.db.Query(ctx, `
		select i.id, i.titulo, i.descricao, i.fotos, i.setor_slug, i.categoria,
		       i.valor_referencia, i.lote_id, l.titulo
		  from itens i
		  left join lotes l on l.id = i.lote_id
		 where i.dono_id = $1 and i.status = 'disponivel'
		 order by i.criado_em desc
		 limit 200
	`, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()
	itens := []itemPub{}
	for rows.Next() {
		var it itemPub
		if err := rows.Scan(&it.ID, &it.Titulo, &it.Descricao, &it.Fotos,
			&it.SetorSlug, &it.Categoria, &it.ValorReferencia,
			&it.LoteID, &it.LoteTitulo); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		itens = append(itens, it)
	}

	// Lotes abertos do dono.
	type lotePub struct {
		ID             uuid.UUID `json:"id"`
		Titulo         string    `json:"titulo"`
		SetorPrincipal string    `json:"setor_principal"`
		ValorTotal     float64   `json:"valor_total"`
		NumItens       int       `json:"num_itens"`
		Capa           *string   `json:"capa,omitempty"`
	}
	lotesRows, err := h.db.Query(ctx, `
		select l.id, l.titulo, l.setor_principal, l.valor_total,
		       (select count(*) from itens where lote_id = l.id) as n,
		       (select (i.fotos)[1] from itens i
		         where i.lote_id = l.id and coalesce(array_length(i.fotos,1),0) > 0
		         order by i.criado_em limit 1) as capa
		  from lotes l
		 where l.dono_id = $1 and l.status = 'aberto'
		 order by l.criado_em desc
	`, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer lotesRows.Close()
	lotes := []lotePub{}
	for lotesRows.Next() {
		var l lotePub
		if err := lotesRows.Scan(&l.ID, &l.Titulo, &l.SetorPrincipal,
			&l.ValorTotal, &l.NumItens, &l.Capa); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		lotes = append(lotes, l)
	}

	// Algumas avaliações recentes pra mostrar na página.
	type avalPub struct {
		Nota       int     `json:"nota"`
		Comentario *string `json:"comentario,omitempty"`
		DeNome     string  `json:"de_nome"`
	}
	avalRows, err := h.db.Query(ctx, `
		select a.nota, a.comentario, coalesce(p.nome, '—')
		  from avaliacoes a
		  join profiles p on p.id = a.de_id
		 where a.para_id = $1
		 order by a.criado_em desc
		 limit 8
	`, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer avalRows.Close()
	avaliacoes := []avalPub{}
	for avalRows.Next() {
		var a avalPub
		if err := avalRows.Scan(&a.Nota, &a.Comentario, &a.DeNome); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		avaliacoes = append(avaliacoes, a)
	}

	c.JSON(http.StatusOK, gin.H{
		"perfil":     p,
		"itens":      itens,
		"lotes":      lotes,
		"avaliacoes": avaliacoes,
	})
}
