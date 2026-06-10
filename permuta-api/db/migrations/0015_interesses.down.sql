drop table if exists interesses_itens cascade;
drop index if exists idx_lotes_tipo;
alter table lotes drop column if exists tipo;
