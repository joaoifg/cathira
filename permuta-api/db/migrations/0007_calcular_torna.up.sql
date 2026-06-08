create or replace function calcular_torna(p_negociacao uuid)
returns table (valor_a numeric, valor_b numeric, torna numeric, quem_paga uuid)
language plpgsql as $$
declare
  n   negociacoes%rowtype;
  v_a numeric;
  v_b numeric;
begin
  select * into n from negociacoes where id = p_negociacao;
  if not found then
    raise exception 'negociacao % nao encontrada', p_negociacao;
  end if;

  select coalesce(sum(valor_referencia), 0) into v_a
    from itens where id = any(n.itens_a);
  select coalesce(sum(valor_referencia), 0) into v_b
    from itens where id = any(n.itens_b);

  return query
    select
      v_a,
      v_b,
      (v_b - v_a) as torna,
      case
        when v_b > v_a then n.uid_a
        when v_a > v_b then n.uid_b
        else null
      end as quem_paga;
end;
$$;

create or replace function atualizar_mesa(
  p_negociacao uuid,
  p_itens_a    uuid[],
  p_itens_b    uuid[],
  p_actor      uuid
) returns negociacoes
language plpgsql as $$
declare
  n  negociacoes;
  t  record;
begin
  select * into n from negociacoes where id = p_negociacao for update;
  if not found then
    raise exception 'negociacao % nao encontrada', p_negociacao;
  end if;
  if p_actor not in (n.uid_a, n.uid_b) then
    raise exception 'actor % nao participa da negociacao %', p_actor, p_negociacao;
  end if;
  if n.status not in ('proposta','contraproposta') then
    raise exception 'negociacao % nao pode mais ser alterada (status=%)', p_negociacao, n.status;
  end if;

  update negociacoes
     set itens_a       = p_itens_a,
         itens_b       = p_itens_b,
         aceite_a      = false,
         aceite_b      = false,
         versao        = versao + 1,
         ultima_acao   = p_actor,
         atualizado_em = now(),
         status        = 'contraproposta'
   where id = p_negociacao
   returning * into n;

  select * into t from calcular_torna(p_negociacao);

  update negociacoes
     set valor_a   = t.valor_a,
         valor_b   = t.valor_b,
         torna     = t.torna,
         quem_paga = t.quem_paga
   where id = p_negociacao
   returning * into n;

  return n;
end;
$$;

create or replace function aceitar_negociacao(
  p_negociacao uuid,
  p_actor      uuid
) returns negociacoes
language plpgsql as $$
declare
  n negociacoes;
begin
  select * into n from negociacoes where id = p_negociacao for update;
  if not found then
    raise exception 'negociacao % nao encontrada', p_negociacao;
  end if;
  if p_actor = n.uid_a then
    update negociacoes set aceite_a = true, atualizado_em = now() where id = p_negociacao;
  elsif p_actor = n.uid_b then
    update negociacoes set aceite_b = true, atualizado_em = now() where id = p_negociacao;
  else
    raise exception 'actor % nao participa da negociacao', p_actor;
  end if;

  update negociacoes
     set status = case when aceite_a and aceite_b then 'aceita' else status end
   where id = p_negociacao
   returning * into n;

  if n.status = 'aceita' then
    update lotes set status = 'fechado' where id in (n.lote_a, n.lote_b);
    update itens set status = 'trocado'
      where id = any(n.itens_a) or id = any(n.itens_b);
  end if;

  return n;
end;
$$;
