import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import '../../shared/widgets/destacar_sheet.dart';
import 'novo_item_screen.dart';

/// Abre a tela de novo item e invalida a lista no retorno. Reusado pela aba
/// Acervo (que provê o FAB contextual).
Future<void> abrirNovoItem(BuildContext context, WidgetRef ref) async {
  final created = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const NovoItemScreen()),
  );
  if (created == true) ref.invalidate(meusItensProvider);
}

/// Corpo do inventário de itens, sem Scaffold — pra ser embutido na aba Acervo.
class MeusItensBody extends ConsumerWidget {
  const MeusItensBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itens = ref.watch(meusItensProvider);
    final setores = ref.watch(setoresProvider);
    final lotes = ref.watch(meusLotesProvider);

    return itens.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          final setMap = {
            for (final s in (setores.value ?? const <Setor>[])) s.slug: s,
          };
          final loteMap = {
            for (final l in (lotes.value ?? const <Lote>[])) l.id: l,
          };
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _InventarioDashboard(itens: data, setMap: setMap),
              ),
              if (data.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final it = data[i];
                      return _ItemCard(
                        item: it,
                        setor: setMap[it.setorSlug],
                        lote: it.loteId != null ? loteMap[it.loteId] : null,
                      );
                    },
                  ),
                ),
            ],
          );
        },
    );
  }

  Widget _empty(BuildContext ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🧰', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 14),
              Text('Nenhum item cadastrado',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Cria itens individuais (uma chuteira, um console)\n'
                'e depois agrupa em lotes na outra aba.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item, this.setor, this.lote});
  final Item item;
  final Setor? setor;
  final Lote? lote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cor = setor != null ? AppColors.colorFromHex(setor!.cor) : AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                if (item.descricao != null && item.descricao!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.descricao!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12.5, height: 1.3),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (setor != null)
                      _chip('${setor!.icone} ${setor!.nome}', cor),
                    _chip(item.categoria, AppColors.ink),
                    if (lote != null)
                      _chip('📦 ${lote!.titulo}', AppColors.success)
                    else
                      _chip('Solto', AppColors.muted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                brl(item.valorReferencia),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => DestacarSheet.mostrar(
                  context,
                  alvoTipo: 'item',
                  alvoId: item.id,
                  alvoTitulo: item.titulo,
                ).then((_) => ref.invalidate(meusItensProvider)),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'destacar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumb() {
    if (item.fotos.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.fotos.first,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: setor != null
              ? AppColors.gradientFromHex(setor!.cor)
              : AppColors.gradHero,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(setor?.icone ?? '📦',
              style: const TextStyle(fontSize: 28)),
        ),
      );

  Widget _chip(String label, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      );
}

/// Dashboard do próprio inventário: stats, distribuição por setor,
/// CTA pra destacar. Cabeça da tela "Meus itens".
class _InventarioDashboard extends StatelessWidget {
  const _InventarioDashboard({required this.itens, required this.setMap});

  final List<Item> itens;
  final Map<String, Setor> setMap;

  @override
  Widget build(BuildContext context) {
    final total = itens.length;
    final valorTotal =
        itens.fold<double>(0, (a, i) => a + i.valorReferencia);
    final emLote = itens.where((i) => i.loteId != null).length;
    final soltos = total - emLote;
    final pctLote = total == 0 ? 0.0 : (emLote / total);

    // distribuição por setor
    final porSetor = <String, _SetorAgg>{};
    for (final it in itens) {
      final a = porSetor.putIfAbsent(
          it.setorSlug, () => _SetorAgg(setMap[it.setorSlug]));
      a.count += 1;
      a.valor += it.valorReferencia;
    }
    final lista = porSetor.values.toList()
      ..sort((a, b) => b.valor.compareTo(a.valor));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero do inventário
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: AppColors.gradInk,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MEU INVENTÁRIO',
                      style: AppTheme.mono(10,
                              color: AppColors.accent,
                              weight: FontWeight.w800)
                          .copyWith(letterSpacing: 1.6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  brl(valorTotal),
                  style: AppTheme.mono(36,
                      color: Colors.white, weight: FontWeight.w700),
                ),
                Text(
                  '$total ${total == 1 ? "item" : "itens"} disponíveis pra trocar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _heroChip('📦 em lotes', '$emLote'),
                    const SizedBox(width: 8),
                    _heroChip('🪶 soltos', '$soltos'),
                    const SizedBox(width: 8),
                    _heroChip(
                      '${(pctLote * 100).toStringAsFixed(0)}% agrupado',
                      null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (lista.isNotEmpty) ...[
            Row(
              children: [
                Text('Distribuição por setor',
                    style: AppTheme.display(20,
                        weight: FontWeight.w700, letter: -0.6)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('${lista.length}',
                      style: AppTheme.mono(11, weight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...lista.map((a) => _barraSetor(a, valorTotal)),
            const SizedBox(height: 16),
          ],
          // Faixa explicando que destaque é monetização
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFEF3E7), Color(0xFFFEE8D2)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.accentDeep, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Destaque seu item',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                      Text(
                        'A partir de R\$ 9,90 — aparece primeiro no feed dos outros usuários.',
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                            height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (itens.isNotEmpty)
            Row(
              children: [
                Text('Itens',
                    style: AppTheme.display(20,
                        weight: FontWeight.w700, letter: -0.6)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('$total',
                      style: AppTheme.mono(11, weight: FontWeight.w800)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _heroChip(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _barraSetor(_SetorAgg a, double total) {
    final cor = a.setor != null
        ? AppColors.colorFromHex(a.setor!.cor)
        : AppColors.muted;
    final pct = total == 0 ? 0.0 : (a.valor / total);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(a.setor?.icone ?? '📦',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                a.setor?.nome ?? '—',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text('${a.count}',
                  style: AppTheme.mono(11, color: AppColors.muted)
                      .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(brl(a.valor),
                  style: AppTheme.mono(13,
                      color: cor, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: cor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(cor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetorAgg {
  _SetorAgg(this.setor);
  final Setor? setor;
  int count = 0;
  double valor = 0;
}
