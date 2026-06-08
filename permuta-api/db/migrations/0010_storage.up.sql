-- Bucket "itens" para fotos. Público em leitura (qualquer um pode ver foto
-- de um item à venda), upload restrito ao dono autenticado.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('itens', 'itens', true, 5242880,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public             = excluded.public,
  file_size_limit    = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Policies em storage.objects para esse bucket.
-- Convenção de path: <user_uuid>/<item_uuid>/<filename>
-- O primeiro segmento do path determina o dono.

drop policy if exists "itens leitura publica"    on storage.objects;
drop policy if exists "itens upload do dono"     on storage.objects;
drop policy if exists "itens update do dono"     on storage.objects;
drop policy if exists "itens delete do dono"     on storage.objects;

create policy "itens leitura publica" on storage.objects
  for select using (bucket_id = 'itens');

create policy "itens upload do dono" on storage.objects
  for insert with check (
    bucket_id = 'itens'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "itens update do dono" on storage.objects
  for update using (
    bucket_id = 'itens'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "itens delete do dono" on storage.objects
  for delete using (
    bucket_id = 'itens'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
