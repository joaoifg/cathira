drop table if exists destaques_pagamentos cascade;
drop index if exists idx_itens_destaque;
drop index if exists idx_lotes_destaque;
alter table lotes drop column if exists destaque_ate;
alter table itens drop column if exists destaque_ate;
