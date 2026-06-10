package handler

import (
	"context"
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type InteressesHandler struct{ db *pgxpool.Pool }

func NewInteressesHandler(db *pgxpool.Pool) *InteressesHandler {
	return &InteressesHandler{db: db}
}

// GET /interesses/recebidos — interesses pendentes pra mim (sou o "para_id").
func (h *InteressesHandler) Recebidos(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	rows, err := h.db.Query(c.Request.Context(), `
		select i.id, i.de_id, i.item_id, i.criado_em, i.status,
		       it.titulo, it.fotos, it.setor_slug, it.categoria,
		       it.valor_referencia,
		       coalesce(p.nome, '—') as de_nome,
		       p.cidade as de_cidade,
		       coalesce(p.reputacao, 0)::float8 as de_reputacao,
		       coalesce(p.num_trocas, 0) as de_num_trocas
		  from interesses_itens i
		  join itens it    on it.id = i.item_id
		  join profiles p  on p.id  = i.de_id
		 where i.para_id = $1 and i.status = 'pendente'
		 order by i.criado_em desc
		 limit 100
	`, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	out := []map[string]any{}
	for rows.Next() {
		var id, deID, itemID uuid.UUID
		var criadoEm any
		var status, titulo, setorSlug, categoria, deNome string
		var deCidade *string
		var fotos []string
		var valorRef, deRep float64
		var deTrocas int
		if err := rows.Scan(&id, &deID, &itemID, &criadoEm, &status,
			&titulo, &fotos, &setorSlug, &categoria, &valorRef,
			&deNome, &deCidade, &deRep, &deTrocas); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		out = append(out, map[string]any{
			"id":               id,
			"de_id":            deID,
			"item_id":          itemID,
			"criado_em":        criadoEm,
			"status":           status,
			"item_titulo":      titulo,
			"item_fotos":       fotos,
			"item_setor_slug":  setorSlug,
			"item_categoria":   categoria,
			"item_valor":       valorRef,
			"de_nome":          deNome,
			"de_cidade":        deCidade,
			"de_reputacao":     deRep,
			"de_num_trocas":    deTrocas,
		})
	}
	c.JSON(http.StatusOK, out)
}

// POST /interesses/:id/aceitar — aceita o interesse, cria a negociação com
// o item já dentro da mesa do lado do dono, e o "lote inventário" do
// interessado pra ser explorado.
func (h *InteressesHandler) Aceitar(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	intID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	ctx := c.Request.Context()

	tx, err := h.db.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer tx.Rollback(ctx)

	var interesse struct {
		DeID    uuid.UUID
		ParaID  uuid.UUID
		ItemID  uuid.UUID
		Status  string
		NegoID  *uuid.UUID
	}
	if err := tx.QueryRow(ctx, `
		select de_id, para_id, item_id, status, negociacao_id
		  from interesses_itens where id = $1 for update
	`, intID).Scan(&interesse.DeID, &interesse.ParaID, &interesse.ItemID,
		&interesse.Status, &interesse.NegoID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "interesse não encontrado"})
		return
	}
	if interesse.ParaID != uid {
		c.JSON(http.StatusForbidden, gin.H{"error": "esse interesse não é seu"})
		return
	}
	if interesse.Status == "aceito" && interesse.NegoID != nil {
		// Já foi aceito antes — devolve a negociação existente.
		c.JSON(http.StatusOK, gin.H{
			"negociacao_id": *interesse.NegoID,
			"ja_aceito":     true,
		})
		return
	}
	if interesse.Status != "pendente" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "interesse já foi resolvido (status=" + interesse.Status + ")",
		})
		return
	}

	// Lote A (do dono do item): se item já está em lote normal, usa esse.
	// Senão cria lote 'solo' com só esse item.
	loteA, err := h.resolveLoteParaItem(ctx, tx, interesse.ParaID, interesse.ItemID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "lote_a: " + err.Error()})
		return
	}

	// Lote B (do interessado): se tem algum lote aberto normal, usa.
	// Senão cria 'inventario_auto' com TODOS os itens disponíveis dele.
	loteB, err := h.resolveLoteInventario(ctx, tx, interesse.DeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "lote_b: " + err.Error()})
		return
	}

	// Cria negociação com o item curtido já na mesa do lado A.
	var negID uuid.UUID
	if err := tx.QueryRow(ctx, `
		insert into negociacoes (lote_a, lote_b, uid_a, uid_b, itens_a, itens_b, status)
		values ($1, $2, $3, $4, ARRAY[$5::uuid], ARRAY[]::uuid[], 'proposta')
		returning id
	`, loteA, loteB, interesse.ParaID, interesse.DeID, interesse.ItemID).Scan(&negID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "negociacao: " + err.Error()})
		return
	}

	// Recalcula torna agora que a mesa tem itens.
	if _, err := tx.Exec(ctx, `select * from atualizar_mesa($1, ARRAY[$2::uuid], ARRAY[]::uuid[], $3)`,
		negID, interesse.ItemID, interesse.ParaID); err != nil {
		// Não fatal — a UI pode recalcular depois. Mas logamos.
		c.JSON(http.StatusInternalServerError, gin.H{"error": "atualizar_mesa: " + err.Error()})
		return
	}

	// Marca interesse como aceito.
	if _, err := tx.Exec(ctx, `
		update interesses_itens set status='aceito', negociacao_id=$1, resolvido_em=now()
		 where id=$2
	`, negID, intID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"negociacao_id": negID,
		"ja_aceito":     false,
	})
}

