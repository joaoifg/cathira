import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import '../../shared/widgets/glass.dart';
import '../perfil/perfil_publico_screen.dart';
import 'mesa_screen.dart';

/// Tela de "Interesses recebidos" — quando alguém curte um item meu na
/// descoberta por item, aparece aqui. Posso aceitar (abre Mesa exploradora
/// com o item já dentro) ou recusar.
class InteressesScreen extends ConsumerWidget {
  const InteressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interesses = ref.watch(interessesRecebidosProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Interesses recebidos'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(interessesRecebidosProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: interesses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data.isEmpty) return _empty(context);
          return RefreshIndicator(
            edgeOffset: GlassAppBar.alturaTotal(context),
            onRefresh: () async =>
                ref.invalidate(interessesRecebidosProvider),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  20, GlassAppBar.alturaTotal(context) + 12, 20, 32),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _InteresseCard(data: data[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💌', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 14),
              Text('Nenhum interesse novo.',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Quando alguém curtir um item seu na descoberta,\n'
                'aparece aqui pra você aceitar ou recusar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

class _InteresseCard extends ConsumerStatefulWidget {
  const _InteresseCard({required this.data});
  final Map<String, dynamic> data;

  @override
  ConsumerState<_InteresseCard> createState() => _InteresseCardState();
}

class _InteresseCardState extends ConsumerState<_InteresseCard> {
  bool _processando = false;

  Future<void> _aceitar() async {
    setState(() => _processando = true);
    try {
      final dio = ref.read(apiClientProvider);
      final r = await dio.post<Map<String, dynamic>>(
        '/interesses/${widget.data['id']}/aceitar',
      );
      final negID = r.data?['negociacao_id'] as String?;
      ref.invalidate(interessesRecebidosProvider);
      ref.invalidate(minhasNegociacoesProvider);
      if (negID != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MesaScreen(negociacaoId: negID),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falhou: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _recusar() async {
    setState(() => _processando = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/interesses/${widget.data['id']}/recusar');
      ref.invalidate(interessesRecebidosProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falhou: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final fotos = ((d['item_fotos'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final deNome = d['de_nome'] as String? ?? '—';
    final deCidade = d['de_cidade'] as String?;
    final deRep = (d['de_reputacao'] as num?)?.toDouble() ?? 0;
    final itemTitulo = d['item_titulo'] as String? ?? '—';
    final itemValor = (d['item_valor'] as num?)?.toDouble() ?? 0;
    final itemCategoria = d['item_categoria'] as String? ?? '';
    final deID = d['de_id'] as String?;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          // Cabeçalho: foto do item + info
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (fotos.isNotEmpty)
                  Image.network(
                    fotos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.surfaceAlt),
                  )
                else
                  Container(color: AppColors.surfaceAlt),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.62),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$deNome curtiu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemTitulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (itemCategoria.isNotEmpty)
                              Text(
                                itemCategoria,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        brl(itemValor),
                        style: AppTheme.mono(16,
                            color: Colors.white,
                            weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Quem mandou (clicável → perfil público)
          InkWell(
            onTap: deID == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PerfilPublicoScreen(
                          userId: deID,
                          nomeFallback: deNome,
                        ),
                      ),
                    ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.gradHero,
                    ),
                    child: Center(
                      child: Text(
                        deNome.isNotEmpty ? deNome[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                deNome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5),
                              ),
                            ),
                            if (deRep > 0) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded,
                                  color: AppColors.accent, size: 13),
                              Text(
                                deRep.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        if (deCidade != null && deCidade.isNotEmpty)
                          Text(
                            deCidade,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted, size: 18),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Botões
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processando ? null : _recusar,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.ink,
                      side: BorderSide(
                          color: AppColors.ink.withValues(alpha: 0.12)),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _processando ? null : _aceitar,
                    icon: const Icon(Icons.travel_explore_rounded, size: 18),
                    label: const Text('Explorar inventário'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
