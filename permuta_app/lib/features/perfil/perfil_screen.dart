import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env/env.dart';
import '../../core/http/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../auth/dev_auth.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/widgets/glass.dart';

class _PersonaChip extends ConsumerWidget {
  const _PersonaChip({required this.nome, required this.email, required this.emoji});
  final String nome;
  final String email;
  final String emoji;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
      label: Text(nome,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      onPressed: () async {
        try {
          await ref.read(devAuthControllerProvider).login(nome: nome, email: email);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logado como $nome')),
            );
          }
          ref.invalidate(meusLotesProvider);
          ref.invalidate(meusItensProvider);
          ref.invalidate(minhasNegociacoesProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Falha: $e')),
            );
          }
        }
      },
    );
  }
}

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _seeding = false;
  bool _seedingMundo = false;
  String? _seedMsg;

  Future<void> _popularDemo() async {
    setState(() {
      _seeding = true;
      _seedMsg = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final r = await dio.post<Map<String, dynamic>>('/dev/seed');
      final data = r.data ?? const {};
      setState(() => _seedMsg =
          '✅ ${data['lotes_criados']} lotes e ${data['itens_criados']} itens criados pra você.');
      ref.invalidate(meusLotesProvider);
      ref.invalidate(meusItensProvider);
    } catch (e) {
      setState(() => _seedMsg = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _popularMundo() async {
    setState(() {
      _seedingMundo = true;
      _seedMsg = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final r = await dio.post<Map<String, dynamic>>('/dev/seed-mundo');
      final data = r.data ?? const {};
      setState(() => _seedMsg =
          '✅ ${data['personas_criadas']} personas com ${data['lotes_criados']} lotes (${data['itens_criados']} itens). Agora vai em "Descobrir"!');
    } catch (e) {
      setState(() => _seedMsg = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _seedingMundo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dev = ref.watch(devSessionProvider);
    final supabase = ref.watch(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    final nome = dev?.nome ?? user?.userMetadata?['nome'] ?? user?.email ?? 'Você';
    final email = dev?.email ?? user?.email ?? '—';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: const Text('Perfil')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, GlassAppBar.alturaTotal(context) + 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradHero,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      nome.toString().isNotEmpty
                          ? nome.toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        email.toString(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (dev != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'sessão de dev',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (Env.devMode) ...[
            const Text('Modo desenvolvimento',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppColors.accentDeep),
                      SizedBox(width: 8),
                      Text(
                        'Popular dados de demonstração',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cria 4 lotes prontos (carro+moto, estúdio, gamer, futebol) '
                    'com 11 itens. Substitui os atuais do mesmo status.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _seeding ? null : _popularDemo,
                    icon: _seeding
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Popular meus lotes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentDeep,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(Icons.public_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Popular o mundo (outros usuários)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cria 3 personas fictícias (Maria, Pedro, Ana) com lotes em automóveis, eletrônicos, '
                    'instrumentos e imóveis. É com elas que você vai poder swipar/negociar.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _seedingMundo ? null : _popularMundo,
                    icon: _seedingMundo
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.travel_explore_rounded),
                    label: const Text('Popular mundo demo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  if (_seedMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(_seedMsg!,
                        style: const TextStyle(fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
          if (Env.devMode) ...[
            const Text('Trocar de persona',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Loga como uma das personas do seed mundo. Útil pra testar match recíproco.',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _PersonaChip(nome: 'Joao Dev', email: 'dev+joao-dev@local.test', emoji: '🧑‍💻'),
                _PersonaChip(nome: 'Maria Souza', email: 'demo+maria@local.test', emoji: '👩'),
                _PersonaChip(nome: 'Pedro Lima', email: 'demo+pedro@local.test', emoji: '🧔'),
                _PersonaChip(nome: 'Ana Pereira', email: 'demo+ana@local.test', emoji: '👩‍🎤'),
              ],
            ),
            const SizedBox(height: 22),
          ],
          OutlinedButton.icon(
            onPressed: () {
              ref.read(devAuthControllerProvider).logout();
              ref.read(supabaseClientProvider).auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
