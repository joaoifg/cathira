-- profiles
alter table profiles enable row level security;

create policy "profiles publicos para leitura" on profiles
  for select using (true);

create policy "dono edita proprio perfil" on profiles
  for update using (auth.uid() = id);

create policy "dono cria proprio perfil" on profiles
  for insert with check (auth.uid() = id);

-- setores: leitura aberta, escrita só via service role
alter table setores enable row level security;

create policy "setores publicos" on setores
  for select using (true);

-- lotes
alter table lotes enable row level security;

create policy "lotes visiveis a todos" on lotes
  for select using (true);

create policy "dono cria lote" on lotes
  for insert with check (auth.uid() = dono_id);

create policy "dono edita seu lote" on lotes
  for update using (auth.uid() = dono_id);

create policy "dono apaga seu lote" on lotes
  for delete using (auth.uid() = dono_id);

-- itens
alter table itens enable row level security;

create policy "itens visiveis a todos" on itens
  for select using (true);

create policy "dono cria item" on itens
  for insert with check (auth.uid() = dono_id);

create policy "dono edita item" on itens
  for update using (auth.uid() = dono_id);

create policy "dono apaga item" on itens
  for delete using (auth.uid() = dono_id);

-- swipes: só o autor enxerga
alter table swipes enable row level security;

create policy "autor ve proprios swipes" on swipes
  for select using (auth.uid() = from_id);

create policy "autor cria swipe" on swipes
  for insert with check (auth.uid() = from_id);

-- negociacoes: só os dois participantes
alter table negociacoes enable row level security;

create policy "participantes veem negociacao" on negociacoes
  for select using (auth.uid() in (uid_a, uid_b));

-- escrita em negociacoes só via service role (Go API), nunca direto pelo cliente

-- mensagens: participantes da negociacao
alter table mensagens enable row level security;

create policy "participantes veem mensagens" on mensagens
  for select using (
    exists (
      select 1 from negociacoes n
      where n.id = mensagens.negociacao_id
        and auth.uid() in (n.uid_a, n.uid_b)
    )
  );

create policy "participantes enviam mensagens" on mensagens
  for insert with check (
    auth.uid() = sender_id and exists (
      select 1 from negociacoes n
      where n.id = mensagens.negociacao_id
        and auth.uid() in (n.uid_a, n.uid_b)
    )
  );

-- avaliacoes
alter table avaliacoes enable row level security;

create policy "avaliacoes publicas para leitura" on avaliacoes
  for select using (true);

create policy "autor cria avaliacao apos troca aceita" on avaliacoes
  for insert with check (
    auth.uid() = de_id and exists (
      select 1 from negociacoes n
      where n.id = avaliacoes.negociacao_id
        and n.status = 'aceita'
        and auth.uid() in (n.uid_a, n.uid_b)
    )
  );
