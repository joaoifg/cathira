import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/setores/home_screen.dart';
import '../../features/descoberta/descoberta_screen.dart';
import '../../features/acervo/acervo_screen.dart';
import '../../features/negociacao/negociacoes_screen.dart';
import '../../features/perfil/perfil_screen.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/glass.dart';
import 'nav_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(currentTabProvider);
    final negociacoes = ref.watch(minhasNegociacoesProvider);
    final pendentes = (negociacoes.value ?? const [])
        .where((n) =>
            n.statusTexto == 'proposta' || n.statusTexto == 'contraproposta')
        .length;

    const pages = [
      HomeScreen(),
      DescobertaScreen(),
      AcervoScreen(),
      NegociacoesScreen(),
      PerfilScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: _GlassNav(
        index: index,
        pendentes: pendentes,
        onTap: (i) => ref.read(currentTabProvider.notifier).state = i,
      ),
    );
  }
}

/// Barra flutuante "totalmente glass" estilo Tinder/iOS: vidro translúcido puro
/// (deixa o conteúdo vazar por trás), sem pílula sólida. A aba ativa é o próprio
/// ícone pintado com o gradiente da marca + um ponto-indicador abaixo.
class _GlassNav extends StatelessWidget {
  const _GlassNav({
    required this.index,
    required this.pendentes,
    required this.onTap,
  });

  final int index;
  final int pendentes;
  final ValueChanged<int> onTap;

  // Índice da aba "Negócios" — onde mora o badge de pendências.
  static const _negociosIdx = 3;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(Icons.local_fire_department_outlined,
          Icons.local_fire_department_rounded, 'Descobrir'),
      _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Acervo'),
      _NavItem(Icons.handshake_outlined, Icons.handshake_rounded, 'Negócios'),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: GlassSurface(
          radius: 30,
          blur: 24,
          opacity: 0.58,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (i) {
              final badge = i == _negociosIdx && pendentes > 0 ? pendentes : 0;
              return _GlassNavButton(
                item: items[i],
                selected: i == index,
                badge: badge,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  const _GlassNavButton({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        selected ? item.activeIcon : item.icon,
        key: ValueKey(selected),
        color: selected ? Colors.white : AppColors.muted,
        size: 25,
      ),
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ícone ativo vira gradiente (truque do Tinder); inativo fica muted.
                  selected ? GradientMask(child: icon) : icon,
                  if (badge > 0)
                    Positioned(
                      right: -9,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(100),
                          border:
                              Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 17, minHeight: 17),
                        child: Text(
                          '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              // Label sempre presente, discreta — ativa ganha gradiente.
              selected
                  ? GradientMask(
                      child: Text(item.label, style: _labelStyle(true)),
                    )
                  : Text(item.label, style: _labelStyle(false)),
              const SizedBox(height: 4),
              // Ponto-indicador: gradiente quando ativo, transparente quando não.
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: selected ? 5 : 0,
                height: 5,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradHero,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(bool selected) => TextStyle(
        color: selected ? Colors.white : AppColors.muted,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 10.5,
        letterSpacing: 0.1,
      );
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
