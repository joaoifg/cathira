import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/setores/home_screen.dart';
import '../../features/descoberta/descoberta_screen.dart';
import '../../features/lotes/meus_lotes_screen.dart';
import '../../features/itens/meus_itens_screen.dart';
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
      MeusLotesScreen(),
      MeusItensScreen(),
      NegociacoesScreen(),
      PerfilScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: _CustomNav(
        index: index,
        pendentes: pendentes,
        onTap: (i) => ref.read(currentTabProvider.notifier).state = i,
      ),
    );
  }
}

class _CustomNav extends StatelessWidget {
  const _CustomNav({
    required this.index,
    required this.pendentes,
    required this.onTap,
  });

  final int index;
  final int pendentes;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(Icons.local_fire_department_outlined,
          Icons.local_fire_department_rounded, 'Descobrir'),
      _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Lotes'),
      _NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Itens'),
      _NavItem(Icons.handshake_outlined, Icons.handshake_rounded, 'Negócios'),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (i) {
            final it = items[i];
            final selected = i == index;
            final badge = i == 4 && pendentes > 0 ? pendentes : 0;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.gradHero : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              selected ? it.activeIcon : it.icon,
                              key: ValueKey(selected),
                              color: selected ? Colors.white : AppColors.muted,
                              size: 22,
                            ),
                          ),
                          if (badge > 0)
                            Positioned(
                              right: -8,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                      color: AppColors.surface, width: 2),
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
                      if (selected) ...[
                        const SizedBox(height: 2),
                        Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
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
