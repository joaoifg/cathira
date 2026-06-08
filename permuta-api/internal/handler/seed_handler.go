package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/config"
	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
)

type SeedHandler struct {
	db  *pgxpool.Pool
	cfg config.Config
	hc  *http.Client
}

func NewSeedHandler(db *pgxpool.Pool, cfg config.Config) *SeedHandler {
	return &SeedHandler{db: db, cfg: cfg, hc: &http.Client{Timeout: 15 * time.Second}}
}

type seedItem struct {
	titulo, categoria, descricao string
	valor                        float64
	campos                       map[string]string
	foto                         string // URL pública, pode ficar vazio
}

type seedLote struct {
	titulo, setor      string
	faixaMin, faixaMax float64
	itens              []seedItem
}

type seedPersona struct {
	nome, email, cidade string
	lotes               []seedLote
}

// POST /dev/seed — popula lotes do user autenticado.
func (h *SeedHandler) Run(c *gin.Context) {
	uid, _ := middleware.UserID(c)
	ctx := c.Request.Context()

	tx, err := h.db.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer tx.Rollback(ctx)

	if err := wipeUser(ctx, tx, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	itensCriados, err := insertSeedLotes(ctx, tx, uid, meusSeed)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"lotes_criados": len(meusSeed),
		"itens_criados": itensCriados,
	})
}

