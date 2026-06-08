package domain

import (
	"time"

	"github.com/google/uuid"
)

type Item struct {
	ID              uuid.UUID      `json:"id"`
	DonoID          uuid.UUID      `json:"dono_id"`
	Titulo          string         `json:"titulo"`
	Descricao       *string        `json:"descricao,omitempty"`
	Fotos           []string       `json:"fotos"`
	SetorSlug       string         `json:"setor_slug"`
	Categoria       string         `json:"categoria"`
	ValorReferencia float64        `json:"valor_referencia"`
	Campos          map[string]any `json:"campos"`
	Destacavel      bool           `json:"destacavel"`
	LoteID          *uuid.UUID     `json:"lote_id,omitempty"`
	Status          string         `json:"status"`
	CriadoEm        time.Time      `json:"criado_em"`
}

type NovoItem struct {
	Titulo          string         `json:"titulo"           binding:"required,min=2,max=120"`
	Descricao       *string        `json:"descricao"`
	Fotos           []string       `json:"fotos"`
	SetorSlug       string         `json:"setor_slug"       binding:"required"`
	Categoria       string         `json:"categoria"        binding:"required"`
	ValorReferencia float64        `json:"valor_referencia" binding:"required,gte=0"`
	Campos          map[string]any `json:"campos"`
	Destacavel      *bool          `json:"destacavel"`
	LoteID          *uuid.UUID     `json:"lote_id"`
}