// POST /interesses/:id/recusar — só marca como recusado.
func (h *InteressesHandler) Recusar(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	intID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	res, err := h.db.Exec(c.Request.Context(), `
		update interesses_itens
		   set status='recusado', resolvido_em=now()
		 where id=$1 and para_id=$2 and status='pendente'
	`, intID, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if res.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "interesse não encontrado ou já resolvido"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// resolveLoteParaItem garante que o item está em algum lote (normal ou solo).
// Se já estiver, retorna o lote_id. Se for solto, cria um lote tipo 'solo'
// agrupando só esse item e retorna o id.
func (h *InteressesHandler) resolveLoteParaItem(ctx context.Context, tx pgx.Tx,
	donoID, itemID uuid.UUID) (uuid.UUID, error) {
	var loteID *uuid.UUID
	var setor string
	var titulo string
	if err := tx.QueryRow(ctx,
		`select lote_id, setor_slug, titulo from itens where id = $1 and dono_id = $2`,
		itemID, donoID).Scan(&loteID, &setor, &titulo); err != nil {
		return uuid.Nil, err
	}
	if loteID != nil {
		return *loteID, nil
	}
	// Cria lote 'solo' e move o item pra ele.
	var novoID uuid.UUID
	if err := tx.QueryRow(ctx, `
		insert into lotes (dono_id, titulo, setor_principal, tipo)
		values ($1, $2, $3, 'solo') returning id
	`, donoID, titulo, setor).Scan(&novoID); err != nil {
		return uuid.Nil, err
	}
	if _, err := tx.Exec(ctx, `update itens set lote_id = $1 where id = $2`,
		novoID, itemID); err != nil {
		return uuid.Nil, err
	}
	return novoID, nil
}

// resolveLoteInventario procura primeiro lote normal aberto do user. Se
// não tiver, cria um 'inventario_auto' com todos os itens disponíveis.
func (h *InteressesHandler) resolveLoteInventario(ctx context.Context, tx pgx.Tx,
	donoID uuid.UUID) (uuid.UUID, error) {
	var loteID uuid.UUID
	err := tx.QueryRow(ctx, `
		select id from lotes
		 where dono_id = $1 and status = 'aberto' and tipo = 'normal'
		 order by criado_em desc limit 1
	`, donoID).Scan(&loteID)
	if err == nil {
		return loteID, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, err
	}
	// Verifica se já existe inventario_auto.
	err = tx.QueryRow(ctx, `
		select id from lotes
		 where dono_id = $1 and tipo = 'inventario_auto' and status = 'aberto'
		 limit 1
	`, donoID).Scan(&loteID)
	if err == nil {
		return loteID, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, err
	}
	// Cria inventario_auto. Setor = setor do item mais valioso disponível.
	var setor string
	if err := tx.QueryRow(ctx, `
		select coalesce(
		         (select setor_slug from itens where dono_id = $1 and status = 'disponivel'
		           order by valor_referencia desc limit 1),
		         (select slug from setores where ativo = true limit 1)
		       )
	`, donoID).Scan(&setor); err != nil {
		return uuid.Nil, err
	}
	if err := tx.QueryRow(ctx, `
		insert into lotes (dono_id, titulo, setor_principal, tipo)
		values ($1, 'Meu inventário', $2, 'inventario_auto') returning id
	`, donoID, setor).Scan(&loteID); err != nil {
		return uuid.Nil, err
	}
	// Move todos os itens disponíveis pro lote auto (sem mexer em quem já está em outro lote).
	if _, err := tx.Exec(ctx, `
		update itens set lote_id = $1
		 where dono_id = $2 and lote_id is null and status = 'disponivel'
	`, loteID, donoID); err != nil {
		return uuid.Nil, err
	}
	return loteID, nil
}
