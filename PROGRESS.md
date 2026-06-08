# Permuta — Progresso

Documento vivo do que está pronto. Atualizar a cada marco.

Última atualização: **2026-06-07**.

---

## Estado atual

**Fase 0 — Fundação** ✅
**Fase 1 — Núcleo CRUD** ✅
**Fase 2 — Mesa de negociação (diferencial)** ✅

| Camada | Status |
|---|---|
| Migrations Postgres (schema + torna + RLS + Realtime + Storage) | ✅ 11/11 aplicadas |
| Função `calcular_torna` + `atualizar_mesa` + `aceitar_negociacao` | ✅ |
| Trigger `recalc_valor_lote` + `recalc_reputacao` | ✅ |
| RLS em todas as tabelas + policies do bucket `itens` | ✅ |
| 5 setores (esportivo, automoveis, eletronicos, instrumentos, imoveis) com ícone, cor, tagline | ✅ |
| Realtime habilitado (`negociacoes`, `mensagens`) | ✅ |
| Go API: Gin + pgx + middleware JWT HS256 + CORS | ✅ |
| CRUD: lotes/itens/swipes/negociações + descoberta + mesa + aceite | ✅ |
| `POST /dev/login` (gerador de JWT pra user dev, com email opcional) | ✅ |
| `POST /dev/seed` + `POST /dev/seed-mundo` + `POST /dev/upload` | ✅ |
| Flutter: Riverpod + Supabase + Dio + image_picker | ✅ |
| Tema vermelho/laranja com gradientes + design system | ✅ |
| Bottom nav 6 abas + badge de negociações pendentes | ✅ |
| Tela de login com hero + Como funciona + dev login | ✅ |
| Home com hero, stats, grid de setores colorido, CTA | ✅ |
| Meus Lotes + Novo Lote + Detalhe (juntar/desjuntar itens, valor ao vivo) | ✅ |
| Meus Itens + Novo Item (com upload de foto via Storage) | ✅ |
| **Descoberta com swipe** (cards estilo Tinder, like/pass, dialog de match) | ✅ |
| **Mesa de negociação** (split em 2 lados, torna ao vivo, aceite mútuo) | ✅ |
| **Realtime na mesa** (assina UPDATE em `negociacoes`) | ✅ |
| Perfil com troca de persona + popular meu seed + popular mundo | ✅ |

---

## Arquitetura

```
┌──────────────────────────────┐
│        Flutter app           │
│  - Riverpod, Dio, Realtime   │
│  - 6 abas: Home / Descobrir  │
│    / Lotes / Itens / Negócios│
│    / Perfil                  │
└──────────────┬───────────────┘
               │ REST (Bearer JWT)        WebSocket (Realtime)
               ▼                                ▼
        ┌──────────────┐              ┌─────────────────┐
        │   Go API     │◀────────────▶│  Supabase       │
        │ (Gin + pgx)  │  Admin API   │  - Auth         │
        │              │  Storage     │  - Postgres+RLS │
        │              │  Realtime    │  - Storage      │
        └──────┬───────┘              │  - Realtime WS  │
               │ pgx                  └─────────────────┘
               ▼
        ┌─────────────────────┐
        │  Supabase Postgres  │
        │  + função torna     │
        │  + triggers         │
        │  + Realtime publi.  │
        └─────────────────────┘
```

**Decisões registradas:**

- Torna mora no Postgres (`calcular_torna`, `atualizar_mesa`, `aceitar_negociacao`).
- `atualizar_mesa` faz lock, recalcula torna, **incrementa versão e zera aceites** — qualquer mudança invalida aceite anterior.
- Aceite mútuo (`aceite_a AND aceite_b`) → status vira `aceita`, lotes vão pra `fechado`, itens vão pra `trocado` — tudo na função do banco.
- RLS bloqueia escrita direta em `negociacoes` pelo cliente. Quem escreve é a Go API com `service_role`.
- Realtime: Flutter assina `postgres_changes` na tabela `negociacoes` filtrado por id. `replica identity full` na tabela faz o payload incluir o registro completo.
- Dev login: nosso JWT é HS256 assinado com o mesmo secret que o Supabase usa, então middleware **e** o Supabase Realtime aceitam (via `realtime.setAuth(token)`).
- Upload de foto: Flutter manda multipart pro backend, backend proxia pro Storage com a service key. Funciona tanto com dev login quanto com login real, sem precisar do SDK do Supabase no client.

