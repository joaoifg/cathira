package handler

import (
	"context"
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// Gerador de massa: cria milhares de lotes mockados (com fotos picsum) distribuídos
// entre um pool de personas "bulk", pra encher o feed de Descobrir.
//
//   POST /dev/seed-massa?lotes=1500&personas=40&min_itens=1&max_itens=4&fotos_max=3
//
// É idempotente: limpa os lotes/itens das personas bulk antes de gerar de novo.

type massaSetor struct {
	slug    string
	cidades bool // só ilustrativo; usamos lista global de cidades
	cats    []string
	titulos []string // templates de título de lote
	marcas  []string // pra compor nome do item
	produto []string // substantivo do item
	valMin  float64
	valMax  float64
	faixaLo float64
	faixaHi float64
}

var massaCidades = []string{
	"São Paulo", "Rio de Janeiro", "Belo Horizonte", "Curitiba", "Porto Alegre",
	"Salvador", "Recife", "Fortaleza", "Brasília", "Manaus", "Florianópolis",
	"Goiânia", "Vitória", "Campinas", "Belém", "Niterói", "Santos", "Natal",
	"João Pessoa", "Maceió", "Cuiabá", "Campo Grande", "Londrina", "Joinville",
}

var massaEstados = []string{"novo", "seminovo", "usado"}

var massaSetores = []massaSetor{
	{
		slug: "automoveis",
		cats: []string{"hatch", "sedan", "suv", "picape", "moto"},
		titulos: []string{"Garagem completa", "Carro + moto", "Família trocando de carro",
			"Coleção sobre rodas", "Veículo seminovo", "Lote automotivo"},
		marcas:  []string{"Honda", "Toyota", "VW", "Fiat", "Chevrolet", "Hyundai", "Jeep", "Yamaha", "BMW", "Renault"},
		produto: []string{"Civic", "Corolla", "Onix", "HB20", "Compass", "Hilux", "MT-09", "Gol", "Polo", "Strada"},
		valMin:  18000, valMax: 160000, faixaLo: 20000, faixaHi: 200000,
	},
	{
		slug: "eletronicos",
		cats: []string{"smartphone", "notebook", "console", "tv", "camera", "audio"},
		titulos: []string{"Setup gamer completo", "Kit fotógrafo", "Home office top",
			"Sala de cinema", "Smart home premium", "Lote de eletrônicos"},
		marcas:  []string{"Apple", "Samsung", "Sony", "LG", "Dell", "Asus", "Canon", "Microsoft", "JBL", "Logitech"},
		produto: []string{"iPhone 15", "Galaxy S24", "PS5 Slim", "MacBook Pro", "OLED 65''", "EOS R50", "Xbox Series X", "Headset 7.1", "Monitor ultrawide", "Soundbar"},
		valMin:  1200, valMax: 22000, faixaLo: 2000, faixaHi: 30000,
	},
	{
		slug: "instrumentos",
		cats: []string{"guitarra", "violao", "bateria", "piano", "sopro", "estudio"},
		titulos: []string{"Estúdio caseiro", "Studio musical", "Setup de áudio hi-fi",
			"Bateria completa", "Pedalboard + amp", "Lote de instrumentos"},
		marcas:  []string{"Fender", "Gibson", "Yamaha", "Marshall", "Pioneer", "Roland", "Shure", "Mapex", "Ibanez", "Tagima"},
		produto: []string{"Stratocaster", "Les Paul", "Piano P-125", "DSL40 combo", "DDJ-FLX6", "Bateria Tornado", "Kit SM58", "Pedalboard", "Violão eletroacústico", "Sintetizador"},
		valMin:  250, valMax: 16000, faixaLo: 1500, faixaHi: 20000,
	},
	{
		slug: "imoveis",
		cats: []string{"apto", "casa", "terreno", "comercial", "rural"},
		titulos: []string{"Apto no centro", "Casa com quintal", "Sala comercial",
			"Terreno em condomínio", "Sítio com lago", "Imóvel pra permuta"},
		marcas:  []string{"Centro", "Zona Sul", "Zona Norte", "Bairro nobre", "Litoral", "Condomínio fechado", "Beira-mar", "Interior"},
		produto: []string{"Apto 60m² 2 quartos", "Casa 3 quartos", "Studio 30m²", "Sala 80m²", "Terreno 360m²", "Sítio 5000m²", "Cobertura duplex", "Kitnet mobiliada"},
		valMin:  120000, valMax: 900000, faixaLo: 150000, faixaHi: 1200000,
	},
	{
		slug: "livros",
		cats: []string{"literatura", "hq", "manga", "tecnico", "colecao", "ebook"},
		titulos: []string{"Biblioteca pessoal", "Coleção de HQs", "Mangás raros",
			"Livros de medicina", "Box edição luxo", "Lote de livros"},
		marcas:  []string{"Rocco", "Panini", "Darkside", "Companhia das Letras", "HarperCollins", "Marvel", "DC", "Elsevier"},
		produto: []string{"Coleção Harry Potter", "Senhor dos Anéis luxo", "Berserk Deluxe 1-10", "One Piece 1-50", "Sandman definitivo", "Watchmen", "Kit residência médica", "Saga Fundação"},
		valMin:  80, valMax: 2400, faixaLo: 200, faixaHi: 3000,
	},
	{
		slug: "outdoor",
		cats: []string{"camping", "escalada", "trilha", "pesca", "barraca", "mochila"},
		titulos: []string{"Camping de praia", "Escalada outdoor", "Pacote de pesca",
			"Outdoor de viagem", "Trilha pesada", "Lote outdoor"},
		marcas:  []string{"Coleman", "Yeti", "Petzl", "Mammut", "Osprey", "MSR", "Deuter", "Shimano", "Quechua", "JetBoil"},
		produto: []string{"Barraca 4 pessoas", "Cooler 24L", "Corda dinâmica 70m", "Cadeirinha de escalada", "Mochila 65L", "Fogareiro", "Vara + molinete", "Saco de dormir -5°C"},
		valMin:  250, valMax: 4200, faixaLo: 500, faixaHi: 8000,
	},
	{
		slug: "esportivo",
		cats: []string{"chuteira", "bola", "uniforme", "luva"},
		titulos: []string{"Kit futebol pro", "Tênis competitivo", "Surf life",
			"Bike + acessórios", "Esportes náuticos", "Lote esportivo"},
		marcas:  []string{"Nike", "Adidas", "Wilson", "Caloi", "Specialized", "Rip Curl", "Reusch", "Asics", "Penalty", "Mizuno"},
		produto: []string{"Chuteira Predator", "Bola oficial", "Raquete Pro Staff", "Bike speed", "Prancha 6'2", "Neoprene 3/2", "Luva de goleiro", "Skate completo"},
		valMin:  120, valMax: 4500, faixaLo: 200, faixaHi: 6000,
	},
}

// Massa — POST /dev/seed-massa
func (h *SeedHandler) Massa(c *gin.Context) {
	ctx := c.Request.Context()

	nLotes := atoiDefault(c.Query("lotes"), 1500)
	nPersonas := atoiDefault(c.Query("personas"), 40)
	minItens := atoiDefault(c.Query("min_itens"), 1)
	maxItens := atoiDefault(c.Query("max_itens"), 4)
	fotosMax := atoiDefault(c.Query("fotos_max"), 3)

	if nLotes < 1 {
		nLotes = 1
	}
	if nLotes > 20000 {
		nLotes = 20000 // teto de segurança
	}
	if nPersonas < 1 {
		nPersonas = 1
	}
	if nPersonas > 200 {
		nPersonas = 200
	}
	if minItens < 1 {
		minItens = 1
	}
	if maxItens < minItens {
		maxItens = minItens
	}
	if fotosMax < 1 {
		fotosMax = 1
	}

	// rand determinístico pra reprodutibilidade.
	rng := rand.New(rand.NewSource(20260608))

	// 1) Garante o pool de personas bulk.
	bulkUIDs := make([]uuid.UUID, 0, nPersonas)
	for i := 0; i < nPersonas; i++ {
		email := fmt.Sprintf("demo+bulk%03d@local.test", i)
		nome := fmt.Sprintf("%s %s", primeiroNome(i), sobrenome(i))
		uid, err := h.ensureUser(ctx, email, nome)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": fmt.Sprintf("persona bulk %s: %s", email, err),
			})
			return
		}
		cidade := massaCidades[i%len(massaCidades)]
		_, _ = h.db.Exec(ctx, `
			insert into profiles (id, nome, cidade, reputacao)
			values ($1,$2,$3,$4)
			on conflict (id) do update set nome = excluded.nome, cidade = excluded.cidade, reputacao = excluded.reputacao
		`, uid, nome, cidade, 3.5+rng.Float64()*1.5)
		bulkUIDs = append(bulkUIDs, uid)
	}

	// 2) Limpa lotes/itens antigos das personas bulk (idempotência).
	//    itens.lote_id é ON DELETE SET NULL, então apaga itens por dono antes dos lotes.
	_, _ = h.db.Exec(ctx, `delete from itens where dono_id = any($1)`, bulkUIDs)
	_, _ = h.db.Exec(ctx, `delete from lotes where dono_id = any($1)`, bulkUIDs)

	// 3) Monta tudo em memória (ids gerados no client pra não depender de RETURNING),
	//    depois insere em lote (multi-row) — o banco é remoto, então minimizar
	//    round-trips é o que importa.
	loteRows := make([][]any, 0, nLotes)
	itemRows := make([][]any, 0, nLotes*((minItens+maxItens)/2+1))
	fotosCriadas := 0

	for i := 0; i < nLotes; i++ {
		st := massaSetores[rng.Intn(len(massaSetores))]
		dono := bulkUIDs[i%len(bulkUIDs)]
		cidade := massaCidades[rng.Intn(len(massaCidades))]
		titulo := fmt.Sprintf("%s #%d", st.titulos[rng.Intn(len(st.titulos))], i+1)
		loteID := uuid.New()

		loteRows = append(loteRows, []any{loteID, dono, titulo, st.slug, st.faixaLo, st.faixaHi, cidade})

		qtdItens := minItens + rng.Intn(maxItens-minItens+1)
		for j := 0; j < qtdItens; j++ {
			cat := st.cats[rng.Intn(len(st.cats))]
			marca := st.marcas[rng.Intn(len(st.marcas))]
			prod := st.produto[rng.Intn(len(st.produto))]
			estado := massaEstados[rng.Intn(len(massaEstados))]
			valor := st.valMin + rng.Float64()*(st.valMax-st.valMin)
			itTitulo := fmt.Sprintf("%s %s", marca, prod)
			descricao := fmt.Sprintf("%s — estado %s, item de demonstração", itTitulo, estado)
			campos := map[string]string{"marca": marca, "estado": estado}

			// 1..fotosMax fotos picsum, cada uma com seed único e estável.
			qtdFotos := 1 + rng.Intn(fotosMax)
			fotos := make([]string, 0, qtdFotos)
			for k := 0; k < qtdFotos; k++ {
				fotos = append(fotos, picsum(fmt.Sprintf("massa-%d-%d-%d", i, j, k)))
			}
			fotosCriadas += qtdFotos

			itemRows = append(itemRows, []any{uuid.New(), dono, itTitulo, descricao, st.slug, cat, valor, campos, fotos, loteID})
		}
	}

	tx, err := h.db.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer tx.Rollback(ctx)

	// Desliga o trigger de recálculo durante a carga (recalcula no fim de uma vez)
	// e insere em chunks multi-row.
	if _, err := tx.Exec(ctx, `alter table itens disable trigger trg_recalc_lote`); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "disable trigger: " + err.Error()})
		return
	}

	if err := bulkInsert(ctx, tx, "lotes",
		[]string{"id", "dono_id", "titulo", "setor_principal", "faixa_alvo_min", "faixa_alvo_max", "cidade"},
		loteRows, 700); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "insert lotes: " + err.Error()})
		return
	}
	if err := bulkInsert(ctx, tx, "itens",
		[]string{"id", "dono_id", "titulo", "descricao", "setor_slug", "categoria", "valor_referencia", "campos", "fotos", "lote_id"},
		itemRows, 500); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "insert itens: " + err.Error()})
		return
	}

	// Recalcula valor_total de todos os lotes bulk de uma vez e religa o trigger.
	if _, err := tx.Exec(ctx, `
		update lotes l set valor_total = coalesce(s.soma, 0)
		  from (select lote_id, sum(valor_referencia) soma from itens where dono_id = any($1) group by lote_id) s
		 where l.id = s.lote_id
	`, bulkUIDs); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "recalc valor: " + err.Error()})
		return
	}
	if _, err := tx.Exec(ctx, `alter table itens enable trigger trg_recalc_lote`); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "enable trigger: " + err.Error()})
		return
	}

	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"personas_bulk": len(bulkUIDs),
		"lotes_criados": len(loteRows),
		"itens_criados": len(itemRows),
		"fotos_criadas": fotosCriadas,
	})
}

