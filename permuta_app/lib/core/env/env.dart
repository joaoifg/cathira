/// Configuração injetada via --dart-define.
///
/// Para rodar:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8080
///
/// 10.0.2.2 = localhost da máquina vista do emulador Android.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Liga o botão "Entrar como dev" na tela de login.
  /// Passar via: --dart-define=DEV_MODE=true
  static const devMode =
      bool.fromEnvironment('DEV_MODE', defaultValue: false);

  static bool get ok =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
