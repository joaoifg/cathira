create table lotes (
  id              uuid primary key default gen_random_uuid(),
  dono_id         uuid not null references profiles(id) on delete cascade,
  titulo          text not null,
  setor_principal text not null references setores(slug),
  valor_total     numeric(14,2) default 0,
  faixa_alvo_min  numeric(14,2),
  faixa_alvo_max  numeric(14,2),
  aceita_torna    boolean default true,
  aceita_parcial  boolean default true,
  cidade          text,
  geo             geography(point, 4326),
  status          text default 'aberto' check (status in ('aberto','negociando','fechado')),
  criado_em       timestamptz default now()
);

create index on lotes (setor_principal);
create index on lotes (dono_id);
create index on lotes (status);
create index on lotes using gist (geo);

create table itens (
  id               uuid primary key default gen_random_uuid(),
  dono_id          uuid not null references profiles(id) on delete cascade,
  titulo           text not null,
  descricao        text,
  fotos            text[] default '{}',
  setor_slug       text not null references setores(slug),
  categoria        text not null,
  valor_referencia numeric(14,2) not null check (valor_referencia >= 0),
  campos           jsonb default '{}'::jsonb,
  destacavel       boolean default true,
  lote_id          uuid references lotes(id) on delete set null,
  status           text default 'disponivel' check (status in ('disponivel','em_negociacao','trocado')),
  criado_em        timestamptz default now()
);

create index on itens (setor_slug, categoria);
create index on itens (lote_id);
create index on itens (dono_id);

create or replace function recalc_valor_lote() returns trigger as $$
declare
  alvo uuid;
begin
  if (tg_op = 'DELETE') then
    alvo := old.lote_id;
  elsif (tg_op = 'UPDATE') then
    if new.lote_id is distinct from old.lote_id then
      update lotes set valor_total = (
        select coalesce(sum(valor_referencia),0) from itens where lote_id = old.lote_id
      ) where id = old.lote_id;
    end if;
    alvo := new.lote_id;
  else
    alvo := new.lote_id;
  end if;

  if alvo is not null then
    update lotes set valor_total = (
      select coalesce(sum(valor_referencia),0) from itens where lote_id = alvo
    ) where id = alvo;
  end if;
  return null;
end; $$ language plpgsql;

create trigger trg_recalc_lote
after insert or update or delete on itens
for each row execute function recalc_valor_lote();
