# Permuta

Marketplace de **permuta multilateral com equalização de valor** (lotes + torna automática).

Spec completa em `spec-permuta-lotes.md` (raiz do projeto, se você anexou). Codinome: *Permuta*.

```
cathira/
├── permuta-api/    # backend Go (Gin + pgx)
└── permuta_app/    # mobile Flutter
```

## Stack

| Camada | Escolha |
|---|---|
| Mobile | Flutter + Riverpod |
| Backend | Go 1.25 + Gin + pgx |
| Auth | Supabase Auth (JWT HS256) |
| Banco | Supabase Postgres + PostGIS |
| Storage | Supabase Storage (fotos dos itens) |
| Realtime | Supabase Realtime (chat / mesa) |
| Migrations | golang-migrate (`Makefile`) |

A regra de torna fica no Postgres (`calcular_torna`, `atualizar_mesa`,
`aceitar_negociacao`). A Go API só orquestra; ela nunca recalcula valor
no servidor pra evitar drift entre cliente e banco.

---

## Setup

### 1. Supabase

1. Cria projeto em https://supabase.com → guarda a **senha do Postgres**.
2. **Settings → API**:
   - `Project URL` → `SUPABASE_URL`
   - `anon public` key → `SUPABASE_ANON_KEY`
   - `service_role` key → `SUPABASE_SERVICE_KEY` (só backend, nunca no app)
   - `JWT Secret` → `SUPABASE_JWT_SECRET`
3. **Settings → Database** → `Connection string (URI)` → `DATABASE_URL`.
4. **Authentication → Providers**: liga **Phone** (Twilio/Vonage) e/ou **Google**.

### 2. Migrations

Precisa do `golang-migrate` instalado:

```powershell
# Windows
scoop install migrate
```

```bash
cd permuta-api
cp .env.example .env       # preencha as variáveis
# carrega a DATABASE_URL e roda
$env:DATABASE_URL = (Get-Content .env | Select-String '^DATABASE_URL=').ToString().Split('=',2)[1]
make migrate-up
```

Em SQL puro o que rodou:
- `0001` extensões (`pgcrypto`, `postgis`)
- `0002` profiles
- `0003` setores (já com seed do setor `esportivo`)
- `0004` lotes + itens + trigger `recalc_valor_lote`
- `0005` swipes + negociacoes
- `0006` mensagens + avaliacoes (+ trigger `recalc_reputacao`)
- `0007` funções `calcular_torna`, `atualizar_mesa`, `aceitar_negociacao`
- `0008` Row Level Security

### 3. Backend

```bash
cd permuta-api
make tidy
make run         # sobe em :8080
curl http://localhost:8080/healthz
```

### 4. Mobile

O app lê config via `--dart-define`:

```bash
cd permuta_app
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` é como o emulador Android enxerga o `localhost` do host. No iOS use o IP da máquina.

---

## Endpoints (todos protegidos por JWT do Supabase)

```
GET  /healthz                       # público

POST /auth/me                       # upsert do profile
GET  /setores                       # cards da home

POST /lotes                         # cria lote
GET  /lotes/:id                     # detalhe + itens
POST /lotes/:id/itens               # adiciona item

GET  /descoberta?setor=&faixa_min=&faixa_max=&limit=
POST /swipes                        # {from_lote, to_lote, decisao}

GET  /negociacoes                   # minhas negociações
POST /negociacoes/:id/mesa          # atualiza itens da mesa (recalcula torna)
POST /negociacoes/:id/aceitar       # marca aceite (fecha se ambos)
```

## Status

- [x] Fase 0 — fundação (schema, função torna, auth middleware, scaffold Flutter)
- [ ] Fase 1 — núcleo de troca (CRUD funcional + descoberta + swipe)
- [ ] Fase 2 — mesa de negociação (UI da mesa + Realtime)
- [ ] Fase 3 — confiança (avaliações + push)
- [ ] Fase 4 — Automóveis + Imóveis
