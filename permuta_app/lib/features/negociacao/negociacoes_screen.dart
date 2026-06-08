import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import 'mesa_screen.dart';

class NegociacoesScreen extends ConsumerWidget {
  const NegociacoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final negs = ref.watch(minhasNegociacoesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Negociações'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(minhasNegociacoesProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: negs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data.isEmpty) return _empty(context);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(minhasNegociacoesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _NegoCard(
                n: data[i],
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MesaScreen(negociacaoId: data[i].id),
                  ));
                  ref.invalidate(minhasNegociacoesProvider);
                },
              ),
            ),
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
              const Text('🤝', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Nenhuma negociação ativa.',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Vai na aba "Descobrir" e dá like em um lote.\n'
                'Quando rolar match recíproco, abre aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

class _NegoCard extends StatelessWidget {
  const _NegoCard({required this.n, required this.onTap});
  final Negociacao n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final torna = n.torna;
    final tornaStr = torna == 0
        ? 'Troca par'
        : '${torna > 0 ? '+' : '-'}${brl(torna.abs())}';
    final tornaColor = torna == 0
        ? AppColors.muted
        : torna > 0
            ? AppColors.success
            : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.gradHero,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🤝', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Negociação #${n.id.substring(0, 8)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip(n.statusTexto, _statusColor(n.statusTexto)),
                      if (n.aceiteA && n.aceiteB)
                        _chip('✓ aceito por ambos', AppColors.success)
                      else if (n.aceiteA || n.aceiteB)
                        _chip('aceito por 1', AppColors.accentDeep),
                      _chip('v${n.versao}', AppColors.muted),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('A: ${brl(n.valorA)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      const Text('  ·  ', style: TextStyle(color: AppColors.muted)),
                      Text('B: ${brl(n.valorB)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(tornaStr,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: tornaColor,
                        fontSize: 14)),
                const SizedBox(height: 2),
                const Text('torna',
                    style: TextStyle(color: AppColors.muted, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'aceita':
        return AppColors.success;
      case 'recusada':
      case 'cancelada':
        return AppColors.muted;
      case 'contraproposta':
        return AppColors.accentDeep;
      default:
        return AppColors.primary;
    }
  }

  Widget _chip(String label, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: TextStyle(
                color: cor, fontWeight: FontWeight.w700, fontSize: 11)),
      );
}
