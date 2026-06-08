drop trigger if exists trg_recalc_lote on itens;
drop function if exists recalc_valor_lote();
drop table if exists itens cascade;
drop table if exists lotes cascade;
