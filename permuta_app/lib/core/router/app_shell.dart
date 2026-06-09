import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/setores/home_screen.dart';
import '../../features/descoberta/descoberta_screen.dart';
import '../../features/acervo/acervo_screen.dart';
import '../../features/negociacao/negociacoes_screen.dart';
import '../../features/perfil/perfil_screen.dart';
import '../../shared/providers/data_providers.dart';
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

/// Barra flutuante "glass": translúcida com blur, cantos arredondados,
/// flutua acima do conteúdo. A aba ativa vira uma pílula com gradiente + label.
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(items.length, (i) {
                  final it = items[i];
                  final selected = i == index;
                  final badge =
                      i == _negociosIdx && pendentes > 0 ? pendentes : 0;
                  return _GlassNavButton(
                    item: it,
                    selected: selected,
                    badge: badge,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
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
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 14 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradHero : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      key: ValueKey(selected),
                      color: selected ? Colors.white : AppColors.muted,
                      size: 23,
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(100),
                          border:
                              Border.all(color: AppColors.surface, width: 2),
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        child: Text(
                          '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Label só na aba ativa, com transição suave de largura.
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
