do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      execute 'alter publication supabase_realtime drop table mensagens';
    exception when undefined_object then null;
    end;
    begin
      execute 'alter publication supabase_realtime drop table negociacoes';
    exception when undefined_object then null;
    end;
  end if;
end $$;

alter table mensagens   replica identity default;
alter table negociacoes replica identity default;