// bulkInsert insere rows em statements multi-row de até chunk linhas cada.
func bulkInsert(ctx context.Context, tx pgx.Tx, table string, cols []string, rows [][]any, chunk int) error {
	if len(rows) == 0 {
		return nil
	}
	nc := len(cols)
	colList := strings.Join(cols, ", ")
	for start := 0; start < len(rows); start += chunk {
		end := start + chunk
		if end > len(rows) {
			end = len(rows)
		}
		batch := rows[start:end]
		args := make([]any, 0, len(batch)*nc)
		var sb strings.Builder
		fmt.Fprintf(&sb, "insert into %s (%s) values ", table, colList)
		for ri, row := range batch {
			if ri > 0 {
				sb.WriteByte(',')
			}
			sb.WriteByte('(')
			for ci := range cols {
				if ci > 0 {
					sb.WriteByte(',')
				}
				fmt.Fprintf(&sb, "$%d", ri*nc+ci+1)
			}
			sb.WriteByte(')')
			args = append(args, row...)
		}
		if _, err := tx.Exec(ctx, sb.String(), args...); err != nil {
			return err
		}
	}
	return nil
}

func atoiDefault(s string, def int) int {
	if s == "" {
		return def
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		return def
	}
	return n
}

var massaPrimeiros = []string{
	"Lucas", "Mariana", "Pedro", "Ana", "Rafael", "Juliana", "Bruno", "Camila",
	"Diego", "Patrícia", "Eduardo", "Fernanda", "Thiago", "Larissa", "Vinícius",
	"Daniela", "Gabriel", "Isabela", "Ricardo", "Aline", "Marcelo", "Sofia",
	"Felipe", "Renata", "André", "Beatriz", "Caio", "Letícia", "Gustavo", "Natália",
}

var massaSobrenomes = []string{
	"Souza", "Lima", "Pereira", "Mendes", "Cardoso", "Vargas", "Castro", "Tavares",
	"Rocha", "Andrade", "Nogueira", "Martins", "Lopes", "Pinto", "Duarte", "Almeida",
	"Vieira", "Carvalho", "Moura", "Barros", "Reis", "Santos", "Freitas", "Gomes",
}

func primeiroNome(i int) string { return massaPrimeiros[i%len(massaPrimeiros)] }
func sobrenome(i int) string    { return massaSobrenomes[(i/len(massaPrimeiros)+i)%len(massaSobrenomes)] }
