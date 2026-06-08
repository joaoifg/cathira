package domain

import (
	"time"

	"github.com/google/uuid"
)

type Negociacao struct {
	ID           uuid.UUID   `json:"id"`
	LoteA        uuid.UUID   `json:"lote_a"`
	LoteB        uuid.UUID   `json:"lote_b"`
	UidA         uuid.UUID   `json:"uid_a"`
	UidB         uuid.UUID   `json:"uid_b"`
	ItensA       []uuid.UUID `json:"itens_a"`
	ItensB       []uuid.UUID `json:"itens_b"`
	ValorA       float64     `json:"valor_a"`
	ValorB       float64     `json:"valor_b"`
	Torna        float64     `json:"torna"`
	QuemPaga     *uuid.UUID  `json:"quem_paga,omitempty"`
	AceiteA      bool        `json:"aceite_a"`
	AceiteB      bool        `json:"aceite_b"`
	Status       string      `json:"status"`
	UltimaAcao   *uuid.UUID  `json:"ultima_acao,omitempty"`
	Versao       int         `json:"versao"`
	CriadoEm     time.Time   `json:"criado_em"`
	AtualizadoEm time.Time   `json:"atualizado_em"`
}

type AtualizarMesaReq struct {
	ItensA []uuid.UUID `json:"itens_a" binding:"required"`
	ItensB []uuid.UUID `json:"itens_b" binding:"required"`
}

type Swipe struct {
	FromLote uuid.UUID `json:"from_lote" binding:"required"`
	ToLote   uuid.UUID `json:"to_lote"   binding:"required"`
	Decisao  string    `json:"decisao"   binding:"required,oneof=like pass"`
}
