import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/http/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';
import '../../shared/widgets/glass.dart';
import '../auth/dev_auth.dart';

class MesaScreen extends ConsumerStatefulWidget {
  const MesaScreen({super.key, required this.negociacaoId});
  final String negociacaoId;

  @override
  ConsumerState<MesaScreen> createState() => _MesaScreenState();
}

class _MesaScreenState extends ConsumerState<MesaScreen> {
  RealtimeChannel? _channel;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  @override
  void dispose() {
    final ch = _channel;
    if (ch != null) {
      ref.read(supabaseClientProvider).removeChannel(ch);
    }
    super.dispose();
  }

  void _setupRealtime() {
    final supabase = ref.read(supabaseClientProvider);

    // Se for dev login, injeta o JWT no Realtime (o cliente Supabase senão
    // não saberia que estamos logados pra autenticar o WebSocket).
    final dev = ref.read(devSessionProvider);
    if (dev != null) {
      supabase.realtime.setAuth(dev.token);
    }

    _channel = supabase
        .channel('mesa-${widget.negociacaoId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'negociacoes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.negociacaoId,
          ),
          callback: (payload) {
            ref.invalidate(negociacaoDetalheProvider(widget.negociacaoId));
            // Mostra um toast leve quando o outro lado mexer.
            final novo = payload.newRecord;
            final ultimaAcao = novo['ultima_acao'] as String?;
            final dev = ref.read(devSessionProvider);
            final supa = ref.read(supabaseClientProvider);
            final meuUid = dev?.userId ?? supa.auth.currentUser?.id;
            if (ultimaAcao != null && ultimaAcao != meuUid && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('💫 O outro lado mexeu na mesa'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensagens',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'negociacao_id',
            value: widget.negociacaoId,
          ),
          callback: (_) {
            ref.invalidate(mensagensProvider(widget.negociacaoId));
          },
        )
        .subscribe();
  }

  void _abrirChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatSheet(negociacaoId: widget.negociacaoId),
    );
  }

  void _abrirAvaliacao() {
    showDialog(
      context: context,
      builder: (_) => _AvaliacaoDialog(negociacaoId: widget.negociacaoId),
    );
  }

  Future<void> _atualizarMesa(
      List<String> itensA, List<String> itensB) async {
    setState(() => _enviando = true);
    try {
      await ref.read(apiClientProvider).post(
        '/negociacoes/${widget.negociacaoId}/mesa',
        data: {'itens_a': itensA, 'itens_b': itensB},
      );
      ref.invalidate(negociacaoDetalheProvider(widget.negociacaoId));
      ref.invalidate(minhasNegociacoesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falhou: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _aceitar() async {
    setState(() => _enviando = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/negociacoes/${widget.negociacaoId}/aceitar');
      ref.invalidate(negociacaoDetalheProvider(widget.negociacaoId));
      ref.invalidate(minhasNegociacoesProvider);
      ref.invalidate(meusLotesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aceite falhou: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalhe = ref.watch(negociacaoDetalheProvider(widget.negociacaoId));

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: GlassAppBar(
        title: const Text('Mesa de negociação'),
        actions: [
          IconButton(
            tooltip: 'Chat',
            onPressed: _abrirChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton(
            onPressed: () =>
                ref.invalidate(negociacaoDetalheProvider(widget.negociacaoId)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: detalhe.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (d) => _buildMesa(d),
      ),
    );
  }

  Widget _buildMesa(NegociacaoDetalhe d) {
    final n = d.negociacao;
    final meuLado = d.meuLado;
    final souA = meuLado == 'a';

    final meusItensDisp = souA ? d.itensA : d.itensB;
    final outrosItensDisp = souA ? d.itensB : d.itensA;
    final meusItensMesa = souA ? n.itensA : n.itensB;
    final outrosItensMesa = souA ? n.itensB : n.itensA;
    final meuValor = souA ? n.valorA : n.valorB;
    final outroValor = souA ? n.valorB : n.valorA;

    final tornaDoMeuLado = outroValor - meuValor; // > 0 = recebo mais valor, pago a torna
    final aceiteMeu = souA ? n.aceiteA : n.aceiteB;
    final aceiteOutro = souA ? n.aceiteB : n.aceiteA;

    final meuLote = souA ? d.loteA : d.loteB;
    final outroLote = souA ? d.loteB : d.loteA;

    return Column(
      children: [
        _statusBar(n, tornaDoMeuLado, aceiteMeu, aceiteOutro),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ladoColumn(
                  titulo: 'Meu lote',
                  subtitulo: meuLote.titulo,
                  cor: AppColors.success,
                  itensMesa: meusItensMesa,
                  itensDisp: meusItensDisp,
                  valor: meuValor,
                  meuLado: true,
                  onAdd: (id) {
                    final novos = [...meusItensMesa, id];
                    if (souA) {
                      _atualizarMesa(novos, outrosItensMesa);
                    } else {
                      _atualizarMesa(outrosItensMesa, novos);
                    }
                  },
                  onRemove: (id) {
                    final novos = [...meusItensMesa]..remove(id);
                    if (souA) {
                      _atualizarMesa(novos, outrosItensMesa);
                    } else {
                      _atualizarMesa(outrosItensMesa, novos);
                    }
                  },
                ),
              ),
              Container(width: 1, color: Colors.black.withValues(alpha: 0.08)),
              Expanded(
                child: _ladoColumn(
                  titulo: 'Lote de ${outroLote.donoNome}',
                  subtitulo: outroLote.titulo,
                  cor: AppColors.primary,
                  itensMesa: outrosItensMesa,
                  itensDisp: outrosItensDisp,
                  valor: outroValor,
                  meuLado: false,
                  onAdd: (id) {
                    final novos = [...outrosItensMesa, id];
                    if (souA) {
                      _atualizarMesa(meusItensMesa, novos);
                    } else {
                      _atualizarMesa(novos, meusItensMesa);
                    }
                  },
                  onRemove: (id) {
                    final novos = [...outrosItensMesa]..remove(id);
                    if (souA) {
                      _atualizarMesa(meusItensMesa, novos);
                    } else {
                      _atualizarMesa(novos, meusItensMesa);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        _bottomBar(n, aceiteMeu),
      ],
    );
  }

  Widget _statusBar(
      Negociacao n, double tornaDoMeuLado, bool aceiteMeu, bool aceiteOutro) {
    final tornaTexto = tornaDoMeuLado == 0
        ? 'Troca par — sem torna'
        : tornaDoMeuLado > 0
            ? 'Você pagaria ${brl(tornaDoMeuLado)} de torna'
            : 'Você receberia ${brl(tornaDoMeuLado.abs())} de torna';
    final tornaCor = tornaDoMeuLado == 0
        ? AppColors.muted
        : tornaDoMeuLado > 0
            ? AppColors.primary
            : AppColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(color: AppColors.ink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.scale_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(tornaTexto,
                  style: TextStyle(
                    color: tornaCor == AppColors.muted ? Colors.white : tornaCor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  )),
              const Spacer(),
              _aceiteIndicador('Eu', aceiteMeu),
              const SizedBox(width: 6),
              _aceiteIndicador('Outro', aceiteOutro),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('v${n.versao}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Text('status: ${n.statusTexto}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aceiteIndicador(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? AppColors.success : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_rounded : Icons.hourglass_empty_rounded,
              size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _ladoColumn({
    required String titulo,
    required String subtitulo,
    required Color cor,
    required List<String> itensMesa,
    required List<ItemMini> itensDisp,
    required double valor,
    required bool meuLado,
    required void Function(String id) onAdd,
    required void Function(String id) onRemove,
  }) {
    final mapaDisp = {for (final i in itensDisp) i.id: i};
    final naMesa =
        itensMesa.map((id) => mapaDisp[id]).whereType<ItemMini>().toList();
    final fora = itensDisp.where((i) => !itensMesa.contains(i.id)).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cor.withValues(alpha: 0.9), cor],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
                Text(subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Na mesa: ${brl(valor)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                if (naMesa.isEmpty)
                  _hint('Arraste itens daqui pra mesa →')
                else
                  ...naMesa.map((it) => _itemTile(it, true, onRemove)),
                const SizedBox(height: 14),
                _separador('Fora da mesa'),
                const SizedBox(height: 6),
                if (fora.isEmpty)
                  _hint('—')
                else
                  ...fora.map((it) => _itemTile(it, false, onAdd)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(ItemMini it, bool naMesa, void Function(String) onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: naMesa
            ? AppColors.success.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: naMesa
              ? AppColors.success.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          if (it.fotos.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                it.fotos.first,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbFallback(),
              ),
            )
          else
            _thumbFallback(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                Text(brl(it.valorReferencia),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _enviando ? null : () => onPressed(it.id),
            icon: Icon(
              naMesa ? Icons.remove_rounded : Icons.add_rounded,
              size: 18,
              color: naMesa ? AppColors.primary : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.image_rounded, size: 16, color: AppColors.muted),
      );

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(t,
            style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
      );

  Widget _separador(String label) => Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.black.withValues(alpha: 0.08))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
          Expanded(child: Container(height: 1, color: Colors.black.withValues(alpha: 0.08))),
        ],
      );

  Widget _bottomBar(Negociacao n, bool aceiteMeu) {
    final aceita = n.statusTexto == 'aceita';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: aceita
            ? Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success),
                        SizedBox(width: 8),
                        Text('Troca aceita pelos dois lados!',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _abrirAvaliacao,
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Avaliar a troca'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentDeep,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _enviando || aceiteMeu ? null : _aceitar,
                      icon: Icon(aceiteMeu
                          ? Icons.hourglass_empty_rounded
                          : Icons.check_rounded),
                      label: Text(aceiteMeu
                          ? 'Aceito — esperando o outro'
                          : 'Aceitar como está'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            aceiteMeu ? AppColors.muted : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ChatSheet extends ConsumerStatefulWidget {
  const _ChatSheet({required this.negociacaoId});
  final String negociacaoId;

  @override
  ConsumerState<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<_ChatSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _enviando = true);
    try {
      await ref.read(apiClientProvider).post(
        '/negociacoes/${widget.negociacaoId}/mensagens',
        data: {'texto': t},
      );
      _ctrl.clear();
      ref.invalidate(mensagensProvider(widget.negociacaoId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falhou: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(mensagensProvider(widget.negociacaoId));
    final dev = ref.watch(devSessionProvider);
    final supabase = ref.watch(supabaseClientProvider);
    final meuUid = dev?.userId ?? supabase.auth.currentUser?.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => GlassSheet(
        child: Column(
          children: [
            GlassSheet.handle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Chat da negociação',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: msgs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Nenhuma mensagem ainda.\nManda a primeira pra quebrar o gelo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    }
                  });
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final m = data[i];
                      final eu = m.senderId == meuUid;
                      return Align(
                        alignment:
                            eu ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.7),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: eu
                                ? AppColors.primary
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(eu ? 14 : 4),
                              bottomRight: Radius.circular(eu ? 4 : 14),
                            ),
                          ),
                          child: Text(
                            m.texto,
                            style: TextStyle(
                              color: eu ? Colors.white : AppColors.ink,
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(
                        hintText: 'Mensagem...',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _enviando ? null : _enviar,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Icon(Icons.send_rounded, size: 20),
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

class _AvaliacaoDialog extends ConsumerStatefulWidget {
  const _AvaliacaoDialog({required this.negociacaoId});
  final String negociacaoId;

  @override
  ConsumerState<_AvaliacaoDialog> createState() => _AvaliacaoDialogState();
}

class _AvaliacaoDialogState extends ConsumerState<_AvaliacaoDialog> {
  int _nota = 5;
  final _coment = TextEditingController();
  bool _enviando = false;
  String? _err;

  @override
  void dispose() {
    _coment.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _err = null;
    });
    try {
      await ref.read(apiClientProvider).post('/avaliacoes', data: {
        'negociacao_id': widget.negociacaoId,
        'nota': _nota,
        'comentario': _coment.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obrigado pela avaliação! ⭐')),
        );
      }
    } catch (e) {
      setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como foi a troca?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Sua avaliação afeta a reputação pública da pessoa.',
            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final ativa = i < _nota;
              return IconButton(
                onPressed: () => setState(() => _nota = i + 1),
                icon: Icon(
                  ativa ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: ativa ? AppColors.accent : AppColors.muted,
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _coment,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Comentário (opcional)',
            ),
          ),
          if (_err != null)
            Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
