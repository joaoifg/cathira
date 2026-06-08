drop policy if exists "itens delete do dono"     on storage.objects;
drop policy if exists "itens update do dono"     on storage.objects;
drop policy if exists "itens upload do dono"     on storage.objects;
drop policy if exists "itens leitura publica"    on storage.objects;

delete from storage.buckets where id = 'itens';
