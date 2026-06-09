import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import 'novo_lote_screen.dart';
import 'lote_detalhe_screen.dart';

/// Abre a tela de novo lote e invalida a lista no retorno. Reusado pela aba
/// Acervo (que provê o FAB contextual).
Future<void> abrirNovoLote(BuildContext context, WidgetRef ref) async {
  final created = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const NovoLoteScreen()),
  );
  if (created == true) ref.invalidate(meusLotesProvider);
}

/// Corpo da listagem de lotes, sem Scaffold — pra ser embutido na aba Acervo.
class MeusLotesBody extends ConsumerWidget {
  const MeusLotesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotes = ref.watch(meusLotesProvider);
    final setores = ref.watch(setoresProvider);

    return lotes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data.isEmpty) return _empty(context);
          final setMap = {
            for (final s in (setores.value ?? const <Setor>[])) s.slug: s,
          };
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _LoteCard(
              lote: data[i],
              setor: setMap[data[i].setorPrincipal],
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => LoteDetalheScreen(loteId: data[i].id)),
                );
                ref.invalidate(meusLotesProvider);
              },
            ),
          );
        },
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Nenhum lote ainda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cria seu primeiro lote pra começar a permutar.\n'
              'Pode juntar quantos itens quiser dentro dele.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoteCard extends StatelessWidget {
  const _LoteCard({required this.lote, this.setor, required this.onTap});
  final Lote lote;
  final Setor? setor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = setor != null
        ? AppColors.colorFromHex(setor!.cor)
        : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: setor != null
                    ? AppColors.gradientFromHex(setor!.cor)
                    : AppColors.gradHero,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(setor?.icone ?? '📦',
                    style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lote.titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip(setor?.nome ?? lote.setorPrincipal, cor),
                      _statusChip(lote.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total ${brl(lote.valorTotal)}'
                    '${lote.faixaAlvoMin != null ? ' · quer ${brl(lote.faixaAlvoMin)}-${brl(lote.faixaAlvoMax)}' : ''}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: cor, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      );

  Widget _statusChip(String status) {
    final cores = {
      'aberto': AppColors.success,
      'negociando': AppColors.accentDeep,
      'fechado': AppColors.muted,
    };
    final cor = cores[status] ?? AppColors.muted;
    return _chip(status, cor);
  }
}