---

## Estrutura

```
cathira/
├── README.md
├── PROGRESS.md                    # este arquivo
│
├── permuta-api/
│   ├── cmd/api/main.go
│   ├── internal/
│   │   ├── config/
│   │   ├── server/
│   │   ├── middleware/
│   │   │   ├── auth.go            # JWT HS256
│   │   │   ├── cors.go            # libera Chrome em dev
│   │   │   └── logging.go
│   │   ├── domain/                # Lote, Item, Negociacao
│   │   ├── repository/
│   │   ├── service/
│   │   └── handler/
│   │       ├── auth_handler.go    # POST /auth/me
│   │       ├── dev_handler.go     # POST /dev/login (nome ou email)
│   │       ├── seed_handler.go    # /dev/seed + /dev/seed-mundo
│   │       ├── upload_handler.go  # /dev/upload (proxy → Storage)
│   │       ├── setor_handler.go
│   │       ├── lote_handler.go    # CRUD + /lotes/meus + descoberta
│   │       ├── item_handler.go    # CRUD + /itens/meus + PATCH move
│   │       ├── swipe_handler.go
│   │       └── negociacao_handler.go # list + detalhe + mesa + aceitar
│   └── db/migrations/
│       ├── 0001 extensions
│       ├── 0002 profiles
│       ├── 0003 setores (seed esportivo)
│       ├── 0004 lotes + itens (trigger valor_total)
│       ├── 0005 swipes + negociacoes
│       ├── 0006 mensagens + avaliacoes (trigger reputacao)
│       ├── 0007 funções calcular_torna + atualizar_mesa + aceitar
│       ├── 0008 RLS
│       ├── 0009 setores extras (cor, ícone, +4 setores)
│       ├── 0010 storage bucket itens + policies
│       └── 0011 realtime publication
│
└── permuta_app/
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── env/env.dart
        │   ├── theme/app_theme.dart      # gradiente vermelho/laranja
        │   ├── supabase/supabase_providers.dart
        │   ├── http/api_client.dart      # Dio + dev token OU JWT real
        │   └── router/
        │       ├── app_router.dart       # AuthGate
        │       └── app_shell.dart        # bottom nav 6 abas
        ├── features/
        │   ├── auth/
        │   │   ├── login_screen.dart     # hero + OTP + Google + dev
        │   │   └── dev_auth.dart         # provider + controller
        │   ├── setores/home_screen.dart  # hero, stats, grid setores
        │   ├── lotes/
        │   │   ├── meus_lotes_screen.dart
        │   │   ├── novo_lote_screen.dart
        │   │   └── lote_detalhe_screen.dart # junta/desjunta itens
        │   ├── itens/
        │   │   ├── meus_itens_screen.dart
        │   │   └── novo_item_screen.dart # upload foto + campos extras
        │   ├── descoberta/
        │   │   └── descoberta_screen.dart # swipe like/pass + match
        │   ├── negociacao/
        │   │   ├── negociacoes_screen.dart # lista
        │   │   └── mesa_screen.dart      # tela-estrela com Realtime
        │   └── perfil/
        │       └── perfil_screen.dart    # troca persona + seed
        └── shared/
            ├── models/models.dart
            ├── providers/data_providers.dart
            └── widgets/brl.dart
```

---

## Como rodar local

`.env` do backend já preenchido com o projeto `hhijyhzhxcndnzevpuoj`.

```powershell
# Terminal 1 - API
cd C:\Users\style\Documents\cathira\permuta-api
go run ./cmd/api
```

```powershell
# Terminal 2 - Flutter
cd C:\Users\style\Documents\cathira\permuta_app

flutter run -d chrome --web-port=7357 `
  --dart-define=SUPABASE_URL=https://hhijyhzhxcndnzevpuoj.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_-S0bPwYo-JBYSxZ8Q_M0bw_g9DKhMSB `
  --dart-define=API_BASE_URL=http://localhost:8080 `
  --dart-define=DEV_MODE=true
