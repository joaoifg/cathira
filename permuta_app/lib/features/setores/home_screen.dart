import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/nav_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/brl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setores = ref.watch(setoresProvider);
    final lotes = ref.watch(meusLotesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(setoresProvider);
            ref.invalidate(meusLotesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              _heroBanner(context),
              const SizedBox(height: 20),
              _statsRow(context, lotes),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Text('Setores',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    const Spacer(),
                    Text(
                      'O que você tem pra trocar?',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              setores.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _errorBox('Erro carregando setores: $e'),
                data: (data) => _setorGrid(context, data),
              ),
              const SizedBox(height: 32),
              _comoFunciona(context),
              const SizedBox(height: 24),
              _ctaCriar(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.gradHero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.36),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Círculo decorativo no canto pra dar profundidade.
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1),
                    ),
                    child: const Text(
                      '🔥  Marketplace de permuta',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Junta tudo num lote.\nA gente equaliza o resto.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1.1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Carro + bike + console? Tudo numa cesta só. '
                    'Se o lote da outra pessoa vale mais, o app calcula a torna.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 13.5,
                      height: 1.5,
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

  Widget _statsRow(BuildContext context, AsyncValue<List<Lote>> lotes) {
    final list = lotes.value ?? const <Lote>[];
    final totalValor =
        list.fold<double>(0, (a, l) => a + l.valorTotal);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _statCard('Meus lotes', list.length.toString(),
                Icons.inventory_2_rounded, AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard('Valor total', brl(totalValor),
                Icons.attach_money_rounded, AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cor.withValues(alpha: 0.18), cor.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _setorGrid(BuildContext context, List<Setor> data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('Nenhum setor disponível.')),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
        ),
        itemCount: data.length,
        itemBuilder: (ctx, i) => _SetorCard(setor: data[i]),
      ),
    );
  }

  Widget _comoFunciona(BuildContext context) {
    final passos = [
      ('1', '📦', 'Monta um lote', 'Cesta com 1, 2 ou 10 itens — você decide'),
      ('2', '👀', 'Recebe sugestões', 'Outros lotes na sua faixa de valor'),
      ('3', '⚖️', 'Mesa de negociação', 'Itens entram e saem, torna recalcula ao vivo'),
      ('4', '🤝', 'Aceita e fecha', 'Os dois confirmam, troca virou compromisso'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.gradCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Como funciona',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            ...passos.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(p.$2, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.$3,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                            Text(p.$4,
                                style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.5,
                                    height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _ctaCriar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () =>
            ref.read(currentTabProvider.notifier).state = AppTab.lotes,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pronto pra trocar?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cria seu primeiro lote agora',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(msg, style: const TextStyle(color: Colors.red)),
        ),
      );
}

class _SetorCard extends ConsumerWidget {
  const _SetorCard({required this.setor});
  final Setor setor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cor = AppColors.colorFromHex(setor.cor);
    final grad = AppColors.gradientFromHex(setor.cor);
    return InkWell(
      onTap: () {
        ref.read(setorInicialProvider.notifier).state = setor.slug;
        ref.read(currentTabProvider.notifier).state = AppTab.descobrir;
      },
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          gradient: grad,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Halo decorativo
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -10,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(setor.icone,
                          style: const TextStyle(fontSize: 28)),
                    ),
                    const Spacer(),
                    Text(
                      setor.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (setor.tagline != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          setor.tagline!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
}
