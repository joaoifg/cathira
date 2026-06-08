package service

import (
	"context"

	"github.com/google/uuid"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
	"github.com/joaohenriqueoci/permuta-api/internal/repository"
)

type LoteService struct {
	lotes *repository.LoteRepo
	itens *repository.ItemRepo
}

func NewLoteService(l *repository.LoteRepo, i *repository.ItemRepo) *LoteService {
	return &LoteService{lotes: l, itens: i}
}

func (s *LoteService) Create(ctx context.Context, dono uuid.UUID, in domain.NovoLote) (domain.Lote, error) {
	return s.lotes.Create(ctx, dono, in)
}

func (s *LoteService) Get(ctx context.Context, id uuid.UUID) (domain.Lote, []domain.Item, error) {
	l, err := s.lotes.Get(ctx, id)
	if err != nil {
		return domain.Lote{}, nil, err
	}
	itens, err := s.itens.ListByLote(ctx, id)
	if err != nil {
		return l, nil, err
	}
	return l, itens, nil
}

func (s *LoteService) Feed(ctx context.Context, viewer uuid.UUID, q domain.FeedQuery) ([]repository.FeedItem, error) {
	if q.Limit <= 0 || q.Limit > 50 {
		q.Limit = 20
	}
	return s.lotes.Feed(ctx, viewer, q)
}

func (s *LoteService) AddItem(ctx context.Context, dono, loteID uuid.UUID, in domain.NovoItem) (domain.Item, error) {
	in.LoteID = &loteID
	return s.itens.Create(ctx, dono, in)
}

func (s *LoteService) MyLotes(ctx context.Context, dono uuid.UUID) ([]domain.Lote, error) {
	return s.lotes.ListByOwner(ctx, dono)
}

func (s *LoteService) MyItens(ctx context.Context, dono uuid.UUID) ([]domain.Item, error) {
	return s.itens.ListByOwner(ctx, dono)
}

// MoveItem move item entre lotes ou solta (loteID = nil).
func (s *LoteService) MoveItem(ctx context.Context, dono, itemID uuid.UUID, loteID *uuid.UUID) (domain.Item, error) {
	return s.itens.UpdateLote(ctx, dono, itemID, loteID)
}

func (s *LoteService) CreateItem(ctx context.Context, dono uuid.UUID, in domain.NovoItem) (domain.Item, error) {
	return s.itens.Create(ctx, dono, in)
}
