package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
)

type NegociacaoRepo struct{ db *pgxpool.Pool }

func NewNegociacaoRepo(db *pgxpool.Pool) *NegociacaoRepo { return &NegociacaoRepo{db: db} }

// LikeReciproco grava o swipe; se for like recíproco, cria a negociação dentro
// da mesma transação e devolve seu ID. Quando não há reciprocidade, retorna uuid.Nil.
func (r *NegociacaoRepo) LikeReciproco(ctx context.Context, fromID uuid.UUID, in domain.Swipe) (uuid.UUID, error) {
	tx, err := r.db.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.Serializable})
	if err != nil {
		return uuid.Nil, err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, `
		insert into swipes (from_id, from_lote, to_lote, decisao) values ($1,$2,$3,$4)
		on conflict (from_id, from_lote, to_lote) do update set decisao = excluded.decisao
	`, fromID, in.FromLote, in.ToLote, in.Decisao); err != nil {
		return uuid.Nil, err
	}
	if in.Decisao != "like" {
		return uuid.Nil, tx.Commit(ctx)
	}

	var donoTo uuid.UUID
	if err := tx.QueryRow(ctx, `select dono_id from lotes where id = $1`, in.ToLote).Scan(&donoTo); err != nil {
		return uuid.Nil, err
	}

	// existe like de volta?
	var recip bool
	if err := tx.QueryRow(ctx, `
		select exists (
			select 1 from swipes
			 where from_id = $1 and from_lote = $2 and to_lote = $3 and decisao = 'like'
		)
	`, donoTo, in.ToLote, in.FromLote).Scan(&recip); err != nil {
		return uuid.Nil, err
	}
	if !recip {
		return uuid.Nil, tx.Commit(ctx)
	}

	// já existe negociação aberta entre esses dois lotes?
	var existing uuid.UUID
	err = tx.QueryRow(ctx, `
		select id from negociacoes
		 where ((lote_a = $1 and lote_b = $2) or (lote_a = $2 and lote_b = $1))
		   and status in ('proposta','contraproposta')
		 limit 1
	`, in.FromLote, in.ToLote).Scan(&existing)
	if err == nil {
		return existing, tx.Commit(ctx)
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, err
	}

	var donoFrom uuid.UUID
	if err := tx.QueryRow(ctx, `select dono_id from lotes where id = $1`, in.FromLote).Scan(&donoFrom); err != nil {
		return uuid.Nil, err
	}

	var negoID uuid.UUID
	if err := tx.QueryRow(ctx, `
		insert into negociacoes (lote_a, lote_b, uid_a, uid_b)
		values ($1,$2,$3,$4) returning id
	`, in.FromLote, in.ToLote, donoFrom, donoTo).Scan(&negoID); err != nil {
		return uuid.Nil, err
	}

	if _, err := tx.Exec(ctx, `
		update lotes set status = 'negociando' where id in ($1,$2) and status = 'aberto'
	`, in.FromLote, in.ToLote); err != nil {
		return uuid.Nil, err
	}

	return negoID, tx.Commit(ctx)
}

func (r *NegociacaoRepo) Get(ctx context.Context, id uuid.UUID) (domain.Negociacao, error) {
	row := r.db.QueryRow(ctx, `
		select id, lote_a, lote_b, uid_a, uid_b, itens_a, itens_b, valor_a, valor_b, torna, quem_paga,
		       aceite_a, aceite_b, status, ultima_acao, versao, criado_em, atualizado_em
		  from negociacoes where id = $1
	`, id)
	return scanNego(row)
}

func (r *NegociacaoRepo) ListByUser(ctx context.Context, uid uuid.UUID) ([]domain.Negociacao, error) {
	rows, err := r.db.Query(ctx, `
		select id, lote_a, lote_b, uid_a, uid_b, itens_a, itens_b, valor_a, valor_b, torna, quem_paga,
		       aceite_a, aceite_b, status, ultima_acao, versao, criado_em, atualizado_em
		  from negociacoes where uid_a = $1 or uid_b = $1
		 order by atualizado_em desc
	`, uid)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []domain.Negociacao{}
	for rows.Next() {
		n, err := scanNego(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, n)
	}
	return out, rows.Err()
}

func (r *NegociacaoRepo) AtualizarMesa(ctx context.Context, negID, actor uuid.UUID, itensA, itensB []uuid.UUID) (domain.Negociacao, error) {
	var n domain.Negociacao
	row := r.db.QueryRow(ctx, `
		select id, lote_a, lote_b, uid_a, uid_b, itens_a, itens_b, valor_a, valor_b, torna, quem_paga,
		       aceite_a, aceite_b, status, ultima_acao, versao, criado_em, atualizado_em
		  from atualizar_mesa($1, $2, $3, $4)
	`, negID, itensA, itensB, actor)
	if err := row.Scan(&n.ID, &n.LoteA, &n.LoteB, &n.UidA, &n.UidB, &n.ItensA, &n.ItensB,
		&n.ValorA, &n.ValorB, &n.Torna, &n.QuemPaga, &n.AceiteA, &n.AceiteB,
		&n.Status, &n.UltimaAcao, &n.Versao, &n.CriadoEm, &n.AtualizadoEm); err != nil {
		return n, err
	}
	return n, nil
}

func (r *NegociacaoRepo) Aceitar(ctx context.Context, negID, actor uuid.UUID) (domain.Negociacao, error) {
	var n domain.Negociacao
	row := r.db.QueryRow(ctx, `
		select id, lote_a, lote_b, uid_a, uid_b, itens_a, itens_b, valor_a, valor_b, torna, quem_paga,
		       aceite_a, aceite_b, status, ultima_acao, versao, criado_em, atualizado_em
		  from aceitar_negociacao($1, $2)
	`, negID, actor)
	if err := row.Scan(&n.ID, &n.LoteA, &n.LoteB, &n.UidA, &n.UidB, &n.ItensA, &n.ItensB,
		&n.ValorA, &n.ValorB, &n.Torna, &n.QuemPaga, &n.AceiteA, &n.AceiteB,
		&n.Status, &n.UltimaAcao, &n.Versao, &n.CriadoEm, &n.AtualizadoEm); err != nil {
		return n, err
	}
	return n, nil
}

type scannable interface {
	Scan(dest ...any) error
}

func scanNego(s scannable) (domain.Negociacao, error) {
	var n domain.Negociacao
	err := s.Scan(&n.ID, &n.LoteA, &n.LoteB, &n.UidA, &n.UidB, &n.ItensA, &n.ItensB,
		&n.ValorA, &n.ValorB, &n.Torna, &n.QuemPaga, &n.AceiteA, &n.AceiteB,
		&n.Status, &n.UltimaAcao, &n.Versao, &n.CriadoEm, &n.AtualizadoEm)
	return n, err
}
