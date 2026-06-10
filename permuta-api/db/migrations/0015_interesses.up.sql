-- Interesse em item: quando alguém dá like num item da Descoberta por item,
-- cria um interesse pendente que o dono pode aceitar (abre Mesa exploradora)
-- ou recusar. É o passo intermediário entre o swipe e a negociação aberta.

-- Classifica lotes: 'normal' (criados pelo usuário) vs 'solo' (criado
-- automaticamente pra negociar 1 item solto) vs 'inventario_auto' (criado
-- automaticamente agrupando todos os itens disponíveis do user pra abrir mesa).
-- Lotes auto não aparecem na lista pública de lotes.
alter table lotes
  add column if not exists tipo text default 'normal'
    check (tipo in ('normal','solo','inventario_auto'));

create index if not exists idx_lotes_tipo on lotes (tipo);

create table interesses_itens (
  id            uuid primary key default gen_random_uuid(),
  de_id         uuid not null references profiles(id) on delete cascade,
  para_id       uuid not null references profiles(id) on delete cascade,
  item_id       uuid not null references itens(id)    on delete cascade,
  status        text default 'pendente'
                check (status in ('pendente','aceito','recusado','cancelado')),
  negociacao_id uuid references negociacoes(id) on delete set null,
  mensagem      text,
  criado_em     timestamptz default now(),
  resolvido_em  timestamptz,
  unique (de_id, item_id)
);

create index on interesses_itens (para_id, status, criado_em desc);
create index on interesses_itens (de_id, criado_em desc);
