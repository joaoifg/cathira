package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
)

type ItemRepo struct{ db *pgxpool.Pool }

func NewItemRepo(db *pgxpool.Pool) *ItemRepo { return &ItemRepo{db: db} }

func (r *ItemRepo) Create(ctx context.Context, donoID uuid.UUID, in domain.NovoItem) (domain.Item, error) {
	destacavel := true
	if in.Destacavel != nil {
		destacavel = *in.Destacavel
	}
	if in.Fotos == nil {
		in.Fotos = []string{}
	}
	if in.Campos == nil {
		in.Campos = map[string]any{}
	}

	var it domain.Item
	err := r.db.QueryRow(ctx, `
		insert into itens (dono_id, titulo, descricao, fotos, setor_slug, categoria, valor_referencia, campos, destacavel, lote_id)
		values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		returning id, dono_id, titulo, descricao, fotos, setor_slug, categoria, valor_referencia, campos, destacavel, lote_id, status, criado_em
	`, donoID, in.Titulo, in.Descricao, in.Fotos, in.SetorSlug, in.Categoria, in.ValorReferencia, in.Campos, destacavel, in.LoteID,
	).Scan(&it.ID, &it.DonoID, &it.Titulo, &it.Descricao, &it.Fotos, &it.SetorSlug, &it.Categoria,
		&it.ValorReferencia, &it.Campos, &it.Destacavel, &it.LoteID, &it.Status, &it.CriadoEm)
	return it, err
}

func (r *ItemRepo) ListByOwner(ctx context.Context, dono uuid.UUID) ([]domain.Item, error) {
	rows, err := r.db.Query(ctx, `
		select id, dono_id, titulo, descricao, fotos, setor_slug, categoria, valor_referencia, campos, destacavel, lote_id, status, criado_em
		  from itens where dono_id = $1 order by criado_em desc
	`, dono)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.Item{}
	for rows.Next() {
		var it domain.Item
		if err := rows.Scan(&it.ID, &it.DonoID, &it.Titulo, &it.Descricao, &it.Fotos, &it.SetorSlug, &it.Categoria,
			&it.ValorReferencia, &it.Campos, &it.Destacavel, &it.LoteID, &it.Status, &it.CriadoEm); err != nil {
			return nil, err
		}
		out = append(out, it)
	}
	return out, rows.Err()
}

func (r *ItemRepo) UpdateLote(ctx context.Context, dono, itemID uuid.UUID, loteID *uuid.UUID) (domain.Item, error) {
	var it domain.Item
	err := r.db.QueryRow(ctx, `
		update itens set lote_id = $3
		 where id = $1 and dono_id = $2
		 returning id, dono_id, titulo, descricao, fotos, setor_slug, categoria, valor_referencia, campos, destacavel, lote_id, status, criado_em
	`, itemID, dono, loteID).Scan(&it.ID, &it.DonoID, &it.Titulo, &it.Descricao, &it.Fotos, &it.SetorSlug, &it.Categoria,
		&it.ValorReferencia, &it.Campos, &it.Destacavel, &it.LoteID, &it.Status, &it.CriadoEm)
	return it, err
}

func (r *ItemRepo) ListByLote(ctx context.Context, loteID uuid.UUID) ([]domain.Item, error) {
	rows, err := r.db.Query(ctx, `
		select id, dono_id, titulo, descricao, fotos, setor_slug, categoria, valor_referencia, campos, destacavel, lote_id, status, criado_em
		  from itens where lote_id = $1 order by criado_em
	`, loteID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.Item{}
	for rows.Next() {
		var it domain.Item
		if err := rows.Scan(&it.ID, &it.DonoID, &it.Titulo, &it.Descricao, &it.Fotos, &it.SetorSlug, &it.Categoria,
			&it.ValorReferencia, &it.Campos, &it.Destacavel, &it.LoteID, &it.Status, &it.CriadoEm); err != nil {
			return nil, err
		}
		out = append(out, it)
	}
	return out, rows.Err()
}
