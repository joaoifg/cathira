create table setores (
  slug          text primary key,
  nome          text not null,
  faixas        jsonb not null,
  categorias    jsonb not null,
  campos_extras jsonb not null,
  ativo         boolean default true,
  criado_em     timestamptz default now()
);

insert into setores (slug, nome, faixas, categorias, campos_extras) values
('esportivo', 'Esportivo',
 '[{"min":0,"max":50},{"min":50,"max":150},{"min":150,"max":400}]'::jsonb,
 '["chuteira","bola","uniforme","luva"]'::jsonb,
 '{"tamanho":"text","marca":"text","estado":"enum:novo,usado"}'::jsonb);
