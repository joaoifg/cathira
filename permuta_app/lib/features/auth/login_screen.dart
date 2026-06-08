import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env/env.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import 'dev_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _waitingOtp = false;
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await ref
          .read(supabaseClientProvider)
          .auth
          .signInWithOtp(phone: _phoneCtrl.text.trim());
      setState(() => _waitingOtp = true);
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await ref.read(supabaseClientProvider).auth.verifyOTP(
            type: OtpType.sms,
            phone: _phoneCtrl.text.trim(),
            token: _otpCtrl.text.trim(),
          );
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: 'app.cathira://login-callback/',
          );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _devLogin() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await ref.read(devAuthControllerProvider).login(nome: 'Joao Dev');
    } catch (e) {
      setState(() => _err = 'Dev login falhou: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, c) {
            final wide = c.maxWidth >= 880;
            final left = _editorial(context);
            final right = _ctaCard(context);

            if (wide) {
              return Stack(
                children: [
                  _backgroundDecor(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 36, 56, 36),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: left),
                        const SizedBox(width: 56),
                        Expanded(
                          flex: 5,
                          child: Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                _backgroundDecor(),
                ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    left,
                    const SizedBox(height: 28),
                    right,
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Pequenos detalhes geométricos atrás do conteúdo — dá movimento sem competir.
  Widget _backgroundDecor() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Linha gradiente no topo, estilo Stripe.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(gradient: AppColors.gradHero),
            ),
          ),
          // Grid de pontos sutil no canto inferior direito.
          Positioned(
            bottom: 24,
            right: 24,
            child: Opacity(
              opacity: 0.35,
              child: CustomPaint(
                size: const Size(160, 160),
                painter: _DotGridPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Coluna esquerda: identidade + manchete + peça gráfica
  Widget _editorial(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _logoLockup(),
        const SizedBox(height: 64),
        _headline(),
        const SizedBox(height: 24),
        SizedBox(
          width: 500,
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                    height: 1.55,
                    fontSize: 16,
                  ),
              children: const [
                TextSpan(
                  text: 'Carro + bike + console',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                    text:
                        ' viram um lote só. O outro lado monta o dele. A torna sai calculada na hora — sem amadorismo, sem item por item.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        _socialProof(),
        const SizedBox(height: 36),
        _pecaGrafica(),
      ],
    );
  }

  Widget _logoLockup() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'c',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'cathira',
          style: AppTheme.display(22, weight: FontWeight.w700, letter: -1.2),
        ),
        const SizedBox(width: 8),
        // pulsing dot
        _PulsingDot(color: AppColors.success),
        const SizedBox(width: 6),
        Text(
          'BETA 0.1',
          style: AppTheme.mono(10).copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _headline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // eyebrow — etimologia, marca a identidade brasileira raiz.
        Row(
          children: [
            Container(
              width: 24,
              height: 2,
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CATHIRA  ·  DANÇA DE RODA  ·  TROCA DE LANCE',
              style: AppTheme.mono(10, color: AppColors.muted)
                  .copyWith(fontWeight: FontWeight.w800, letterSpacing: 2.2),
            ),
          ],
        ),
        const SizedBox(height: 22),
        // Manchete principal.
        RichText(
          text: TextSpan(
            style: AppTheme.display(64, weight: FontWeight.w700, letter: -3.2),
            children: [
              const TextSpan(text: 'abre a '),
              TextSpan(
                text: 'roda.',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
                    ).createShader(const Rect.fromLTWH(0, 0, 320, 100)),
                ),
              ),
              const TextSpan(text: '\ntroca '),
              TextSpan(
                text: 'tudo.',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
                    ).createShader(const Rect.fromLTWH(0, 0, 280, 100)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialProof() {
    return Row(
      children: [
        _ProofStat(value: '7', label: 'setores'),
        const _ProofDivider(),
        _ProofStat(value: 'R\$ 11M+', label: 'em catálogo'),
        const _ProofDivider(),
        _ProofStat(value: '70+', label: 'permutadores'),
      ],
    );
  }

  Widget _pecaGrafica() {
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 30,
            child: _miniLote(
              emoji: '🚗',
              titulo: 'Civic 2019 EXL',
              valor: 'R\$ 95.000',
              cor1: const Color(0xFFDC2626),
              cor2: const Color(0xFFEF4444),
              rot: -0.08,
            ),
          ),
          Positioned(
            left: 130,
            top: 0,
            child: _miniLote(
              emoji: '🎸',
              titulo: 'Les Paul Studio',
              valor: 'R\$ 9.800',
              cor1: const Color(0xFF7C3AED),
              cor2: const Color(0xFFA855F7),
              rot: 0.04,
            ),
          ),
          Positioned(
            left: 250,
            top: 50,
            child: _miniLote(
              emoji: '🏕️',
              titulo: 'Camping de praia',
              valor: 'R\$ 2.250',
              cor1: const Color(0xFF059669),
              cor2: const Color(0xFF10B981),
              rot: 0.10,
            ),
          ),
          Positioned(
            right: -8,
            top: 100,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.lift,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '= 1 lote',
                    style: AppTheme.mono(13,
                            color: Colors.white,
                            weight: FontWeight.w800)
                        .copyWith(letterSpacing: -0.4),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.accent, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniLote({
    required String emoji,
    required String titulo,
    required String valor,
    required Color cor1,
    required Color cor2,
    required double rot,
  }) {
    return Transform.rotate(
      angle: rot,
      child: Container(
        width: 160,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cor1, cor2],
          ),
          boxShadow: AppShadows.lift,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const Spacer(),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: AppTheme.mono(12,
                  color: Colors.white.withValues(alpha: 0.95)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Coluna direita: card com formulário de auth
  Widget _ctaCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _waitingOtp ? 'confirme o código' : 'entrar',
            style: AppTheme.display(26, weight: FontWeight.w700, letter: -0.8),
          ),
          const SizedBox(height: 4),
          Text(
            _waitingOtp
                ? 'A gente mandou um SMS pro telefone.'
                : 'Telefone, Google ou modo dev.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 22),
          if (!_waitingOtp) ...[
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: '+55 11 91234-5678',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _loading ? null : _sendOtp,
              child: const Text('Receber código por SMS'),
            ),
          ] else ...[
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
                prefixIcon: Icon(Icons.password_rounded),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _loading ? null : _verifyOtp,
              child: const Text('Entrar'),
            ),
            TextButton(
              onPressed:
                  _loading ? null : () => setState(() => _waitingOtp = false),
              child: const Text('Trocar telefone'),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: Divider(color: AppColors.ink.withValues(alpha: 0.08))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'ou',
                  style: AppTheme.mono(11,
                      color: AppColors.muted, weight: FontWeight.w700),
                ),
              ),
              Expanded(
                  child: Divider(color: AppColors.ink.withValues(alpha: 0.08))),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loading ? null : _google,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
            label: const Text('Continuar com Google'),
          ),
          if (Env.devMode) ...[
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: AppColors.accent, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acesso dev',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12.5)),
                        Text(
                          'Token fake sem SMS/Google.',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10.5,
                              height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _loading ? null : _devLogin,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Entrar',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
          if (_err != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_err!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Ao entrar você concorda com nossos termos. A torna é referência — ajuste no chat.',
            style: TextStyle(
              color: AppColors.muted.withValues(alpha: 0.8),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofStat extends StatelessWidget {
  const _ProofStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTheme.display(22, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.mono(10, color: AppColors.muted)
              .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _ProofDivider extends StatelessWidget {
  const _ProofDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        color: AppColors.ink.withValues(alpha: 0.12),
      );
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.25 * (1 - _ctrl.value)),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink.withValues(alpha: 0.18);
    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
