create table swipes (
  id        uuid primary key default gen_random_uuid(),
  from_id   uuid not null references profiles(id) on delete cascade,
  from_lote uuid not null references lotes(id) on delete cascade,
  to_lote   uuid not null references lotes(id) on delete cascade,
  decisao   text not null check (decisao in ('like','pass')),
  criado_em timestamptz default now(),
  unique (from_id, from_lote, to_lote)
);

create index on swipes (to_lote, decisao);

create table negociacoes (
  id            uuid primary key default gen_random_uuid(),
  lote_a        uuid not null references lotes(id),
  lote_b        uuid not null references lotes(id),
  uid_a         uuid not null references profiles(id),
  uid_b         uuid not null references profiles(id),
  itens_a       uuid[] default '{}',
  itens_b       uuid[] default '{}',
  valor_a       numeric(14,2) default 0,
  valor_b       numeric(14,2) default 0,
  torna         numeric(14,2) default 0,
  quem_paga     uuid,
  aceite_a      boolean default false,
  aceite_b      boolean default false,
  status        text default 'proposta'
                check (status in ('proposta','contraproposta','aceita','recusada','cancelada')),
  ultima_acao   uuid,
  versao        int default 1,
  criado_em     timestamptz default now(),
  atualizado_em timestamptz default now(),
  check (lote_a <> lote_b),
  check (uid_a <> uid_b)
);

create index on negociacoes (uid_a);
create index on negociacoes (uid_b);
create index on negociacoes (status);
