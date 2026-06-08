import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/api_url_override.dart';
import '../supabase/supabase_providers.dart';
import '../../features/auth/dev_auth.dart';

/// Dio configurado com a base URL da Go API. O interceptor injeta o Bearer:
///   - se houver dev session ativa, manda o token de dev (HS256, criado em /dev/login)
///   - senão, manda o JWT do Supabase Auth (faz refresh se estiver perto de expirar)
final apiClientProvider = Provider<Dio>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final baseUrl = ref.watch(effectiveApiBaseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final dev = ref.read(devSessionProvider);
        if (dev != null) {
          options.headers['Authorization'] = 'Bearer ${dev.token}';
        } else {
          final token = await _freshToken(supabase);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

Future<String?> _freshToken(SupabaseClient supabase) async {
  final session = supabase.auth.currentSession;
  if (session == null) return null;
  final expiresAt = session.expiresAt;
  if (expiresAt != null) {
    final exp = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    if (DateTime.now().isAfter(exp.subtract(const Duration(seconds: 30)))) {
      final refreshed = await supabase.auth.refreshSession();
      return refreshed.session?.accessToken;
    }
  }
  return session.accessToken;
}
