import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'glass.dart';

/// Bottom sheet pra destacar item ou lote. Mostra 3 planos de duração
/// (30/60/180 dias) com preços fixos. Confirma → chama POST destacar
/// no backend → exibe snack de sucesso. O pagamento é mock por enquanto.
class DestacarSheet extends ConsumerStatefulWidget {
  const DestacarSheet({
    super.key,
    required this.alvoTipo, // 'item' ou 'lote'
    required this.alvoId,
    required this.alvoTitulo,
  });

  final String alvoTipo;
  final String alvoId;
  final String alvoTitulo;

  static Future<void> mostrar(
    BuildContext ctx, {
    required String alvoTipo,
    required String alvoId,
    required String alvoTitulo,
  }) {
    return showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DestacarSheet(
        alvoTipo: alvoTipo,
        alvoId: alvoId,
        alvoTitulo: alvoTitulo,
      ),
    );
  }

  @override
  ConsumerState<DestacarSheet> createState() => _DestacarSheetState();
}

class _DestacarSheetState extends ConsumerState<DestacarSheet> {
  int _dias = 30;
  bool _enviando = false;
  String? _err;

  static const _planos = [
    (30, 990, 'Boost', 'Por 1 mês'),
    (60, 1990, 'Plus', 'Por 2 meses'),
    (180, 3990, 'Estende', 'Por 6 meses'),
  ];

  Future<void> _confirmar() async {
    setState(() {
      _enviando = true;
      _err = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        '/${widget.alvoTipo == "lote" ? "lotes" : "itens"}/${widget.alvoId}/destacar',
        data: {'dias': _dias},
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔥 ${widget.alvoTipo == "lote" ? "Lote" : "Item"} em destaque por $_dias dias!',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => GlassSheet(
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          children: [
            GlassSheet.handle(),
            const SizedBox(height: 18),
            // Hero
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.primary],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.alvoTitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Aparece primeiro pra quem buscar.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Escolhe a duração',
                style: AppTheme.display(22,
                    weight: FontWeight.w700, letter: -0.6)),
            const SizedBox(height: 4),
            const Text(
              'Quanto maior o período, melhor o preço.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ..._planos.map((p) => _planoCard(p.$1, p.$2, p.$3, p.$4)),
            const SizedBox(height: 12),
            const Text(
              '💡 O pagamento é placeholder — em produção será via Stripe ou Pix. Não há cobrança real agora.',
              style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.4,
                  fontStyle: FontStyle.italic),
            ),
            if (_err != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_err!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _enviando ? null : _confirmar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(54),
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Destacar por $_dias dias',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planoCard(int dias, int centavos, String nome, String desc) {
    final sel = _dias == dias;
    final reais = (centavos / 100).toStringAsFixed(2).replaceAll('.', ',');
    return GestureDetector(
      onTap: () => setState(() => _dias = dias),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Não-selecionado é translúcido pra deixar o vidro do sheet respirar.
          color: sel ? AppColors.ink : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: sel ? Colors.transparent : AppColors.ink.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: sel
                      ? AppColors.accent
                      : AppColors.ink.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: sel
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      color: sel
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ $reais',
                  style: AppTheme.mono(18,
                      color: sel ? AppColors.accent : AppColors.ink,
                      weight: FontWeight.w800),
                ),
                Text(
                  '${dias}d',
                  style: AppTheme.mono(10,
                          color: sel
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppColors.muted)
                      .copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