```

---

## Roteiro de teste (3 minutos pra ver tudo funcionando)

1. **Login** → clica "Entrar como dev" no card de login (logado como `Joao Dev`).
2. **Perfil** → "Popular meus lotes" (cria 4 lotes pra você) **e** "Popular mundo demo" (cria Maria, Pedro, Ana com 7 lotes total).
3. **Home** → vê stats atualizadas, grid colorido de setores.
4. **Meus lotes** → 4 lotes com totais. Abre um → vê os itens dentro com valor.
   - Tira o item "PS5 Slim" do lote → ele vai pra "Itens soltos".
   - Adiciona de volta → trigger no banco recalcula o total.
5. **Itens** → catálogo com chips de setor/lote. Botão `+` → cria item novo com upload de foto (vai pro Storage).
6. **Descobrir** → escolhe seu lote no topo. Vê cards das personas. Dá like.
7. **Trocar de persona** → no Perfil, clica em "Maria Souza". Agora você está logado como Maria, abre Descobrir, dá like de volta no seu lote do Joao → **MATCH!**
8. Dialog de match → **Abrir mesa**.
9. **Mesa de negociação** → vê dois lados, lista de itens disponíveis em cada lote.
   - Clica `+` num item → ele entra na mesa, valor recalcula, **torna aparece em tempo real**.
   - Clica `Aceitar como está` → indicador "Eu ✓" aparece.
10. Volta pra Joao no Perfil → vai em Negócios → abre a mesma negociação → mesmo estado (realtime já trouxe a versão atual).
   - Aceita → ambos aceitos → status muda pra **"Troca aceita pelos dois lados"**.

---

## Endpoints

```
GET   /healthz                                 # público

# DEV (só com DEV_MODE=true)
POST  /dev/login          {nome?, email?}      # devolve JWT HS256
POST  /dev/seed                                # popula 4 lotes pro user
POST  /dev/seed-mundo                          # cria 3 personas + lotes
POST  /dev/upload         (multipart file)     # proxy → Storage

# Autenticadas (Authorization: Bearer <jwt>)
POST  /auth/me
GET   /setores                                 # com icone/cor/tagline

POST  /lotes
GET   /lotes/meus
GET   /lotes/:id                               # lote + itens dentro
POST  /lotes/:id/itens

POST  /itens                                   # cria sem lote
GET   /itens/meus
PATCH /itens/:id          {lote_id?: uuid}     # move entre lotes / solta

GET   /descoberta?setor=&faixa_min=&faixa_max=&limit=
POST  /swipes             {from_lote, to_lote, decisao}
                                              # retorna {match, negociacao_id}

GET   /negociacoes                             # lista minhas
GET   /negociacoes/:id                         # detalhe + lotes + itens dos dois lados
POST  /negociacoes/:id/mesa  {itens_a, itens_b} # recalcula torna, zera aceites
POST  /negociacoes/:id/aceitar                 # aceite individual
```

---

## Próximos passos

- **Chat dentro da negociação** (tabela `mensagens` já existe + Realtime ligado, só falta UI)
- **Push notification** quando rola match ou o outro lado mexe na mesa (FCM)
- **Avaliações pós-troca** (`POST /avaliacoes`) — schema já pronto, trigger atualiza reputação
- **Filtro de descoberta por geolocalização** (PostGIS + `geolocator` no Flutter)
- **Tabela FIPE** integrada como sugestão de valor pra setor automóveis
- **Onboarding de auth real** (Twilio SMS + Google OAuth no Supabase)
- **Substituir bucket público por signed URLs** quando sair de dev

---

## Débitos técnicos conhecidos

- `atualizar_mesa` não valida se os itens passados pertencem aos lotes da negociação — confia no client. Endurecer antes de produção.
- Bucket `itens` é público; deveria gerar signed URLs em produção e usar policies mais restritivas.
- `/dev/seed-mundo` cria usuários com senha aleatória `dev-only-<uuid>` que ninguém vai usar — limpar antes de produção via job de cleanup.
- Image upload vai sempre pelo backend (mesmo com login real). Quando ligar auth real, deveria ir direto do Flutter pro Storage via SDK pra liberar o backend.
- Realtime usa `replica identity full` que aumenta WAL size — monitorar se virar issue.
