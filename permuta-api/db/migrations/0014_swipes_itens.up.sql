-- Descoberta por item: swipe sobre item individual em vez de lote inteiro.
-- Modelo item-first complementa o modelo lote-first existente.

create table swipes_itens (
  id        uuid primary key default gen_random_uuid(),
  from_id   uuid not null references profiles(id) on delete cascade,
  to_item   uuid not null references itens(id) on delete cascade,
  decisao   text not null check (decisao in ('like','pass')),
  criado_em timestamptz default now(),
  unique (from_id, to_item)
);

create index on swipes_itens (to_item, decisao);
create index on swipes_itens (from_id, criado_em desc);
