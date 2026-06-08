-- Habilita Realtime nas tabelas que o Flutter assina (mesa + chat).
-- REPLICA IDENTITY FULL faz o payload do realtime incluir o registro inteiro,
-- não só a PK — necessário pra atualizar a UI sem dar refetch a cada mudança.

alter table negociacoes replica identity full;
alter table mensagens   replica identity full;

-- A publication "supabase_realtime" já existe por padrão em projetos Supabase.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      execute 'alter publication supabase_realtime add table negociacoes';
    exception when duplicate_object then null;
    end;
    begin
      execute 'alter publication supabase_realtime add table mensagens';
    exception when duplicate_object then null;
    end;
  end if;
end $$;
