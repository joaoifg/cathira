import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/nav_providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/dev_auth.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setores = ref.watch(setoresProvider);
    final meusLotes = ref.watch(meusLotesProvider);
    final negociacoes = ref.watch(minhasNegociacoesProvider);
    final descoberta = ref.watch(
      descobertaProvider(const DescobertaQuery()),
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(setoresProvider);
            ref.invalidate(meusLotesProvider);
            ref.invalidate(minhasNegociacoesProvider);
            ref.invalidate(descobertaProvider(const DescobertaQuery()));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Saudacao(ref: ref)),
              SliverToBoxAdapter(
                  child: _quickStats(meusLotes, negociacoes, descoberta)),
              SliverToBoxAdapter(child: const SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  titulo: 'Destaque agora',
                  subtitulo: 'Algo do seu nível pra você dar um like',
                  action: 'Ver tudo →',
                  onAction: () => ref
                      .read(currentTabProvider.notifier)
                      .state = AppTab.descobrir,
                ),
              ),
              SliverToBoxAdapter(child: _heroLote(context, ref, descoberta)),
              SliverToBoxAdapter(child: const SizedBox(height: 32)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  titulo: 'Em alta',
                  subtitulo: 'Mais lotes acabados de subir',
                ),
              ),
              SliverToBoxAdapter(child: _carrossel(context, descoberta)),
              SliverToBoxAdapter(child: const SizedBox(height: 32)),
              SliverToBoxAdapter(
                child: _SectionTitle(
                  titulo: 'Explorar por setor',
                  subtitulo: 'Toca pra filtrar a descoberta',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                sliver: setores.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(child: Text('Erro: $e')),
                  data: (data) => SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _SetorPill(setor: data[i]),
                      childCount: data.length,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _comoFunciona(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats em uma linha
  Widget _quickStats(AsyncValue<List<Lote>> lotes,
      AsyncValue<List<Negociacao>> negs, AsyncValue<List<Lote>> desc) {
    final list = lotes.value ?? const <Lote>[];
    final totalValor = list.fold<double>(0, (a, l) => a + l.valorTotal);
    final activeNegs = (negs.value ?? const [])
        .where((n) =>
            n.statusTexto == 'proposta' || n.statusTexto == 'contraproposta')
        .length;
    final disponiveis = desc.value?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
          boxShadow: AppShadows.soft,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                  child: _StatLine(
                      label: 'Meus lotes',
                      value: '${list.length}',
                      cor: AppColors.primary)),
              _vDivider(),
              Expanded(
                  child: _StatLine(
                      label: 'Catálogo',
                      value: brl(totalValor),
                      cor: AppColors.success)),
              _vDivider(),
              Expanded(
                  child: _StatLine(
                      label: 'Negociando',
                      value: '$activeNegs',
                      cor: AppColors.accent)),
              _vDivider(),
              Expanded(
                  child: _StatLine(
                      label: 'No feed',
                      value: '$disponiveis',
                      cor: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: AppColors.ink.withValues(alpha: 0.08),
      );

  // ─── Hero card de 1 lote do feed
  Widget _heroLote(BuildContext ctx, WidgetRef ref,
      AsyncValue<List<Lote>> descoberta) {
    return descoberta.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Feed vazio',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Roda "Popular mundo demo" no perfil pra povoar com lotes de outras personas.',
                    style: TextStyle(
                        color: AppColors.muted, height: 1.4, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        final destaque = data.first;
        final setor = ref.watch(setoresProvider).value?.firstWhere(
              (s) => s.slug == destaque.setorPrincipal,
              orElse: () => Setor(
                  slug: destaque.setorPrincipal,
                  nome: destaque.setorPrincipal,
                  icone: '📦',
                  cor: '#FF5722',
                  categorias: const []),
            );
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _HeroLoteCard(
            lote: destaque,
            setor: setor,
            onTap: () =>
                ref.read(currentTabProvider.notifier).state = AppTab.descobrir,
          ),
        );
      },
    );
  }

  // ─── Carrossel horizontal
  Widget _carrossel(BuildContext ctx, AsyncValue<List<Lote>> desc) {
    final data = desc.value ?? const <Lote>[];
    if (data.length < 2) return const SizedBox(height: 8);
    final lista = data.skip(1).take(8).toList();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        itemCount: lista.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _MiniLoteCard(lote: lista[i]),
      ),
    );
  }

  Widget _comoFunciona(BuildContext ctx) {
    final passos = [
      ('📦', 'monta um lote',
          'Junta 1, 2 ou 10 itens — você decide o que entra.'),
      ('🔥', 'descobre',
          'Lotes na sua faixa de valor aparecem no feed.'),
      ('⚖️', 'mesa ao vivo',
          'Adiciona ou tira item, torna recalcula sozinha.'),
      ('🤝', 'aceita e fecha', 'Os dois confirmam — virou compromisso.'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          gradient: AppColors.gradInk,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'COMO FUNCIONA',
                  style: AppTheme.mono(10,
                          color: AppColors.accent, weight: FontWeight.w800)
                      .copyWith(letterSpacing: 1.6),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'quatro passos.\nsem mistério.',
              style: AppTheme.display(28,
                  color: Colors.white, weight: FontWeight.w700, letter: -1.2),
            ),
            const SizedBox(height: 18),
            ...passos.asMap().entries.map((e) {
              final p = e.value;
              final n = e.key + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '0$n',
                        style: AppTheme.mono(14,
                            color: AppColors.accent, weight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(p.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.$2,
                              style: AppTheme.display(15,
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                  letter: -0.4)),
                          const SizedBox(height: 1),
                          Text(p.$3,
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12.5,
                                  height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Componentes
// ─────────────────────────────────────────────────────────────

class _Saudacao extends ConsumerWidget {
  const _Saudacao({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final dev = ref.watch(devSessionProvider);
    final user = ref.watch(supabaseClientProvider).auth.currentUser;
    final nome = (dev?.nome ?? user?.userMetadata?['nome']?.toString() ?? '')
        .split(' ')
        .first;
    final hora = DateTime.now().hour;
    final emoji = hora < 6
        ? '🌙'
        : hora < 12
            ? '☀️'
            : hora < 18
                ? '👋'
                : '🌆';
    final saudacao = hora < 6
        ? 'boa madrugada'
        : hora < 12
            ? 'bom dia'
            : hora < 18
                ? 'boa tarde'
                : 'boa noite';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding bar com pulsing dot
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'c',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('cathira',
                  style: AppTheme.display(15,
                      weight: FontWeight.w700, letter: -0.8)),
              const SizedBox(width: 8),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'AO VIVO',
                style: AppTheme.mono(9, color: AppColors.muted)
                    .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '$saudacao${nome.isNotEmpty ? ", $nome" : ""}',
                style: AppTheme.mono(11, color: AppColors.muted)
                    .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: AppTheme.display(40,
                  weight: FontWeight.w700, letter: -1.8),
              children: [
                const TextSpan(text: 'abre a '),
                TextSpan(
                  text: 'roda.',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 60)),
                  ),
                ),
                const TextSpan(text: '\nhoje tem lote\nnovo no feed.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine(
      {required this.label, required this.value, required this.cor});
  final String label;
  final String value;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.mono(20, color: cor, weight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTheme.mono(10, color: AppColors.muted)
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.titulo,
    this.subtitulo,
    this.action,
    this.onAction,
  });
  final String titulo;
  final String? subtitulo;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style:
                      AppTheme.display(22, weight: FontWeight.w700, letter: -0.8),
                ),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitulo!,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 0),
              ),
              child: Text(
                action!,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroLoteCard extends StatelessWidget {
  const _HeroLoteCard({
    required this.lote,
    required this.setor,
    required this.onTap,
  });
  final Lote lote;
  final Setor? setor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final grad = setor != null
        ? AppColors.gradientFromHex(setor!.cor)
        : AppColors.gradHero;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.lift,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: grad)),
            if (lote.capa != null && lote.capa!.isNotEmpty)
              Image.network(
                lote.capa!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    DecoratedBox(decoration: BoxDecoration(gradient: grad)),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${setor?.icone ?? "📦"} ${setor?.nome ?? lote.setorPrincipal}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_rounded,
                                color: AppColors.primary, size: 14),
                            SizedBox(width: 4),
                            Text('Em destaque',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    lote.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(28,
                        color: Colors.white,
                        weight: FontWeight.w700,
                        letter: -1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (lote.donoNome != null)
                        Text(
                          'por ${lote.donoNome}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (lote.donoReputacao > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded,
                            color: Colors.amberAccent, size: 14),
                        Text(
                          ' ${lote.donoReputacao.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        brl(lote.valorTotal),
                        style: AppTheme.mono(22,
                            color: Colors.white,
                            weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLoteCard extends StatelessWidget {
  const _MiniLoteCard({required this.lote});
  final Lote lote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.surfaceAlt,
                ),
                if (lote.capa != null && lote.capa!.isNotEmpty)
                  Image.network(
                    lote.capa!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lote.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  lote.donoNome ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  brl(lote.valorTotal),
                  style: AppTheme.mono(15,
                      color: AppColors.success, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetorPill extends ConsumerWidget {
  const _SetorPill({required this.setor});
  final Setor setor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cor = AppColors.colorFromHex(setor.cor);
    return InkWell(
      onTap: () {
        ref.read(setorInicialProvider.notifier).state = setor.slug;
        ref.read(currentTabProvider.notifier).state = AppTab.descobrir;
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppColors.gradientFromHex(setor.cor),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child:
                    Text(setor.icone, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    setor.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  if (setor.tagline != null)
                    Text(
                      setor.tagline!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cor.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

