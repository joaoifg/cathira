insert into setores (slug, nome, faixas, categorias, campos_extras, icone, cor, tagline) values
('livros', 'Livros e Cultura',
 '[{"min":0,"max":200},{"min":200,"max":800},{"min":800,"max":3000}]'::jsonb,
 '["literatura","hq","manga","tecnico","colecao","ebook"]'::jsonb,
 '{"autor":"text","editora":"text","ano":"int","estado":"enum:novo,seminovo,usado"}'::jsonb,
 '📚', '#0EA5E9', 'HQ, manga, coleções, livros raros'),
('outdoor', 'Outdoor',
 '[{"min":0,"max":500},{"min":500,"max":2000},{"min":2000,"max":8000}]'::jsonb,
 '["camping","escalada","trilha","pesca","barraca","mochila"]'::jsonb,
 '{"tamanho":"text","marca":"text","estado":"enum:novo,seminovo,usado"}'::jsonb,
 '🏕️', '#10B981', 'Camping, trilha, escalada — natureza forte');
