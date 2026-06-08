create table mensagens (
  id            uuid primary key default gen_random_uuid(),
  negociacao_id uuid not null references negociacoes(id) on delete cascade,
  sender_id     uuid not null references profiles(id),
  texto         text,
  tipo          text default 'texto' check (tipo in ('texto','proposta_atualizada','sistema')),
  lido          boolean default false,
  criado_em     timestamptz default now()
);

create index on mensagens (negociacao_id, criado_em);

create table avaliacoes (
  id            uuid primary key default gen_random_uuid(),
  de_id         uuid not null references profiles(id),
  para_id       uuid not null references profiles(id),
  negociacao_id uuid not null references negociacoes(id),
  nota          int not null check (nota between 1 and 5),
  comentario    text,
  criado_em     timestamptz default now(),
  unique (de_id, negociacao_id)
);

create index on avaliacoes (para_id);

create or replace function recalc_reputacao() returns trigger as $$
declare
  alvo uuid := coalesce(new.para_id, old.para_id);
begin
  update profiles set reputacao = (
    select coalesce(round(avg(nota)::numeric, 1), 0) from avaliacoes where para_id = alvo
  ) where id = alvo;
  return null;
end; $$ language plpgsql;

create trigger trg_recalc_reputacao
after insert or update or delete on avaliacoes
for each row execute function recalc_reputacao();
