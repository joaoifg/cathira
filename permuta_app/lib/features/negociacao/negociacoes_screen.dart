import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import '../../shared/widgets/glass.dart';
import 'interesses_screen.dart';
import 'mesa_screen.dart';

class NegociacoesScreen extends ConsumerWidget {
  const NegociacoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final negs = ref.watch(minhasNegociacoesProvider);
    final interesses = ref.watch(interessesRecebidosProvider);
    final qtdInteresses = (interesses.value ?? const []).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Negociações'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(minhasNegociacoesProvider);
              ref.invalidate(interessesRecebidosProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: negs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          return RefreshIndicator(
            edgeOffset: GlassAppBar.alturaTotal(context),
            onRefresh: () async {
              ref.invalidate(minhasNegociacoesProvider);
              ref.invalidate(interessesRecebidosProvider);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  20, GlassAppBar.alturaTotal(context) + 12, 20, 32),
              children: [
                _bannerInteresses(context, ref, qtdInteresses),
                const SizedBox(height: 16),
                if (data.isEmpty)
                  _emptyInline(context)
                else
                  ...data.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NegoCard(
                          n: n,
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => MesaScreen(negociacaoId: n.id),
                            ));
                            ref.invalidate(minhasNegociacoesProvider);
                          },
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bannerInteresses(BuildContext ctx, WidgetRef ref, int qtd) {
    return InkWell(
      onTap: () async {
        await Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => const InteressesScreen(),
        ));
        ref.invalidate(interessesRecebidosProvider);
        ref.invalidate(minhasNegociacoesProvider);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: qtd > 0
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accent],
                )
              : null,
          color: qtd > 0 ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: qtd > 0
              ? null
              : Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
          boxShadow: qtd > 0
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: qtd > 0
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  qtd > 0
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: qtd > 0 ? Colors.white : AppColors.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interesses recebidos',
                    style: TextStyle(
                      color: qtd > 0 ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    qtd > 0
                        ? '$qtd ${qtd == 1 ? "pessoa quer" : "pessoas querem"} algo seu'
                        : 'Quando alguém curtir item seu aparece aqui',
                    style: TextStyle(
                      color: qtd > 0
                          ? Colors.white.withValues(alpha: 0.92)
                          : AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (qtd > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$qtd',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: qtd > 0
                    ? Colors.white
                    : AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _emptyInline(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Text('🤝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Nenhuma negociação ativa',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Dá like num item ou lote pra começar.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
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
