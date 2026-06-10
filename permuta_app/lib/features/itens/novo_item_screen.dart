import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/http/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/glass.dart';

class NovoItemScreen extends ConsumerStatefulWidget {
  const NovoItemScreen({super.key});

  @override
  ConsumerState<NovoItemScreen> createState() => _NovoItemScreenState();
}

class _NovoItemScreenState extends ConsumerState<NovoItemScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  final _camposCtrls = <String, TextEditingController>{};

  String? _setor;
  String? _categoria;

  Uint8List? _fotoBytes;
  String? _fotoUrl;
  bool _uploading = false;

  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _valor.dispose();
    for (final c in _camposCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    setState(() => _err = null);
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await x.readAsBytes();
      _fotoBytes = bytes;

      // Mando pro backend (/dev/upload), que proxia pro Supabase Storage usando
      // a service key. Funciona tanto com dev login quanto com login real.
      final dio = ref.read(apiClientProvider);
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: x.name,
          contentType: DioMediaType.parse(x.mimeType ?? 'image/jpeg'),
        ),
      });
      final r = await dio.post<Map<String, dynamic>>('/dev/upload', data: form);
      _fotoUrl = r.data?['url'] as String?;
      setState(() {});
    } catch (e) {
      setState(() => _err = 'Falha no upload: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_setor == null || _categoria == null) {
      setState(() => _err = 'Escolha setor e categoria');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final campos = <String, dynamic>{
        for (final e in _camposCtrls.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };
      await dio.post('/itens', data: {
        'titulo': _titulo.text.trim(),
        'descricao': _descricao.text.trim().isEmpty
            ? null
            : _descricao.text.trim(),
        'setor_slug': _setor,
        'categoria': _categoria,
        'valor_referencia':
            double.tryParse(_valor.text.replaceAll(',', '.')) ?? 0,
        'fotos': _fotoUrl != null ? [_fotoUrl] : [],
        'campos': campos,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setores = ref.watch(setoresProvider);

    return Scaffold(
      appBar: GlassAppBar(
        title: const Text('Novo item'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _fotoBlock(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título do item',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Mínimo 2 letras' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valor,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor de referência (R\$)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (n == null || n < 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 26),
            const Text('Setor',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            setores.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erro: $e'),
              data: (data) => _setoresWrap(data),
            ),
            if (_setor != null) ...[
              const SizedBox(height: 22),
              const Text('Categoria',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              _categoriasWrap(
                  setores.value?.firstWhere((s) => s.slug == _setor).categorias ??
                      const []),
              const SizedBox(height: 22),
              _camposExtras(setores.value!.firstWhere((s) => s.slug == _setor)),
            ],
            if (_err != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_err!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _loading ? null : _salvar,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Criar item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoBlock() {
    return InkWell(
      onTap: _uploading ? null : _pickAndUpload,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.gradCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _fotoBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(_fotoBytes!, fit: BoxFit.cover),
                  ),
                  if (_uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'Trocar foto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded,
                      size: 40, color: AppColors.primary),
                  const SizedBox(height: 8),
                  const Text(
                    'Adicionar foto',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'jpeg, png ou webp até 5 MB',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _setoresWrap(List<Setor> data) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: data.map((s) {
        final sel = _setor == s.slug;
        return InkWell(
          onTap: () {
            setState(() {
              _setor = s.slug;
              _categoria = null;
              _camposCtrls.clear();
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: sel ? AppColors.gradientFromHex(s.cor) : null,
              color: sel ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? Colors.transparent : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.icone, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  s.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _categoriasWrap(List<String> cats) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.map((c) {
        final sel = _categoria == c;
        return InkWell(
          onTap: () => setState(() => _categoria = c),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.ink : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: sel ? AppColors.ink : Colors.black.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              c,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : AppColors.ink,
                  fontSize: 13),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _camposExtras(Setor s) {
    // s.categorias é apenas a lista; campos_extras está no JSON original.
    // Pra simplificar nesta rodada, deduzo campos por setor.
    final extras = _camposPorSetor[s.slug] ?? const <String, String>{};
    if (extras.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detalhes',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        ...extras.entries.map((e) {
          final ctrl =
              _camposCtrls.putIfAbsent(e.key, () => TextEditingController());
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: '${e.key} ${e.value.isNotEmpty ? "(${e.value})" : ""}',
              ),
            ),
          );
        }),
      ],
    );
  }

  static const _camposPorSetor = <String, Map<String, String>>{
    'esportivo': {'tamanho': '', 'marca': '', 'estado': 'novo/usado'},
    'automoveis': {'ano': '', 'km': '', 'cambio': 'manual/automatico', 'combustivel': ''},
    'eletronicos': {'marca': '', 'modelo': '', 'ano': '', 'estado': 'novo/seminovo/usado'},
    'instrumentos': {'marca': '', 'cordas': '', 'estado': 'novo/usado'},
    'imoveis': {'metragem': 'm²', 'quartos': '', 'vagas': '', 'cidade': ''},
  };
}
