import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Sistema "glass" reutilizável — frosted translúcido estilo iOS / Tinder.
///
/// Use [GlassSurface] pra qualquer painel (barras, cards, sheets, chips).
/// O segredo do glass de verdade: alpha BAIXO no fundo (deixa o blur aparecer),
/// blur forte, e uma fina borda branca no topo simulando a refração da luz.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = 22,
    this.opacity = 0.62,
    this.padding,
    this.tint,
    this.border = true,
    this.borderColor,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final double blur;

  /// Quão "sólido" é o vidro. 0.5–0.7 deixa o conteúdo de trás vazar (mais glass);
  /// 0.8+ fica mais opaco. Tinder fica ~0.6.
  final double opacity;
  final EdgeInsetsGeometry? padding;

  /// Cor base do vidro. Default = creme da surface.
  final Color? tint;
  final bool border;

  /// Cor da borda. Default = branco 0.55 (refração); em vidro escuro use
  /// algo mais discreto, ex. branco 0.25.
  final Color? borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final base = tint ?? AppColors.surface;
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Gradiente vertical sutil: topo mais claro (luz), base mais densa.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: (opacity + 0.12).clamp(0.0, 1.0)),
                base.withValues(alpha: opacity),
              ],
            ),
            borderRadius: br,
            border: border
                ? Border.all(
                    color: borderColor ??
                        Colors.white.withValues(alpha: 0.55),
                    width: 1,
                  )
                : null,
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.10),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// AppBar de vidro estilo iOS: full-width, translúcida, com blur — o conteúdo
/// rola por trás (use `extendBodyBehindAppBar: true` no Scaffold quando o body
/// for rolável, e compense o padding do topo da lista).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  /// Altura total da barra + status bar — use pra compensar o padding do topo
  /// de listas que rolam por trás dela.
  static double alturaTotal(BuildContext context) =>
      MediaQuery.of(context).padding.top + kToolbarHeight;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // flexibleSpace cobre a barra inteira (inclusive a status bar):
      // é aqui que mora o vidro.
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withValues(alpha: 0.78),
                  AppColors.surface.withValues(alpha: 0.55),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Painel de bottom sheet em vidro fosco estilo iOS. Envolve o conteúdo do
/// sheet (lance com `backgroundColor: Colors.transparent` no
/// `showModalBottomSheet` pro vidro aparecer).
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child, this.topRadius = 28});

  final Widget child;
  final double topRadius;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.vertical(top: Radius.circular(topRadius));
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            // Mais opaco que as barras: sheet carrega conteúdo denso
            // (texto, forms) e precisa de legibilidade.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.80),
                AppColors.surface.withValues(alpha: 0.86),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Alça de arrastar padrão dos sheets.
  static Widget handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      );
}

/// Chip/pílula de vidro pra usar SOBRE fotos (blur de verdade no que está
/// atrás). [dark] = vidro escuro com texto branco (estilo media player).
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.child,
    this.dark = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.radius = 100,
  });

  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? AppColors.ink.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.28 : 0.45),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Pinta um [child] (geralmente um Icon ou Text) com o gradiente da marca.
/// É o truque do ícone "ativo" do Tinder — o ícone vira gradiente, sem pílula.
class GradientMask extends StatelessWidget {
  const GradientMask({
    super.key,
    required this.child,
    this.gradient = AppColors.gradHero,
  });

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: child,
    );
  }
}
