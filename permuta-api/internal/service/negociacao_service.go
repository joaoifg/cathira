package service

import (
	"context"

	"github.com/google/uuid"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
	"github.com/joaohenriqueoci/permuta-api/internal/repository"
)

type NegociacaoService struct{ repo *repository.NegociacaoRepo }

func NewNegociacaoService(r *repository.NegociacaoRepo) *NegociacaoService {
	return &NegociacaoService{repo: r}
}

func (s *NegociacaoService) List(ctx context.Context, uid uuid.UUID) ([]domain.Negociacao, error) {
	return s.repo.ListByUser(ctx, uid)
}

func (s *NegociacaoService) Get(ctx context.Context, id uuid.UUID) (domain.Negociacao, error) {
	return s.repo.Get(ctx, id)
}

// AtualizarMesa delega à função SQL atualizar_mesa() — ela faz o lock,
// recalcula torna via calcular_torna() e zera os aceites na mesma transação.
func (s *NegociacaoService) AtualizarMesa(ctx context.Context, negID, actor uuid.UUID, in domain.AtualizarMesaReq) (domain.Negociacao, error) {
	if in.ItensA == nil {
		in.ItensA = []uuid.UUID{}
	}
	if in.ItensB == nil {
		in.ItensB = []uuid.UUID{}
	}
	return s.repo.AtualizarMesa(ctx, negID, actor, in.ItensA, in.ItensB)
}

func (s *NegociacaoService) Aceitar(ctx context.Context, negID, actor uuid.UUID) (domain.Negociacao, error) {
	return s.repo.Aceitar(ctx, negID, actor)
}
