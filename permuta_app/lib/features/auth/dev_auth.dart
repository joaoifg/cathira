import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env/api_url_override.dart';
import '../../core/supabase/supabase_providers.dart';

class DevSession {
  const DevSession({
    required this.token,
    required this.userId,
    required this.nome,
    required this.email,
  });
  final String token;
  final String userId;
  final String nome;
  final String email;
}

/// Sessão fake mantida em memória. Quando != null, o app considera o usuário
/// logado e o Dio interceptor manda esse token em vez do JWT do Supabase.
final devSessionProvider = StateProvider<DevSession?>((_) => null);

/// Bate em POST /dev/login (sem auth) e guarda o token no provider.
class DevAuthController {
  DevAuthController(this.ref);
  final Ref ref;

  Future<void> login({String nome = 'Dev User', String? email}) async {
    final baseUrl = ref.read(effectiveApiBaseUrlProvider);
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    final r = await dio.post('/dev/login', data: {
      'nome': nome,
      if (email != null) 'email': email,
    });
    final data = r.data as Map<String, dynamic>;
    final token = data['token'] as String;
    ref.read(devSessionProvider.notifier).state = DevSession(
      token: token,
      userId: data['user_id'] as String,
      nome: (data['nome'] as String?) ?? nome,
      email: (data['email'] as String?) ?? '',
    );

    // Injeta o token no cliente Realtime do Supabase pra autenticar o WS
    // (o cliente Supabase só sabe da sessão Auth dele — não da nossa).
    ref.read(supabaseClientProvider).realtime.setAuth(token);
  }

  void logout() {
    ref.read(devSessionProvider.notifier).state = null;
    // ignore: avoid_dynamic_calls
    ref.read(supabaseClientProvider).realtime.setAuth(null);
  }
}

final devAuthControllerProvider =
    Provider<DevAuthController>((ref) => DevAuthController(ref));
