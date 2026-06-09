import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_client.dart';
import '../../core/router/nav_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import '../negociacao/mesa_screen.dart';
import '../perfil/perfil_publico_screen.dart';

class DescobertaScreen extends ConsumerStatefulWidget {
  const DescobertaScreen({super.key});

  @override
  ConsumerState<DescobertaScreen> createState() => _DescobertaScreenState();
}

class _DescobertaScreenState extends ConsumerState<DescobertaScreen> {
  String? _setor;
  String _cidade = '';
  String? _meuLoteId;
  int _cursor = 0;

  @override
  Widget build(BuildContext context) {
    // Se a Home pediu pra filtrar por um setor específico, aplica e consome.
    final setorPedido = ref.watch(setorInicialProvider);
    if (setorPedido != null && setorPedido != _setor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _setor = setorPedido;
          _cursor = 0;
        });
        ref.read(setorInicialProvider.notifier).state = null;
      });
    }

    final setores = ref.watch(setoresProvider);
    final meusLotes = ref.watch(meusLotesProvider);
    final q = DescobertaQuery(setor: _setor, cidade: _cidade);
    final feed = ref.watch(descobertaProvider(q));

    final lotesPossiveis = meusLotes.value ?? const <Lote>[];
    if (_meuLoteId == null && lotesPossiveis.isNotEmpty) {
      _meuLoteId = lotesPossiveis.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descobrir'),
        actions: [
          IconButton(
            tooltip: 'Filtrar por cidade',
            onPressed: () async {
              final v = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  final ctrl = TextEditingController(text: _cidade);
                  return AlertDialog(
                    title: const Text('Filtrar por cidade'),
                    content: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        hintText: 'São Paulo, Rio…',
                        prefixIcon: Icon(Icons.place_rounded),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, ''),
                        child: const Text('Limpar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                        child: const Text('Aplicar'),
                      ),
                    ],
                  );
                },
              );
              if (v != null) {
                setState(() {
                  _cidade = v;
                  _cursor = 0;
                });
              }
            },
            icon: Icon(_cidade.isEmpty
                ? Icons.filter_alt_outlined
                : Icons.filter_alt_rounded),
          ),
          IconButton(
            onPressed: () {
              setState(() => _cursor = 0);
              ref.invalidate(descobertaProvider(
                  DescobertaQuery(setor: _setor, cidade: _cidade)));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: lotesPossiveis.isEmpty
          ? _semLote()
          : Column(
              children: [
                _seletorMeuLote(lotesPossiveis),
                if (_cidade.isNotEmpty) _chipCidadeAtiva(),
                _filtroSetores(setores.value ?? const []),
                Expanded(
                  child: feed.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erro: $e')),
                    data: (data) => _buildDeck(data, setores.value ?? const []),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _semLote() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📦', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Pra descobrir você precisa ter um lote.',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'O sistema casa lotes da mesma faixa de valor.\n'
                'Cria pelo menos um na aba "Lotes".',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );

  Widget _seletorMeuLote(List<Lote> lotes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Negociando com meu lote:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: _meuLoteId,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: lotes
                    .map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(
                            '${l.titulo} (${brl(l.valorTotal)})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _meuLoteId = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipCidadeAtiva() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: const Icon(Icons.place_rounded,
              size: 16, color: AppColors.primary),
          label: Text(_cidade,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          deleteIcon: const Icon(Icons.close_rounded,
              size: 14, color: AppColors.primary),
          onDeleted: () => setState(() {
            _cidade = '';
            _cursor = 0;
          }),
        ),
      ),
    );
  }

  Widget _filtroSetores(List<Setor> data) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _chipSetor('Todos', null, '🌐', AppColors.ink),
          ...data.map((s) =>
              _chipSetor(s.nome, s.slug, s.icone, AppColors.colorFromHex(s.cor))),
        ],
      ),
    );
  }

  Widget _chipSetor(String label, String? slug, String icone, Color cor) {
    final sel = _setor == slug;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: sel ? cor : Colors.white,
        side: BorderSide(color: sel ? Colors.transparent : Colors.black.withValues(alpha: 0.1)),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        label: Text(
          '$icone  $label',
          style: TextStyle(
            color: sel ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        onPressed: () {
          setState(() {
            _setor = slug;
            _cursor = 0;
          });
        },
      ),
    );
  }

  Widget _buildDeck(List<Lote> feed, List<Setor> setores) {
    if (feed.isEmpty) {
      return _emptyFeed();
    }
    if (_cursor >= feed.length) {
      return _semMaisCards();
    }
    final atual = feed[_cursor];
    final proximo = _cursor + 1 < feed.length ? feed[_cursor + 1] : null;
    final setMap = {for (final s in setores) s.slug: s};

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          Expanded(
            child: _SwipeStack(
              key: ValueKey('${atual.id}-$_cursor'),
              atual: _LoteCard(lote: atual, setor: setMap[atual.setorPrincipal]),
              proximo: proximo != null
                  ? _LoteCard(lote: proximo, setor: setMap[proximo.setorPrincipal])
                  : null,
              onSwipeLeft: () => _swipe(atual, 'pass'),
              onSwipeRight: () => _swipe(atual, 'like'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _bigBtn(Icons.close_rounded, Colors.white, AppColors.ink,
                  () => _swipe(atual, 'pass')),
              _bigBtn(Icons.swap_horiz_rounded, AppColors.primary, Colors.white,
                  () => _swipe(atual, 'like')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyFeed() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌌', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Sem lotes pra mostrar agora.',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Roda "Popular mundo demo" no perfil pra povoar com lotes de outros usuários.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      );

  Widget _semMaisCards() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Você viu todos!',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  setState(() => _cursor = 0);
                  ref.invalidate(descobertaProvider(
                      DescobertaQuery(setor: _setor, cidade: _cidade)));
                },
                child: const Text('Recarregar'),
              ),
            ],
          ),
        ),
      );

  Widget _bigBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: bg.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon, color: fg, size: 30),
        ),
      ),
    );
  }

  Future<void> _swipe(Lote alvo, String decisao) async {
    if (_meuLoteId == null) return;
    final dio = ref.read(apiClientProvider);
    try {
      final r = await dio.post<Map<String, dynamic>>('/swipes', data: {
        'from_lote': _meuLoteId,
        'to_lote': alvo.id,
        'decisao': decisao,
      });
      final res = r.data ?? const {};
      final match = res['match'] == true;
      if (match) {
        final negId = res['negociacao_id'] as String?;
        if (negId != null && mounted) {
          await _showMatch(negId, alvo);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Swipe falhou: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cursor++);
      ref.invalidate(minhasNegociacoesProvider);
    }
  }

  Future<void> _showMatch(String negId, Lote alvo) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            const Text('Match!',
                style:
                    TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              'Vocês dois curtiram. Bora pra mesa de negociação.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.muted, height: 1.4, fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MesaScreen(negociacaoId: negId),
                ));
              },
              icon: const Icon(Icons.handshake_rounded),
              label: const Text('Abrir mesa'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Depois'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoteCard extends ConsumerWidget {
  const _LoteCard({required this.lote, this.setor});
  final Lote lote;
  final Setor? setor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grad = setor != null
        ? AppColors.gradientFromHex(setor!.cor)
        : AppColors.gradHero;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundo: gradiente do setor (também é o fallback se a foto falhar).
            DecoratedBox(decoration: BoxDecoration(gradient: grad)),
            // Foto de capa do lote (1ª foto do 1º item).
            if (lote.capa != null && lote.capa!.isNotEmpty)
              Image.network(
                lote.capa!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    DecoratedBox(decoration: BoxDecoration(gradient: grad)),
                loadingBuilder: (ctx, child, prog) => prog == null
                    ? child
                    : DecoratedBox(
                        decoration: BoxDecoration(gradient: grad),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
              ),
            // Escurece de cima e de baixo pra manter o texto legível sobre a foto.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(setor?.icone ?? '📦',
                    style: const TextStyle(fontSize: 44)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    setor?.nome ?? lote.setorPrincipal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              lote.titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (lote.donoNome != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: lote.donoId == null
                          ? null
                          : () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => PerfilPublicoScreen(
                                  userId: lote.donoId!,
                                  nomeFallback: lote.donoNome,
                                ),
                              ));
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lote.donoNome!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            if (lote.donoReputacao > 0) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded,
                                  color: Colors.amberAccent, size: 13),
                              const SizedBox(width: 2),
                              Text(
                                lote.donoReputacao.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withValues(alpha: 0.75),
                                size: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (lote.donoCidade != null && lote.donoCidade!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.place_rounded,
                          color: Colors.white.withValues(alpha: 0.9), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        lote.donoCidade!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (lote.numItens > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${lote.numItens} ${lote.numItens == 1 ? "item" : "itens"} no lote',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Valor do lote',
                      brl(lote.valorTotal),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: _stat(
                      'Quer receber',
                      lote.faixaAlvoMin != null
                          ? '${brl(lote.faixaAlvoMin)}+'
                          : '—',
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

/// Card empilhado com gesto de arrastar pra esquerda (pass) / direita (like).
/// Mostra "stamp" de LIKE ou PASS quando o usuário arrasta o suficiente.
class _SwipeStack extends StatefulWidget {
  const _SwipeStack({
    super.key,
    required this.atual,
    required this.proximo,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final Widget atual;
  final Widget? proximo;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  State<_SwipeStack> createState() => _SwipeStackState();
}

class _SwipeStackState extends State<_SwipeStack>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  bool _animatingOut = false;
  Offset _exitTarget = Offset.zero;

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animatingOut) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d, double width) {
    if (_animatingOut) return;
    if (_drag.dx > width * 0.25) {
      _flyOut(Offset(width * 1.6, _drag.dy), widget.onSwipeRight);
    } else if (_drag.dx < -width * 0.25) {
      _flyOut(Offset(-width * 1.6, _drag.dy), widget.onSwipeLeft);
    } else {
      setState(() => _drag = Offset.zero);
    }
  }

  void _flyOut(Offset target, VoidCallback cb) {
    setState(() {
      _exitTarget = target;
      _animatingOut = true;
    });
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      cb();
      setState(() {
        _drag = Offset.zero;
        _animatingOut = false;
        _exitTarget = Offset.zero;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final progress = (_drag.dx / (w * 0.5)).clamp(-1.0, 1.0);
        final angle = progress * 0.18;
        final pos = _animatingOut ? _exitTarget : _drag;
        final likeOpacity = progress.clamp(0.0, 1.0);
        final passOpacity = (-progress).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.proximo != null)
              Positioned.fill(
                child: AnimatedScale(
                  scale: 0.94 + 0.06 * progress.abs(),
                  duration: const Duration(milliseconds: 200),
                  child: Opacity(
                    opacity: 0.55 + 0.35 * progress.abs(),
                    child: widget.proximo!,
                  ),
                ),
              ),
            Positioned.fill(
              child: AnimatedSlide(
                offset: Offset.zero,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: _animatingOut
                      ? const Duration(milliseconds: 260)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(pos.dx, pos.dy * 0.4)
                    ..rotateZ(angle),
                  transformAlignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: (d) => _onPanEnd(d, w),
                    child: Stack(
                      children: [
                        widget.atual,
                        Positioned(
                          top: 24,
                          left: 24,
                          child: _stamp('TROCA', AppColors.success, likeOpacity),
                        ),
                        Positioned(
                          top: 24,
                          right: 24,
                          child: _stamp('PASS', AppColors.danger, passOpacity),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stamp(String label, Color cor, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: label == 'TROCA' ? -0.25 : 0.25,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: cor, width: 4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
