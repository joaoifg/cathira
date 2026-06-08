import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Glyph "cathira" — duas setas em arco formando uma roda interrompida.
/// Lê visualmente como "troca" (setas opostas) e "roda" (círculo de cathira).
///
/// Mantém leitura forte em qualquer tamanho. Pode receber [color] sólida
/// ou [gradient] no traço.
class CathiraGlyph extends StatelessWidget {
  const CathiraGlyph({
    super.key,
    this.size = 28,
    this.color,
    this.gradient,
    this.background,
    this.padding = 0.18,
    this.strokeRatio = 0.18,
  });

  /// Tamanho total do glyph (lado do quadrado).
  final double size;

  /// Cor sólida do traço. Ignorada quando [gradient] é definido.
  final Color? color;

  /// Gradiente aplicado ao traço (sobrepõe [color]).
  final Gradient? gradient;

  /// Cor opcional de fundo (se nulo, transparente).
  final Color? background;

  /// Margem interna proporcional ao tamanho (0..0.4).
  final double padding;

  /// Grossura do traço como fração do tamanho.
  final double strokeRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: _GlyphPainter(
          color: color ?? AppColors.ink,
          gradient: gradient,
          padding: padding,
          strokeRatio: strokeRatio,
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.color,
    required this.gradient,
    required this.padding,
    required this.strokeRatio,
  });

  final Color color;
  final Gradient? gradient;
  final double padding;
  final double strokeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final pad = s * padding;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (s / 2) - pad;
    final stroke = s * strokeRatio;

    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint mkPaint() {
      final p = Paint()
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (gradient != null) {
        p.shader = gradient!.createShader(rect);
      } else {
        p.color = color;
      }
      return p;
    }

    // Arco superior — vai de 200° a 350° (sentido horário).
    final paint = mkPaint();
    canvas.drawArc(
      rect,
      _rad(200),
      _rad(150),
      false,
      paint,
    );

    // Arco inferior — espelho, de 20° a 170°.
    canvas.drawArc(
      rect,
      _rad(20),
      _rad(150),
      false,
      paint,
    );

    // Cabeça da seta superior (no fim do arco em ~350°).
    _drawArrowHead(
      canvas,
      paint,
      center: center,
      radius: radius,
      angleDeg: 350,
      // tangente apontando "saindo" do arco
      directionDeg: 350 + 90,
      stroke: stroke,
    );

    // Cabeça da seta inferior (no fim do arco em ~170°).
    _drawArrowHead(
      canvas,
      paint,
      center: center,
      radius: radius,
      angleDeg: 170,
      directionDeg: 170 + 90,
      stroke: stroke,
    );
  }

  void _drawArrowHead(
    Canvas canvas,
    Paint paint, {
    required Offset center,
    required double radius,
    required double angleDeg,
    required double directionDeg,
    required double stroke,
  }) {
    // Ponta da seta (extremidade do arco).
    final tip = Offset(
      center.dx + radius * math.cos(_rad(angleDeg)),
      center.dy + radius * math.sin(_rad(angleDeg)),
    );

    // Tamanho da seta proporcional ao stroke.
    final arrow = stroke * 1.9;

    // Linha base perpendicular: pega 2 pontos atrás da ponta em ângulos
    // ±35° da direção da tangente.
    final back1 = Offset(
      tip.dx - arrow * math.cos(_rad(directionDeg - 35)),
      tip.dy - arrow * math.sin(_rad(directionDeg - 35)),
    );
    final back2 = Offset(
      tip.dx - arrow * math.cos(_rad(directionDeg + 35)),
      tip.dy - arrow * math.sin(_rad(directionDeg + 35)),
    );

    final path = Path()
      ..moveTo(back1.dx, back1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(back2.dx, back2.dy);

    canvas.drawPath(path, paint);
  }

  double _rad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.color != color ||
      old.gradient != gradient ||
      old.padding != padding ||
      old.strokeRatio != strokeRatio;
}

/// Selo circular "carimbo" — versão estampada do logo pra usar como
/// decoração em cantos / empty states. Tem texto curvo "CATHIRA · DANÇA
/// DE RODA ·" rodando ao redor de um glyph central.
class CathiraStamp extends StatelessWidget {
  const CathiraStamp({super.key, this.size = 140, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cor = color ?? AppColors.ink;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _StampRingPainter(color: cor),
          ),
          CathiraGlyph(
            size: size * 0.42,
            color: cor,
          ),
        ],
      ),
    );
  }
}

class _StampRingPainter extends CustomPainter {
  _StampRingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = s / 2 - 4;

    // Anel duplo.
    final ring = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius - 8, ring);

    // 12 tracinhos curtos como "graduações" — vibe de bússola/serigrafia.
    final tick = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;
    for (int i = 0; i < 24; i++) {
      final a = (i / 24) * 2 * math.pi;
      final inner = Offset(
        center.dx + (radius - 4) * math.cos(a),
        center.dy + (radius - 4) * math.sin(a),
      );
      final outer = Offset(
        center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a),
      );
      canvas.drawLine(inner, outer, tick);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
