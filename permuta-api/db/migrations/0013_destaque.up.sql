-- Sistema de destaque pago: itens/lotes promovidos aparecem primeiro
-- no feed enquanto destaque_ate > now(). Quando vencer, volta a aparecer
-- na ordem natural.

alter table itens add column if not exists destaque_ate timestamptz;
alter table lotes add column if not exists destaque_ate timestamptz;

create index if not exists idx_itens_destaque on itens (destaque_ate)
  where destaque_ate is not null;
create index if not exists idx_lotes_destaque on lotes (destaque_ate)
  where destaque_ate is not null;

-- Tabela de "pagamentos" do destaque (auditoria + revenue tracking).
-- Por enquanto sem integração real de pagamento — só registra.
create table if not exists destaques_pagamentos (
  id            uuid primary key default gen_random_uuid(),
  alvo_tipo     text not null check (alvo_tipo in ('item','lote')),
  alvo_id       uuid not null,
  comprador_id  uuid not null references profiles(id) on delete cascade,
  dias          int  not null check (dias > 0),
  valor_centavos int not null check (valor_centavos >= 0),
  status        text default 'mock' check (status in ('mock','pago','reembolsado','cancelado')),
  payload       jsonb default '{}'::jsonb,
  criado_em     timestamptz default now()
);

create index on destaques_pagamentos (comprador_id, criado_em desc);
create index on destaques_pagamentos (alvo_tipo, alvo_id);
