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
                    color: Colors.white.withValues(alpha: 0.55),
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
