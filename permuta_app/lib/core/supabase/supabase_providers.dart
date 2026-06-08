import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

/// Sessão atual (null se deslogado). Emite toda vez que muda o auth state.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((e) => e.session).distinct();
});

/// Atalho síncrono: existe sessão agora?
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentSession != null;
});
