package domain

import (
	"time"

	"github.com/google/uuid"
)

type Lote struct {
	ID             uuid.UUID `json:"id"`
	DonoID         uuid.UUID `json:"dono_id"`
	Titulo         string    `json:"titulo"`
	SetorPrincipal string    `json:"setor_principal"`
	ValorTotal     float64   `json:"valor_total"`
	FaixaAlvoMin   *float64  `json:"faixa_alvo_min,omitempty"`
	FaixaAlvoMax   *float64  `json:"faixa_alvo_max,omitempty"`
	AceitaTorna    bool      `json:"aceita_torna"`
	AceitaParcial  bool      `json:"aceita_parcial"`
	Cidade         *string   `json:"cidade,omitempty"`
	Status         string    `json:"status"`
	CriadoEm       time.Time `json:"criado_em"`
}

type NovoLote struct {
	Titulo         string   `json:"titulo"          binding:"required,min=2,max=120"`
	SetorPrincipal string   `json:"setor_principal" binding:"required"`
	FaixaAlvoMin   *float64 `json:"faixa_alvo_min"`
	FaixaAlvoMax   *float64 `json:"faixa_alvo_max"`
	AceitaTorna    *bool    `json:"aceita_torna"`
	AceitaParcial  *bool    `json:"aceita_parcial"`
	Cidade         *string  `json:"cidade"`
}

type FeedQuery struct {
	Setor    string  `form:"setor"`
	Cidade   string  `form:"cidade"`
	FaixaMin float64 `form:"faixa_min"`
	FaixaMax float64 `form:"faixa_max"`
	Limit    int     `form:"limit,default=30"`
}