// POST /dev/seed-mundo — cria personas + lotes + avaliações + negociações.
func (h *SeedHandler) Mundo(c *gin.Context) {
	ctx := c.Request.Context()

	emailToUID := map[string]uuid.UUID{}
	emailToLotes := map[string]map[string]uuid.UUID{} // email -> {tituloLote -> id}

	personasCriadas := 0
	lotesCriados := 0
	itensCriados := 0

	for _, p := range personasMundo {
		uid, err := h.ensureUser(ctx, p.email, p.nome)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": fmt.Sprintf("persona %s: %s", p.nome, err),
			})
			return
		}
		emailToUID[p.email] = uid
		personasCriadas++

		tx, err := h.db.Begin(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		_, _ = tx.Exec(ctx, `
			insert into profiles (id, nome, cidade) values ($1,$2,$3)
			on conflict (id) do update set nome = excluded.nome, cidade = excluded.cidade
		`, uid, p.nome, p.cidade)

		if err := wipeUser(ctx, tx, uid); err != nil {
			tx.Rollback(ctx)
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		idsLote, n, err := insertSeedLotesReturning(ctx, tx, uid, p.lotes)
		if err != nil {
			tx.Rollback(ctx)
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if err := tx.Commit(ctx); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		emailToLotes[p.email] = idsLote
		lotesCriados += len(p.lotes)
		itensCriados += n
	}

	// Limpa negociações/avaliações antigas dessas personas pra ser idempotente.
	uids := make([]uuid.UUID, 0, len(emailToUID))
	for _, u := range emailToUID {
		uids = append(uids, u)
	}
	if len(uids) > 0 {
		_, _ = h.db.Exec(ctx, `delete from avaliacoes where de_id = any($1) or para_id = any($1)`, uids)
		_, _ = h.db.Exec(ctx, `delete from mensagens where negociacao_id in (select id from negociacoes where uid_a = any($1) or uid_b = any($1))`, uids)
		_, _ = h.db.Exec(ctx, `delete from negociacoes where uid_a = any($1) or uid_b = any($1)`, uids)
	}

	// Cria negociações pré-existentes.
	negociacoesCriadas := 0
	for _, nq := range seedNegociacoes {
		uidA := emailToUID[nq.LoteAOwnerEmail]
		uidB := emailToUID[nq.LoteBOwnerEmail]
		loteA, okA := emailToLotes[nq.LoteAOwnerEmail][nq.LoteAFiltroTitulo]
		loteB, okB := emailToLotes[nq.LoteBOwnerEmail][nq.LoteBFiltroTitulo]
		if !okA || !okB {
			continue
		}

		var negID uuid.UUID
		err := h.db.QueryRow(ctx, `
			insert into negociacoes (lote_a, lote_b, uid_a, uid_b, status)
			values ($1,$2,$3,$4,$5) returning id
		`, loteA, loteB, uidA, uidB, nq.Status).Scan(&negID)
		if err != nil {
			continue
		}

		// Pra ficar interessante, mete 1 item de cada lado na mesa
		// e dispara o atualizar_mesa pra calcular torna.
		var itemA, itemB uuid.UUID
		_ = h.db.QueryRow(ctx, `select id from itens where lote_id = $1 order by criado_em limit 1`, loteA).Scan(&itemA)
		_ = h.db.QueryRow(ctx, `select id from itens where lote_id = $1 order by criado_em limit 1`, loteB).Scan(&itemB)
		if itemA != uuid.Nil && itemB != uuid.Nil {
			_, _ = h.db.Exec(ctx, `select * from atualizar_mesa($1, $2, $3, $4)`,
				negID, []uuid.UUID{itemA}, []uuid.UUID{itemB}, uidA)
		}

		// Mensagem inicial automática
		_, _ = h.db.Exec(ctx, `
			insert into mensagens (negociacao_id, sender_id, texto, tipo) values
			($1, $2, 'Topa a troca?', 'texto'),
			($1, $3, 'Topo, mas tem como melhorar minha torna?', 'texto')
		`, negID, uidA, uidB)

		negociacoesCriadas++
	}

	// Avaliações pré-existentes (alimentam reputação via trigger).
	avaliacoesCriadas := 0
	for _, av := range seedAvaliacoes {
		uidDe, okDe := emailToUID[av.De]
		uidPara, okPara := emailToUID[av.Para]
		if !okDe || !okPara {
			continue
		}
		// Avaliacoes tem unique(de_id, negociacao_id) — pra contornar, gera negID fake fixo por par.
		fakeNegID := uuid.NewSHA1(uuid.NameSpaceURL,
			[]byte(fmt.Sprintf("seed-aval:%s:%s", av.De, av.Para)))

		// Insere uma negociação stub aceita pra satisfazer a FK
		_, _ = h.db.Exec(ctx, `
			insert into negociacoes (id, lote_a, lote_b, uid_a, uid_b, status)
			select $1, l1.id, l2.id, $2, $3, 'aceita'
			  from lotes l1, lotes l2
			 where l1.dono_id = $2 and l2.dono_id = $3
			 limit 1
			on conflict (id) do nothing
		`, fakeNegID, uidDe, uidPara)

		_, _ = h.db.Exec(ctx, `
			insert into avaliacoes (de_id, para_id, negociacao_id, nota, comentario)
			values ($1, $2, $3, $4, $5)
			on conflict (de_id, negociacao_id) do nothing
		`, uidDe, uidPara, fakeNegID, av.Nota, av.Coment)
		avaliacoesCriadas++
	}

	c.JSON(http.StatusOK, gin.H{
		"personas_criadas":   personasCriadas,
		"lotes_criados":      lotesCriados,
		"itens_criados":      itensCriados,
		"negociacoes_criadas": negociacoesCriadas,
		"avaliacoes_criadas": avaliacoesCriadas,
	})
}

func (h *SeedHandler) ensureUser(ctx context.Context, email, nome string) (uuid.UUID, error) {
	var id uuid.UUID
	err := h.db.QueryRow(ctx, `select id from auth.users where email = $1`, email).Scan(&id)
	if err == nil {
		return id, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, err
	}

	body, _ := json.Marshal(map[string]any{
		"email":         email,
		"password":      "dev-only-" + uuid.NewString(),
		"email_confirm": true,
		"user_metadata": map[string]string{"nome": nome, "source": "dev_seed_mundo"},
	})
	url := strings.TrimRight(h.cfg.SupabaseURL, "/") + "/auth/v1/admin/users"
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", h.cfg.SupabaseSecretKey)
	req.Header.Set("Authorization", "Bearer "+h.cfg.SupabaseSecretKey)
	resp, err := h.hc.Do(req)
	if err != nil {
		return uuid.Nil, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return uuid.Nil, fmt.Errorf("admin api %d: %s", resp.StatusCode, string(raw))
	}
	var out struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(raw, &out); err != nil {
		return uuid.Nil, err
	}
	return uuid.Parse(out.ID)
}

func wipeUser(ctx context.Context, tx pgx.Tx, uid uuid.UUID) error {
	// Ordem importa por causa das FKs:
	// avaliacoes → mensagens → negociacoes → itens → lotes
	if _, err := tx.Exec(ctx, `delete from avaliacoes where de_id = $1 or para_id = $1`, uid); err != nil {
		return fmt.Errorf("limpa avaliacoes: %w", err)
	}
	if _, err := tx.Exec(ctx, `
		delete from mensagens where negociacao_id in (
			select id from negociacoes where uid_a = $1 or uid_b = $1
		)
	`, uid); err != nil {
		return fmt.Errorf("limpa mensagens: %w", err)
	}
	if _, err := tx.Exec(ctx, `delete from negociacoes where uid_a = $1 or uid_b = $1`, uid); err != nil {
		return fmt.Errorf("limpa negociacoes: %w", err)
	}
	if _, err := tx.Exec(ctx, `delete from itens where dono_id = $1`, uid); err != nil {
		return fmt.Errorf("limpa itens: %w", err)
	}
	if _, err := tx.Exec(ctx, `delete from lotes where dono_id = $1`, uid); err != nil {
		return fmt.Errorf("limpa lotes: %w", err)
	}
	return nil
}

func insertSeedLotes(ctx context.Context, tx pgx.Tx, uid uuid.UUID, lotes []seedLote) (int, error) {
	_, n, err := insertSeedLotesReturning(ctx, tx, uid, lotes)
	return n, err
}

func insertSeedLotesReturning(ctx context.Context, tx pgx.Tx, uid uuid.UUID, lotes []seedLote) (map[string]uuid.UUID, int, error) {
	ids := map[string]uuid.UUID{}
	total := 0
	for _, lt := range lotes {
		var loteID uuid.UUID
		if err := tx.QueryRow(ctx, `
			insert into lotes (dono_id, titulo, setor_principal, faixa_alvo_min, faixa_alvo_max)
			values ($1,$2,$3,$4,$5) returning id
		`, uid, lt.titulo, lt.setor, lt.faixaMin, lt.faixaMax).Scan(&loteID); err != nil {
			return ids, total, fmt.Errorf("lote %q: %w", lt.titulo, err)
		}
		ids[lt.titulo] = loteID
		for _, it := range lt.itens {
			campos := map[string]string{}
			if it.campos != nil {
				campos = it.campos
			}
			fotos := []string{}
			if it.foto != "" {
				fotos = []string{it.foto}
			}
			if _, err := tx.Exec(ctx, `
				insert into itens (dono_id, titulo, descricao, setor_slug, categoria, valor_referencia, campos, fotos, lote_id)
				values ($1,$2,$3,$4,$5,$6,$7,$8,$9)
			`, uid, it.titulo, it.descricao, lt.setor, it.categoria, it.valor, campos, fotos, loteID); err != nil {
				return ids, total, fmt.Errorf("item %q: %w", it.titulo, err)
			}
			total++
		}
	}
	return ids, total, nil
}
