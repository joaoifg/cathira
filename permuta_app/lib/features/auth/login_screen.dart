import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env/api_url_override.dart';
import '../../core/env/env.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/cathira_glyph.dart';
import 'dev_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _apiUrlCtrl = TextEditingController();
  bool _waitingOtp = false;
  bool _loading = false;
  bool _editApiUrl = false;
  String? _err;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _apiUrlCtrl.dispose();
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
      setState(() => _err = 'Dev login falhou: $e\n\nVerifique o IP da API.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, c) {
            final wide = c.maxWidth >= 980;
            return wide ? _wideLayout(c.maxHeight) : _mobileLayout();
          },
        ),
      ),
    );
  }

  // ─── Mobile / web estreito
  Widget _mobileLayout() {
    return Stack(
      children: [
        _heroImageCollage(),
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _topBar(light: true),
                const SizedBox(height: 24),
                _cathiraLogoBlock(scale: 1.0),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ctaCard(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Desktop / web largo
  Widget _wideLayout(double h) {
    return Stack(
      children: [
        _heroImageCollage(),
        Padding(
          padding: const EdgeInsets.fromLTRB(56, 28, 56, 36),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(light: true),
                    const Spacer(),
                    _cathiraLogoBlock(scale: 1.6),
                    const SizedBox(height: 12),
                    _socialProof(),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(width: 56),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _ctaCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Foto de fundo: collage de 6 imagens picsum + overlay escuro.
  Widget _heroImageCollage() {
    const seeds = [
      'cathira-bg-1',
      'cathira-bg-2',
      'cathira-bg-3',
      'cathira-bg-4',
      'cathira-bg-5',
      'cathira-bg-6',
    ];
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 0.85,
            ),
            itemCount: seeds.length,
            itemBuilder: (_, i) => Image.network(
              'https://picsum.photos/seed/${seeds[i]}/600/700',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.ink),
            ),
          ),
          // Overlay duplo: cor + gradiente vertical pra texto sair bonito.
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.58),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.ink.withValues(alpha: 0.20),
                  AppColors.ink.withValues(alpha: 0.55),
                  AppColors.ink.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar({required bool light}) {
    final c = light ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          CathiraGlyph(size: 26, color: c),
          const SizedBox(width: 8),
          Text(
            'cathira',
            style: AppTheme.display(20, color: c, letter: 0.4),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Nome CATHIRA gigantesco.
  Widget _cathiraLogoBlock({required double scale}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nome enorme com gradient overlay. Único protagonista da tela.
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFDE2C8),
                Color(0xFFFB923C),
              ],
              stops: [0.0, 0.45, 1.0],
            ).createShader(rect),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'CATHIRA',
                style: AppTheme.display(
                  140 * scale,
                  color: Colors.white,
                  letter: 4 * scale,
                  height: 0.85,
                ),
              ),
            ),
          ),
          SizedBox(height: 32 * scale.clamp(1, 1.2)),
          _miniLotesFan(scale: scale),
        ],
      ),
    );
  }

  /// 3 mini-cards de lote em fan rotacionado — comunica visualmente
  /// "vários ativos viram 1 lote". Reativado a pedido.
  Widget _miniLotesFan({required double scale}) {
    final w = 140.0 * scale.clamp(1, 1.15);
    final h = 180.0 * scale.clamp(1, 1.15);
    return SizedBox(
      height: h + 50,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -(w * 0.55),
            top: 20,
            child: _miniLote(
              w: w,
              h: h,
              emoji: '🚗',
              titulo: 'Civic EXL',
              valor: 'R\$ 95.000',
              cor1: const Color(0xFFDC2626),
              cor2: const Color(0xFFEF4444),
              rot: -0.12,
              fotoSeed: 'civic-vermelho',
            ),
          ),
          _miniLote(
            w: w,
            h: h,
            emoji: '🎸',
            titulo: 'Les Paul Studio',
            valor: 'R\$ 9.800',
            cor1: const Color(0xFF7C3AED),
            cor2: const Color(0xFFA855F7),
            rot: 0.0,
            fotoSeed: 'guitarra-estudio',
          ),
          Positioned(
            right: -(w * 0.55),
            top: 28,
            child: _miniLote(
              w: w,
              h: h,
              emoji: '🏕️',
              titulo: 'Camping',
              valor: 'R\$ 2.250',
              cor1: const Color(0xFF059669),
              cor2: const Color(0xFF10B981),
              rot: 0.14,
              fotoSeed: 'camping-barraca',
            ),
          ),
          // Badge "= 1 lote" pendurado embaixo.
          Positioned(
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: AppShadows.lift,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CathiraGlyph(
                    size: 14,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '= 1 lote',
                    style: AppTheme.mono(12,
                            color: AppColors.ink, weight: FontWeight.w800)
                        .copyWith(letterSpacing: -0.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniLote({
    required double w,
    required double h,
    required String emoji,
    required String titulo,
    required String valor,
    required Color cor1,
    required Color cor2,
    required double rot,
    required String fotoSeed,
  }) {
    return Transform.rotate(
      angle: rot,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: cor1.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Foto picsum como background.
              Image.network(
                'https://picsum.photos/seed/$fotoSeed/480/600',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cor1, cor2],
                    ),
                  ),
                ),
              ),
              // Efeito glass: blur a foto + cor do setor sutil por cima.
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cor1.withValues(alpha: 0.32),
                        cor2.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              // Vinheta escura embaixo pra texto sair legível.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Borda branca translúcida.
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
              ),
              // Conteúdo.
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip do setor com emoji + cor.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: w * 0.12),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.095,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        shadows: const [
                          Shadow(
                            color: Color(0x80000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      style: AppTheme.mono(w * 0.085,
                          color: Colors.white, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _proofStat('7', 'setores'),
          _proofDivider(),
          _proofStat('R\$ 11M+', 'em catálogo'),
          _proofDivider(),
          _proofStat('70+', 'permutadores'),
        ],
      ),
    );
  }

  Widget _proofStat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTheme.display(24, color: Colors.white, letter: 0.3)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _proofDivider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        color: Colors.white.withValues(alpha: 0.22),
      );

  // ─── Card de auth com efeito glass (frosted).
  Widget _ctaCard() {
    final apiUrl = ref.watch(effectiveApiBaseUrlProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 60,
                offset: const Offset(0, 28),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _waitingOtp ? 'CONFIRMA O CÓDIGO' : 'ENTRAR',
            style: AppTheme.display(26, letter: 1.0),
          ),
          const SizedBox(height: 4),
          Text(
            _waitingOtp
                ? 'A gente mandou um SMS pro telefone.'
                : 'Telefone, Google ou modo dev.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: Divider(color: AppColors.ink.withValues(alpha: 0.08))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('ou',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    )),
              ),
              Expanded(
                  child: Divider(color: AppColors.ink.withValues(alpha: 0.08))),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _google,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
            label: const Text('Continuar com Google'),
          ),
          if (Env.devMode) ...[
            const SizedBox(height: 16),
            _devBlock(apiUrl),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_err!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12.5, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }

  Widget _devBlock(String apiUrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
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
                        'Token fake. Use no iPhone com IP da máquina.',
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
          Container(
              height: 1, color: AppColors.ink.withValues(alpha: 0.05)),
          // URL atual + edição
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: _editApiUrl
                ? _apiUrlEditor(apiUrl)
                : _apiUrlReadonly(apiUrl),
          ),
        ],
      ),
    );
  }

  Widget _apiUrlReadonly(String apiUrl) {
    return Row(
      children: [
        const Icon(Icons.lan_rounded, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            apiUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            _apiUrlCtrl.text = apiUrl;
            setState(() => _editApiUrl = true);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            minimumSize: const Size(0, 0),
            foregroundColor: AppColors.primary,
          ),
          child: const Text('mudar',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _apiUrlEditor(String apiUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'URL da API (do iPhone, use o IP da máquina dev na LAN):',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 10.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _apiUrlCtrl,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.10:8080',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () async {
                await ref.read(apiUrlOverrideProvider.notifier).set(null);
                if (mounted) setState(() => _editApiUrl = false);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 0),
                foregroundColor: AppColors.muted,
              ),
              child: const Text('voltar ao default',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(apiUrlOverrideProvider.notifier)
                    .set(_apiUrlCtrl.text);
                if (mounted) setState(() => _editApiUrl = false);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('salvar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ],
    );
  }
}
