import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_client.dart';
import '../models/models.dart';

final setoresProvider = FutureProvider<List<Setor>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/setores');
  return ((r.data as List?) ?? const [])
      .map((e) => Setor.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final meusLotesProvider = FutureProvider<List<Lote>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/lotes/meus');
  return ((r.data as List?) ?? const [])
      .map((e) => Lote.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final meusItensProvider = FutureProvider<List<Item>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/itens/meus');
  return ((r.data as List?) ?? const [])
      .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final loteDetalheProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/lotes/$id');
  final data = Map<String, dynamic>.from(r.data as Map);
  return {
    'lote': Lote.fromJson(Map<String, dynamic>.from(data['lote'] as Map)),
    'itens': ((data['itens'] as List?) ?? const [])
        .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  };
});

class DescobertaQuery {
  const DescobertaQuery({this.setor, this.cidade});
  final String? setor;
  final String? cidade;

  @override
  bool operator ==(Object other) =>
      other is DescobertaQuery && other.setor == setor && other.cidade == cidade;

  @override
  int get hashCode => Object.hash(setor, cidade);
}

final descobertaProvider =
    FutureProvider.family<List<Lote>, DescobertaQuery>((ref, q) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/descoberta', queryParameters: {
    if (q.setor != null && q.setor!.isNotEmpty) 'setor': q.setor,
    if (q.cidade != null && q.cidade!.isNotEmpty) 'cidade': q.cidade,
    'limit': 30,
  });
  return ((r.data as List?) ?? const [])
      .map((e) => Lote.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final minhasNegociacoesProvider = FutureProvider<List<Negociacao>>((ref) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/negociacoes');
  return ((r.data as List?) ?? const [])
      .map((e) => Negociacao.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

class NegociacaoDetalhe {
  NegociacaoDetalhe({
    required this.negociacao,
    required this.loteA,
    required this.loteB,
    required this.itensA,
    required this.itensB,
    required this.meuLado,
  });

  final Negociacao negociacao;
  final LoteMini loteA;
  final LoteMini loteB;
  final List<ItemMini> itensA;
  final List<ItemMini> itensB;
  final String meuLado; // 'a' ou 'b'
}

final descobertaItensProvider =
    FutureProvider.family<List<ItemDescoberta>, DescobertaQuery>((ref, q) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/descoberta/itens', queryParameters: {
    if (q.setor != null && q.setor!.isNotEmpty) 'setor': q.setor,
    if (q.cidade != null && q.cidade!.isNotEmpty) 'cidade': q.cidade,
    'limit': 30,
  });
  return ((r.data as List?) ?? const [])
      .map((e) => ItemDescoberta.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final perfilPublicoProvider =
    FutureProvider.family<PerfilPublico, String>((ref, userId) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/perfis/$userId');
  return PerfilPublico.fromJson(Map<String, dynamic>.from(r.data as Map));
});

final mensagensProvider =
    FutureProvider.family<List<Mensagem>, String>((ref, negId) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/negociacoes/$negId/mensagens');
  return ((r.data as List?) ?? const [])
      .map((e) => Mensagem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final negociacaoDetalheProvider =
    FutureProvider.family<NegociacaoDetalhe, String>((ref, id) async {
  final dio = ref.watch(apiClientProvider);
  final r = await dio.get('/negociacoes/$id');
  final d = Map<String, dynamic>.from(r.data as Map);
  return NegociacaoDetalhe(
    negociacao: Negociacao.fromJson(Map<String, dynamic>.from(d['negociacao'] as Map)),
    loteA: LoteMini.fromJson(Map<String, dynamic>.from(d['lote_a'] as Map)),
    loteB: LoteMini.fromJson(Map<String, dynamic>.from(d['lote_b'] as Map)),
    itensA: ((d['itens_a'] as List?) ?? const [])
        .map((e) => ItemMini.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    itensB: ((d['itens_b'] as List?) ?? const [])
        .map((e) => ItemMini.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    meuLado: d['meu_lado'] as String? ?? 'a',
  );
});

/// Atalho pra dar refresh em todos os dados depois de uma mutation.
void invalidateData(Ref ref) {
  ref.invalidate(meusLotesProvider);
  ref.invalidate(meusItensProvider);
}

void invalidateDataFromWidget(WidgetRef ref) {
  ref.invalidate(meusLotesProvider);
  ref.invalidate(meusItensProvider);
}
