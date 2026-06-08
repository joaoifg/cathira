import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_providers.dart';
import '../../features/auth/dev_auth.dart';
import '../../features/auth/login_screen.dart';
import 'app_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devSession = ref.watch(devSessionProvider);
    if (devSession != null) {
      return const AppShell();
    }

    final session = ref.watch(authSessionProvider);
    return session.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Auth erro: $e'))),
      data: (s) => s == null ? const LoginScreen() : const AppShell(),
    );
  }
}
