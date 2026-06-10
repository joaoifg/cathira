import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import '../../shared/widgets/glass.dart';

class LoteDetalheScreen extends ConsumerWidget {
  const LoteDetalheScreen({super.key, required this.loteId});
  final String loteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalhe = ref.watch(loteDetalheProvider(loteId));
    final setores = ref.watch(setoresProvider);
    final meusItens = ref.watch(meusItensProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: const Text('Lote')),
      body: detalhe.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          final lote = data['lote'] as Lote;
          final itens = (data['itens'] as List).cast<Item>();
          final setMap = {
            for (final s in (setores.value ?? const <Setor>[])) s.slug: s,
          };
          final setor = setMap[lote.setorPrincipal];
          final disponiveis = (meusItens.value ?? const <Item>[])
              .where((it) => it.loteId == null && it.setorSlug == lote.setorPrincipal)
              .toList();

          return RefreshIndicator(
            edgeOffset: GlassAppBar.alturaTotal(context),
            onRefresh: () async {
              ref.invalidate(loteDetalheProvider(loteId));
              ref.invalidate(meusItensProvider);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  20, GlassAppBar.alturaTotal(context) + 20, 20, 80),
              children: [
                _header(lote, setor),
                const SizedBox(height: 20),
                _stats(lote, itens),
                const SizedBox(height: 28),
                _sectionHeader('Itens dentro do lote', itens.length),
                const SizedBox(height: 10),
                if (itens.isEmpty)
                  _emptyBlock('Nenhum item ainda. Adiciona um abaixo 👇')
                else
                  ...itens.map((it) => _ItemDentro(
                        item: it,
                        onRemove: () async {
                          await _moveItem(ref, it.id, null, context);
                        },
                      )),
                const SizedBox(height: 26),
                _sectionHeader('Itens soltos no setor', disponiveis.length),
                const SizedBox(height: 10),
                if (disponiveis.isEmpty)
                  _emptyBlock(
                      'Você não tem itens soltos no setor "${setor?.nome ?? lote.setorPrincipal}".\n'
                      'Cadastra um pela aba "Itens" e adiciona aqui.')
                else
                  ...disponiveis.map((it) => _ItemSolto(
                        item: it,
                        onAdd: () async {
                          await _moveItem(ref, it.id, lote.id, context);
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _moveItem(
      WidgetRef ref, String itemId, String? loteId, BuildContext ctx) async {
    try {
      await ref.read(apiClientProvider).patch(
            '/itens/$itemId',
            data: {'lote_id': loteId},
          );
      ref.invalidate(loteDetalheProvider(this.loteId));
      ref.invalidate(meusItensProvider);
      ref.invalidate(meusLotesProvider);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Falhou: $e')),
        );
      }
    }
  }

  Widget _header(Lote lote, Setor? setor) {
    final grad = setor != null
        ? AppColors.gradientFromHex(setor.cor)
        : AppColors.gradHero;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(setor?.icone ?? '📦', style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lote.titulo,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  setor?.nome ?? lote.setorPrincipal,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats(Lote lote, List<Item> itens) {
    return Row(
      children: [
        Expanded(child: _stat('Total do lote', brl(lote.valorTotal), AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _stat('Nº de itens', itens.length.toString(), AppColors.ink)),
        const SizedBox(width: 10),
        Expanded(
            child: _stat(
                'Faixa alvo',
                lote.faixaAlvoMin != null
                    ? '${brl(lote.faixaAlvoMin)}+'
                    : '—',
                AppColors.success)),
      ],
    );
  }

  Widget _stat(String label, String value, Color cor) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15, color: cor)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _sectionHeader(String label, int count) => Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      );

  Widget _emptyBlock(String msg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(msg,
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      );
}

class _ItemDentro extends StatelessWidget {
  const _ItemDentro({required this.item, required this.onRemove});
  final Item item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        children: [
          _thumb(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(item.categoria,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(brl(item.valorReferencia),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        fontSize: 14)),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Tirar do lote',
            onPressed: onRemove,
            icon: const Icon(Icons.remove_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
          ),
        ],
      ),
    );
  }
}

class _ItemSolto extends StatelessWidget {
  const _ItemSolto({required this.item, required this.onAdd});
  final Item item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _thumb(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(item.categoria,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(brl(item.valorReferencia),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Adicionar ao lote',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

Widget _thumb(Item item) {
  if (item.fotos.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        item.fotos.first,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackThumb(),
      ),
    );
  }
  return _fallbackThumb();
}

Widget _fallbackThumb() => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_rounded, color: AppColors.muted),
    );
