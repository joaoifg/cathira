drop table if exists item_fotos_meta;
delete from setores where slug in ('automoveis','eletronicos','instrumentos','imoveis');
alter table setores drop column if exists tagline;
alter table setores drop column if exists cor;
alter table setores drop column if exists icone;
