drop trigger if exists trg_recalc_reputacao on avaliacoes;
drop function if exists recalc_reputacao();
drop table if exists avaliacoes cascade;
drop table if exists mensagens cascade;
