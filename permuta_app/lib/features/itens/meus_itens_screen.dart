import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import 'novo_item_screen.dart';

class MeusItensScreen extends ConsumerWidget {
  const MeusItensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itens = ref.watch(meusItensProvider);
    final setores = ref.watch(setoresProvider);
    final lotes = ref.watch(meusLotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus itens'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(meusItensProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NovoItemScreen()),
          );
          if (created == true) ref.invalidate(meusItensProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo item'),
      ),
      body: itens.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data.isEmpty) return _empty(context);
          final setMap = {
            for (final s in (setores.value ?? const <Setor>[])) s.slug: s,
          };
          final loteMap = {
            for (final l in (lotes.value ?? const <Lote>[])) l.id: l,
          };
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
          );
        },
      ),
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, this.setor, this.lote});
  final Item item;
  final Setor? setor;
  final Lote? lote;

  @override
  Widget build(BuildContext context) {
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
          Text(
            brl(item.valorReferencia),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.success,
              fontSize: 15,
            ),
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
