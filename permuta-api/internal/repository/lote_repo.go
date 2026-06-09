package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
)

type LoteRepo struct{ db *pgxpool.Pool }

func NewLoteRepo(db *pgxpool.Pool) *LoteRepo { return &LoteRepo{db: db} }

func (r *LoteRepo) Create(ctx context.Context, donoID uuid.UUID, in domain.NovoLote) (domain.Lote, error) {
	var l domain.Lote
	aceitaTorna := true
	aceitaParcial := true
	if in.AceitaTorna != nil {
		aceitaTorna = *in.AceitaTorna
	}
	if in.AceitaParcial != nil {
		aceitaParcial = *in.AceitaParcial
	}

	row := r.db.QueryRow(ctx, `
		insert into lotes (dono_id, titulo, setor_principal, faixa_alvo_min, faixa_alvo_max, aceita_torna, aceita_parcial, cidade)
		values ($1,$2,$3,$4,$5,$6,$7,$8)
		returning id, dono_id, titulo, setor_principal, valor_total, faixa_alvo_min, faixa_alvo_max, aceita_torna, aceita_parcial, cidade, status, criado_em
	`, donoID, in.Titulo, in.SetorPrincipal, in.FaixaAlvoMin, in.FaixaAlvoMax, aceitaTorna, aceitaParcial, in.Cidade)

	err := row.Scan(&l.ID, &l.DonoID, &l.Titulo, &l.SetorPrincipal, &l.ValorTotal,
		&l.FaixaAlvoMin, &l.FaixaAlvoMax, &l.AceitaTorna, &l.AceitaParcial, &l.Cidade, &l.Status, &l.CriadoEm)
	return l, err
}

func (r *LoteRepo) Get(ctx context.Context, id uuid.UUID) (domain.Lote, error) {
	var l domain.Lote
	err := r.db.QueryRow(ctx, `
		select id, dono_id, titulo, setor_principal, valor_total, faixa_alvo_min, faixa_alvo_max,
		       aceita_torna, aceita_parcial, cidade, status, criado_em
		  from lotes where id = $1
	`, id).Scan(&l.ID, &l.DonoID, &l.Titulo, &l.SetorPrincipal, &l.ValorTotal,
		&l.FaixaAlvoMin, &l.FaixaAlvoMax, &l.AceitaTorna, &l.AceitaParcial, &l.Cidade, &l.Status, &l.CriadoEm)
	return l, err
}

// FeedItem é o que vai pra UI da descoberta: lote + perfil do dono.
type FeedItem struct {
	domain.Lote
	DonoNome      string   `json:"dono_nome"`
	DonoCidade    *string  `json:"dono_cidade,omitempty"`
	DonoReputacao float64  `json:"dono_reputacao"`
	NumItens      int      `json:"num_itens"`
	Capa          *string  `json:"capa,omitempty"`
	Fotos         []string `json:"fotos,omitempty"`
	EmDestaque    bool     `json:"em_destaque"`
}

func (r *LoteRepo) Feed(ctx context.Context, donoID uuid.UUID, q domain.FeedQuery) ([]FeedItem, error) {
	rows, err := r.db.Query(ctx, `
		select l.id, l.dono_id, l.titulo, l.setor_principal, l.valor_total, l.faixa_alvo_min, l.faixa_alvo_max,
		       l.aceita_torna, l.aceita_parcial, l.cidade, l.status, l.criado_em,
		       coalesce(p.nome, '—') as dono_nome,
		       p.cidade as dono_cidade,
		       coalesce(p.reputacao, 0)::float8 as dono_reputacao,
		       (select count(*) from itens where lote_id = l.id) as num_itens,
		       (
		         select coalesce(array_agg(f order by f.ord), '{}')
		           from (
		             select (i.fotos)[1] as f, row_number() over (order by i.criado_em) as ord
		               from itens i
		              where i.lote_id = l.id and coalesce(array_length(i.fotos,1),0) > 0
		              limit 6
		           ) f
		       ) as fotos,
		       (l.destaque_ate is not null and l.destaque_ate > now()) as em_destaque
		  from lotes l
		  join profiles p on p.id = l.dono_id
		 where l.status = 'aberto'
		   and l.dono_id <> $1
		   and ($2 = '' or l.setor_principal = $2)
		   and ($3 = 0  or l.valor_total >= $3)
		   and ($4 = 0  or l.valor_total <= $4)
		   and ($5 = '' or coalesce(p.cidade,'') ilike '%' || $5 || '%')
		   and l.id not in (select to_lote from swipes where from_id = $1)
		 order by (l.destaque_ate is not null and l.destaque_ate > now()) desc,
		          l.criado_em desc
		 limit $6
	`, donoID, q.Setor, q.FaixaMin, q.FaixaMax, q.Cidade, q.Limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []FeedItem{}
	for rows.Next() {
		var f FeedItem
		if err := rows.Scan(&f.ID, &f.DonoID, &f.Titulo, &f.SetorPrincipal, &f.ValorTotal,
			&f.FaixaAlvoMin, &f.FaixaAlvoMax, &f.AceitaTorna, &f.AceitaParcial, &f.Cidade, &f.Status, &f.CriadoEm,
			&f.DonoNome, &f.DonoCidade, &f.DonoReputacao, &f.NumItens, &f.Fotos, &f.EmDestaque); err != nil {
			return nil, err
		}
		if len(f.Fotos) > 0 {
			f.Capa = &f.Fotos[0]
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// CheckExists confirma existência e retorna dono.
func (r *LoteRepo) Owner(ctx context.Context, id uuid.UUID) (uuid.UUID, error) {
	var d uuid.UUID
	err := r.db.QueryRow(ctx, `select dono_id from lotes where id = $1`, id).Scan(&d)
	if err == pgx.ErrNoRows {
		return uuid.Nil, err
	}
	return d, err
}

func (r *LoteRepo) ListByOwner(ctx context.Context, dono uuid.UUID) ([]domain.Lote, error) {
	rows, err := r.db.Query(ctx, `
		select id, dono_id, titulo, setor_principal, valor_total, faixa_alvo_min, faixa_alvo_max,
		       aceita_torna, aceita_parcial, cidade, status, criado_em
		  from lotes where dono_id = $1
		 order by criado_em desc
	`, dono)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.Lote{}
	for rows.Next() {
		var l domain.Lote
		if err := rows.Scan(&l.ID, &l.DonoID, &l.Titulo, &l.SetorPrincipal, &l.ValorTotal,
			&l.FaixaAlvoMin, &l.FaixaAlvoMax, &l.AceitaTorna, &l.AceitaParcial, &l.Cidade, &l.Status, &l.CriadoEm); err != nil {
			return nil, err
		}
		out = append(out, l)
	}
	return out, rows.Err()
}
