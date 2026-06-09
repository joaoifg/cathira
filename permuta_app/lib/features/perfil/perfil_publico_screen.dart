import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import '../../shared/widgets/cathira_glyph.dart';

/// Perfil público — visualização do "inventário" de alguém. É o que abre
/// quando você toca no nome de um dono em qualquer card. Mostra:
///   - hero com avatar gradient + nome + reputação estrelada + cidade
///   - lotes abertos (sugestões pré-montadas pelo dono)
///   - inventário aberto (itens disponíveis pra negociar)
///   - avaliações recentes
class PerfilPublicoScreen extends ConsumerWidget {
  const PerfilPublicoScreen({super.key, required this.userId, this.nomeFallback});

  final String userId;
  final String? nomeFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilPublicoProvider(userId));
    final setores = ref.watch(setoresProvider).value ?? const <Setor>[];
    final setoresMap = {for (final s in setores) s.slug: s};

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: perfil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _erroLayout(context, '$e'),
        data: (d) => _content(context, ref, d, setoresMap),
      ),
    );
  }

  Widget _erroLayout(BuildContext ctx, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined,
                size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('Perfil não disponível',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext ctx, WidgetRef ref, PerfilPublico d,
      Map<String, Setor> setMap) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _hero(d),
            titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
            title: Text(
              d.perfil.nome,
              style: AppTheme.display(20, color: Colors.white, letter: -0.4),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _statsBar(d),
              const SizedBox(height: 24),
              if (d.lotes.isNotEmpty) ...[
                _sectionHeader('Lotes sugeridos pelo dono', d.lotes.length),
                const SizedBox(height: 12),
                ..._lotesList(ctx, d.lotes, setMap),
                const SizedBox(height: 28),
              ],
              _sectionHeader('Inventário aberto', d.itens.length),
              const SizedBox(height: 12),
              _inventario(ctx, d.itens, setMap),
              if (d.avaliacoes.isNotEmpty) ...[
                const SizedBox(height: 28),
                _sectionHeader('Avaliações recentes', d.avaliacoes.length),
                const SizedBox(height: 12),
                ..._avaliacoes(d.avaliacoes),
              ],
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Hero
  Widget _hero(PerfilPublico d) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto de fundo: 1ª foto do inventário (ou gradient se sem foto).
        if (d.itens.isNotEmpty &&
            d.itens.first.fotos.isNotEmpty)
          Image.network(
            d.itens.first.fotos.first,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(gradient: AppColors.gradHero),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(gradient: AppColors.gradHero),
          ),
        // Overlay escuro pra texto sair legível.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.ink.withValues(alpha: 0.10),
                AppColors.ink.withValues(alpha: 0.55),
                AppColors.ink.withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Avatar gradient + reputação + cidade.
        Positioned(
          left: 20,
          right: 20,
          bottom: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _avatar(d.perfil),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _glassChip(_reputacaoLabel(d.perfil)),
                    const SizedBox(height: 6),
                    if (d.perfil.cidade != null && d.perfil.cidade!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.place_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 14),
                          const SizedBox(width: 4),
                          Text(
                            d.perfil.cidade!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar(PerfilDono p) {
    final inicial = p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?';
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradHero,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: AppShadows.lift,
      ),
      child: p.fotoUrl != null && p.fotoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                p.fotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    inicial,
                    style: AppTheme.display(32, color: Colors.white),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                inicial,
                style: AppTheme.display(32, color: Colors.white),
              ),
            ),
    );
  }

  Widget _glassChip(String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Colors.amberAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reputacaoLabel(PerfilDono p) {
    if (p.reputacao <= 0) return 'sem avaliações';
    return '${p.reputacao.toStringAsFixed(1)} · ${p.numTrocas} ${p.numTrocas == 1 ? "troca" : "trocas"}';
  }

  // ─── Stats em linha
  Widget _statsBar(PerfilPublico d) {
    final inventarioValor =
        d.itens.fold<double>(0, (a, i) => a + i.valorReferencia);
    return Container(
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
                child: _statCell(
                    'No inventário',
                    '${d.itens.length}',
                    AppColors.ink)),
            _statDivider(),
            Expanded(
                child: _statCell(
                    'Lotes', '${d.lotes.length}', AppColors.primary)),
            _statDivider(),
            Expanded(
                child: _statCell(
                    'Valor', brl(inventarioValor), AppColors.success)),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTheme.mono(20, color: cor, weight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label,
              style: AppTheme.mono(10, color: AppColors.muted).copyWith(
                  fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: AppColors.ink.withValues(alpha: 0.08),
      );

  Widget _sectionHeader(String label, int count) {
    return Row(
      children: [
        Text(label,
            style: AppTheme.display(20, weight: FontWeight.w700, letter: -0.6)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: AppTheme.mono(11, weight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // ─── Lotes (cards horizontais)
  List<Widget> _lotesList(BuildContext ctx, List<LoteMiniPub> lotes,
      Map<String, Setor> setMap) {
    return [
      SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: lotes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final l = lotes[i];
            final setor = setMap[l.setorPrincipal];
            final cor = setor != null
                ? AppColors.colorFromHex(setor.cor)
                : AppColors.primary;
            return Container(
              width: 240,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (l.capa != null && l.capa!.isNotEmpty)
                          Image.network(l.capa!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: setor != null
                                          ? AppColors.gradientFromHex(setor.cor)
                                          : AppColors.gradHero,
                                    ),
                                  ))
                        else
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: setor != null
                                  ? AppColors.gradientFromHex(setor.cor)
                                  : AppColors.gradHero,
                            ),
                          ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${setor?.icone ?? "📦"} ${setor?.nome ?? l.setorPrincipal}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5)),
                        const SizedBox(height: 2),
                        Text(
                          '${l.numItens} ${l.numItens == 1 ? "item" : "itens"}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(brl(l.valorTotal),
                            style: AppTheme.mono(15,
                                color: cor, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  // ─── Inventário em grid
  Widget _inventario(BuildContext ctx, List<ItemPub> itens,
      Map<String, Setor> setMap) {
    if (itens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Text('🪶', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sem itens no inventário ainda.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: itens.length,
      itemBuilder: (_, i) => _itemCard(itens[i], setMap),
    );
  }

  Widget _itemCard(ItemPub it, Map<String, Setor> setMap) {
    final setor = setMap[it.setorSlug];
    final cor =
        setor != null ? AppColors.colorFromHex(setor.cor) : AppColors.muted;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (it.fotos.isNotEmpty)
                  Image.network(it.fotos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.surfaceAlt))
                else
                  Container(color: AppColors.surfaceAlt),
                if (it.loteTitulo != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_rounded,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            it.loteTitulo!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  setor?.nome ?? it.categoria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(brl(it.valorReferencia),
                    style: AppTheme.mono(13,
                        color: cor, weight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Avaliações
  List<Widget> _avaliacoes(List<AvaliacaoPub> avals) {
    return avals.map((a) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CathiraGlyph(size: 18, color: AppColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(a.deNome,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(width: 8),
                      ...List.generate(
                          5,
                          (i) => Icon(
                                i < a.nota
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 13,
                                color: AppColors.accent,
                              )),
                    ],
                  ),
                  if (a.comentario != null && a.comentario!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        a.comentario!,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.inkSoft, height: 1.35),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
