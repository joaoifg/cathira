import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/glass.dart';

class NovoLoteScreen extends ConsumerStatefulWidget {
  const NovoLoteScreen({super.key});

  @override
  ConsumerState<NovoLoteScreen> createState() => _NovoLoteScreenState();
}

class _NovoLoteScreenState extends ConsumerState<NovoLoteScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _faixaMin = TextEditingController();
  final _faixaMax = TextEditingController();
  String? _setor;
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _titulo.dispose();
    _faixaMin.dispose();
    _faixaMax.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_setor == null) {
      setState(() => _err = 'Escolha um setor');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/lotes', data: {
        'titulo': _titulo.text.trim(),
        'setor_principal': _setor,
        if (_faixaMin.text.isNotEmpty)
          'faixa_alvo_min': double.tryParse(_faixaMin.text.replaceAll(',', '.')),
        if (_faixaMax.text.isNotEmpty)
          'faixa_alvo_max': double.tryParse(_faixaMax.text.replaceAll(',', '.')),
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
        title: const Text('Novo lote'),
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
            const Text(
              'Dá um título pro lote.',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Algo curto que descreva a cesta — "Setup gamer", "Carro + bike", etc.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título do lote',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Mínimo 2 letras' : null,
            ),
            const SizedBox(height: 26),
            const Text(
              'Em qual setor?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Determina os campos disponíveis e quem vai ver seu lote.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            setores.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erro: $e'),
              data: (data) => _setoresGrid(data),
            ),
            const SizedBox(height: 28),
            const Text(
              'Faixa de valor que aceitaria receber (opcional).',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ajuda o sistema a sugerir lotes próximos do seu valor.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _faixaMin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'De (R\$)',
                      prefixIcon: Icon(Icons.arrow_downward_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _faixaMax,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Até (R\$)',
                      prefixIcon: Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ),
              ],
            ),
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
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loading ? null : _salvar,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Criar lote'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setoresGrid(List<Setor> data) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: data.map((s) {
        final sel = _setor == s.slug;
        final cor = AppColors.colorFromHex(s.cor);
        return InkWell(
          onTap: () => setState(() => _setor = s.slug),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: sel ? AppColors.gradientFromHex(s.cor) : null,
              color: sel ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel ? Colors.transparent : Colors.black.withValues(alpha: 0.1),
                width: 1.4,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: cor.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.icone, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  s.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
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
}
