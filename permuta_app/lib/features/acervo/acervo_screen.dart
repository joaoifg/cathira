import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass.dart';
import '../itens/meus_itens_screen.dart';
import '../lotes/meus_lotes_screen.dart';

/// Aba unificada: junta "Meus lotes" e "Meus itens" sob um só lugar — o
/// acervo do usuário. Abas internas (segmented) + FAB que muda conforme a aba.
class AcervoScreen extends ConsumerStatefulWidget {
  const AcervoScreen({super.key});

  @override
  ConsumerState<AcervoScreen> createState() => _AcervoScreenState();
}

class _AcervoScreenState extends ConsumerState<AcervoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  bool get _emLotes => _tab.index == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  MeusLotesBody(),
                  MeusItensBody(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _emLotes
            ? abrirNovoLote(context, ref)
            : abrirNovoItem(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(_emLotes ? 'Novo lote' : 'Novo item'),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Acervo',
                  style: AppTheme.display(30,
                      weight: FontWeight.w700, letter: -1.2)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented control "lotes / itens" — pílula glass.
          GlassSurface(
            radius: 18,
            blur: 18,
            opacity: 0.45,
            tint: AppColors.surfaceAlt,
            shadow: false,
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _seg('Lotes', '📦', 0),
                _seg('Itens', '🧰', 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seg(String label, String emoji, int idx) {
    final selected = _tab.index == idx;
    final texto = Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13.5,
        // Branco no selecionado: vira a base do GradientMask.
        color: selected ? Colors.white : AppColors.muted,
      ),
    );
    return Expanded(
      child: GestureDetector(
        onTap: () => _tab.animateTo(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected ? AppShadows.soft : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 7),
              // Label ativa ganha o gradiente da marca (igual à nav bar).
              selected ? GradientMask(child: texto) : texto,
            ],
          ),
        ),
      ),
    );
  }
}
