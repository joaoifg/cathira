package service

import (
	"context"

	"github.com/google/uuid"

	"github.com/joaohenriqueoci/permuta-api/internal/domain"
	"github.com/joaohenriqueoci/permuta-api/internal/repository"
)

type MatchService struct{ nego *repository.NegociacaoRepo }

func NewMatchService(n *repository.NegociacaoRepo) *MatchService {
	return &MatchService{nego: n}
}

// Swipe grava like/pass. Em like recíproco, devolve o ID da negociação criada
// (ou de uma já aberta). Caso contrário NegID = uuid.Nil.
type SwipeResult struct {
	NegID uuid.UUID `json:"negociacao_id,omitempty"`
	Match bool      `json:"match"`
}

func (s *MatchService) Swipe(ctx context.Context, from uuid.UUID, in domain.Swipe) (SwipeResult, error) {
	negID, err := s.nego.LikeReciproco(ctx, from, in)
	if err != nil {
		return SwipeResult{}, err
	}
	return SwipeResult{NegID: negID, Match: negID != uuid.Nil}, nil
}
