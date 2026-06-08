alter table setores
  add column if not exists icone   text default '📦',
  add column if not exists cor     text default '#FF5722',
  add column if not exists tagline text;

update setores set icone = '⚽', cor = '#16A34A', tagline = 'Chuteira, bola, luva e mais'
 where slug = 'esportivo';

insert into setores (slug, nome, faixas, categorias, campos_extras, icone, cor, tagline) values
('automoveis', 'Automóveis',
 '[{"min":0,"max":20000},{"min":20000,"max":50000},{"min":50000,"max":100000},{"min":100000,"max":300000}]'::jsonb,
 '["hatch","sedan","suv","picape","moto"]'::jsonb,
 '{"ano":"int","km":"int","cambio":"enum:manual,automatico","combustivel":"text"}'::jsonb,
 '🚗', '#DC2626', 'Carro, moto, picape — troque pelo lance certo'),
('eletronicos', 'Eletrônicos',
 '[{"min":0,"max":2000},{"min":2000,"max":8000},{"min":8000,"max":30000}]'::jsonb,
 '["smartphone","notebook","console","tv","camera","audio"]'::jsonb,
 '{"marca":"text","modelo":"text","ano":"int","estado":"enum:novo,seminovo,usado"}'::jsonb,
 '💻', '#2563EB', 'Smartphone, console, notebook — high-tech sem dor'),
('instrumentos', 'Instrumentos',
 '[{"min":0,"max":1500},{"min":1500,"max":6000},{"min":6000,"max":20000}]'::jsonb,
 '["guitarra","violao","bateria","piano","sopro","estudio"]'::jsonb,
 '{"marca":"text","cordas":"int","estado":"enum:novo,usado"}'::jsonb,
 '🎸', '#7C3AED', 'Pra galera que toca — equipamento e estúdio'),
('imoveis', 'Imóveis',
 '[{"min":0,"max":150000},{"min":150000,"max":300000},{"min":300000,"max":600000},{"min":600000,"max":2000000}]'::jsonb,
 '["apto","casa","terreno","comercial","rural"]'::jsonb,
 '{"metragem":"int","quartos":"int","vagas":"int","cidade":"text"}'::jsonb,
 '🏠', '#EA580C', 'Apto, casa, terreno — permuta com torna formal');

create table if not exists item_fotos_meta (
  item_id  uuid primary key references itens(id) on delete cascade,
  storage_path text not null
);
