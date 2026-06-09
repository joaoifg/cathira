// Espelha as estruturas JSON da Go API. Mantemos como classes simples
// (sem json_serializable) — o app é pequeno e as formas tendem a mudar.

class Setor {
  Setor({
    required this.slug,
    required this.nome,
    required this.icone,
    required this.cor,
    required this.categorias,
    this.tagline,
  });

  final String slug;
  final String nome;
  final String icone;
  final String cor; // hex sem alpha, com #
  final List<String> categorias;
  final String? tagline;

  factory Setor.fromJson(Map<String, dynamic> j) => Setor(
        slug: j['slug'] as String,
        nome: j['nome'] as String,
        icone: (j['icone'] as String?) ?? '📦',
        cor: (j['cor'] as String?) ?? '#FF5722',
        categorias: ((j['categorias'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        tagline: j['tagline'] as String?,
      );
}

class Lote {
  Lote({
    required this.id,
    required this.titulo,
    required this.setorPrincipal,
    required this.valorTotal,
    required this.status,
    this.donoId,
    this.faixaAlvoMin,
    this.faixaAlvoMax,
    this.cidade,
    this.donoNome,
    this.donoCidade,
    this.donoReputacao = 0,
    this.numItens = 0,
    this.capa,
    this.fotos = const [],
  });

  final String id;
  final String titulo;
  final String setorPrincipal;
  final double valorTotal;
  final double? faixaAlvoMin;
  final double? faixaAlvoMax;
  final String? cidade;
  final String status;
  final String? donoId; // pra abrir o perfil público do dono no tap
  final String? donoNome;
  final String? donoCidade;
  final double donoReputacao;
  final int numItens;
  final String? capa;
  final List<String> fotos;

  factory Lote.fromJson(Map<String, dynamic> j) => Lote(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        setorPrincipal: j['setor_principal'] as String,
        valorTotal: (j['valor_total'] as num?)?.toDouble() ?? 0,
        faixaAlvoMin: (j['faixa_alvo_min'] as num?)?.toDouble(),
        faixaAlvoMax: (j['faixa_alvo_max'] as num?)?.toDouble(),
        cidade: j['cidade'] as String?,
        status: j['status'] as String? ?? 'aberto',
        donoId: j['dono_id'] as String?,
        donoNome: j['dono_nome'] as String?,
        donoCidade: j['dono_cidade'] as String?,
        donoReputacao: (j['dono_reputacao'] as num?)?.toDouble() ?? 0,
        numItens: (j['num_itens'] as num?)?.toInt() ?? 0,
        capa: j['capa'] as String?,
        fotos: ((j['fotos'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class Mensagem {
  Mensagem({
    required this.id,
    required this.senderId,
    required this.texto,
    required this.tipo,
    required this.criadoEm,
  });

  final String id;
  final String senderId;
  final String texto;
  final String tipo;
  final DateTime criadoEm;

  factory Mensagem.fromJson(Map<String, dynamic> j) => Mensagem(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        texto: j['texto'] as String? ?? '',
        tipo: j['tipo'] as String? ?? 'texto',
        criadoEm: DateTime.tryParse(j['criado_em']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class Negociacao {
  Negociacao({
    required this.id,
    required this.loteA,
    required this.loteB,
    required this.uidA,
    required this.uidB,
    required this.itensA,
    required this.itensB,
    required this.valorA,
    required this.valorB,
    required this.torna,
    required this.aceiteA,
    required this.aceiteB,
    required this.statusTexto,
    required this.versao,
    this.quemPaga,
  });

  final String id;
  final String loteA;
  final String loteB;
  final String uidA;
  final String uidB;
  final List<String> itensA;
  final List<String> itensB;
  final double valorA;
  final double valorB;
  final double torna;
  final String? quemPaga;
  final bool aceiteA;
  final bool aceiteB;
  final String statusTexto;
  final int versao;

  factory Negociacao.fromJson(Map<String, dynamic> j) => Negociacao(
        id: j['id'] as String,
        loteA: j['lote_a'] as String,
        loteB: j['lote_b'] as String,
        uidA: j['uid_a'] as String,
        uidB: j['uid_b'] as String,
        itensA: ((j['itens_a'] as List?) ?? const []).map((e) => e.toString()).toList(),
        itensB: ((j['itens_b'] as List?) ?? const []).map((e) => e.toString()).toList(),
        valorA: (j['valor_a'] as num?)?.toDouble() ?? 0,
        valorB: (j['valor_b'] as num?)?.toDouble() ?? 0,
        torna: (j['torna'] as num?)?.toDouble() ?? 0,
        quemPaga: j['quem_paga'] as String?,
        aceiteA: j['aceite_a'] as bool? ?? false,
        aceiteB: j['aceite_b'] as bool? ?? false,
        statusTexto: j['status'] as String? ?? 'proposta',
        versao: (j['versao'] as num?)?.toInt() ?? 1,
      );
}

class ItemMini {
  ItemMini({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.valorReferencia,
    required this.loteId,
    this.fotos = const [],
  });

  final String id;
  final String titulo;
  final String categoria;
  final double valorReferencia;
  final String loteId;
  final List<String> fotos;

  factory ItemMini.fromJson(Map<String, dynamic> j) => ItemMini(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        categoria: j['categoria'] as String,
        valorReferencia: (j['valor_referencia'] as num?)?.toDouble() ?? 0,
        loteId: j['lote_id'] as String,
        fotos: ((j['fotos'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

class LoteMini {
  LoteMini({
    required this.id,
    required this.titulo,
    required this.donoId,
    required this.donoNome,
    required this.setorPrincipal,
  });

  final String id;
  final String titulo;
  final String donoId;
  final String donoNome;
  final String setorPrincipal;

  factory LoteMini.fromJson(Map<String, dynamic> j) => LoteMini(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        donoId: j['dono_id'] as String,
        donoNome: j['dono_nome'] as String? ?? '—',
        setorPrincipal: j['setor_principal'] as String,
      );
}

/// Perfil simplificado do dono (subset de profiles).
class PerfilDono {
  PerfilDono({
    required this.id,
    required this.nome,
    required this.reputacao,
    required this.numTrocas,
    this.fotoUrl,
    this.cidade,
  });

  final String id;
  final String nome;
  final String? fotoUrl;
  final String? cidade;
  final double reputacao;
  final int numTrocas;

  factory PerfilDono.fromJson(Map<String, dynamic> j) => PerfilDono(
        id: j['id'] as String,
        nome: j['nome'] as String? ?? '—',
        fotoUrl: j['foto_url'] as String?,
        cidade: j['cidade'] as String?,
        reputacao: (j['reputacao'] as num?)?.toDouble() ?? 0,
        numTrocas: (j['num_trocas'] as num?)?.toInt() ?? 0,
      );
}

/// Lote resumido pra mostrar na página pública.
class LoteMiniPub {
  LoteMiniPub({
    required this.id,
    required this.titulo,
    required this.setorPrincipal,
    required this.valorTotal,
    required this.numItens,
    this.capa,
  });

  final String id;
  final String titulo;
  final String setorPrincipal;
  final double valorTotal;
  final int numItens;
  final String? capa;

  factory LoteMiniPub.fromJson(Map<String, dynamic> j) => LoteMiniPub(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        setorPrincipal: j['setor_principal'] as String,
        valorTotal: (j['valor_total'] as num?)?.toDouble() ?? 0,
        numItens: (j['num_itens'] as num?)?.toInt() ?? 0,
        capa: j['capa'] as String?,
      );
}

/// Item público (com info do lote se pertencer a algum).
class ItemPub {
  ItemPub({
    required this.id,
    required this.titulo,
    required this.setorSlug,
    required this.categoria,
    required this.valorReferencia,
    required this.fotos,
    this.descricao,
    this.loteId,
    this.loteTitulo,
  });

  final String id;
  final String titulo;
  final String? descricao;
  final List<String> fotos;
  final String setorSlug;
  final String categoria;
  final double valorReferencia;
  final String? loteId;
  final String? loteTitulo;

  factory ItemPub.fromJson(Map<String, dynamic> j) => ItemPub(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        descricao: j['descricao'] as String?,
        fotos: ((j['fotos'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        setorSlug: j['setor_slug'] as String,
        categoria: j['categoria'] as String,
        valorReferencia: (j['valor_referencia'] as num?)?.toDouble() ?? 0,
        loteId: j['lote_id'] as String?,
        loteTitulo: j['lote_titulo'] as String?,
      );
}

class AvaliacaoPub {
  AvaliacaoPub({required this.nota, required this.deNome, this.comentario});
  final int nota;
  final String deNome;
  final String? comentario;

  factory AvaliacaoPub.fromJson(Map<String, dynamic> j) => AvaliacaoPub(
        nota: (j['nota'] as num).toInt(),
        deNome: j['de_nome'] as String? ?? '—',
        comentario: j['comentario'] as String?,
      );
}

class PerfilPublico {
  PerfilPublico({
    required this.perfil,
    required this.itens,
    required this.lotes,
    required this.avaliacoes,
  });

  final PerfilDono perfil;
  final List<ItemPub> itens;
  final List<LoteMiniPub> lotes;
  final List<AvaliacaoPub> avaliacoes;

  factory PerfilPublico.fromJson(Map<String, dynamic> j) => PerfilPublico(
        perfil: PerfilDono.fromJson(
            Map<String, dynamic>.from(j['perfil'] as Map)),
        itens: ((j['itens'] as List?) ?? const [])
            .map((e) => ItemPub.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        lotes: ((j['lotes'] as List?) ?? const [])
            .map((e) =>
                LoteMiniPub.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        avaliacoes: ((j['avaliacoes'] as List?) ?? const [])
            .map((e) =>
                AvaliacaoPub.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class Item {
  Item({
    required this.id,
    required this.titulo,
    required this.setorSlug,
    required this.categoria,
    required this.valorReferencia,
    required this.fotos,
    this.descricao,
    this.loteId,
    this.campos = const {},
  });

  final String id;
  final String titulo;
  final String? descricao;
  final List<String> fotos;
  final String setorSlug;
  final String categoria;
  final double valorReferencia;
  final String? loteId;
  final Map<String, dynamic> campos;

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        descricao: j['descricao'] as String?,
        fotos: ((j['fotos'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        setorSlug: j['setor_slug'] as String,
        categoria: j['categoria'] as String,
        valorReferencia: (j['valor_referencia'] as num?)?.toDouble() ?? 0,
        loteId: j['lote_id'] as String?,
        campos:
            (j['campos'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      );
}
