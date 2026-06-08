import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'env.dart';

/// Override persistente de [Env.apiBaseUrl] para resolver o problema clássico
/// de dev login num device físico (iPhone, Android real): o app foi buildado
/// com uma `API_BASE_URL` fixa que aponta pra `localhost`/`10.0.2.2`, mas
/// no device esses hostnames não resolvem o servidor da máquina dev.
///
/// O usuário cola o IP da LAN (ex.: http://192.168.1.10:8080) e fica salvo.

const _kPrefsKey = 'cathira.api_base_url_override';

class ApiUrlOverrideNotifier extends StateNotifier<String?> {
  ApiUrlOverrideNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_kPrefsKey);
      if (v != null && v.isNotEmpty) state = v;
    } catch (_) {/* SharedPreferences pode falhar em casos extremos */}
  }

  Future<void> set(String? value) async {
    final v = value?.trim();
    final normalized = (v == null || v.isEmpty) ? null : v;
    state = normalized;
    try {
      final p = await SharedPreferences.getInstance();
      if (normalized == null) {
        await p.remove(_kPrefsKey);
      } else {
        await p.setString(_kPrefsKey, normalized);
      }
    } catch (_) {}
  }
}

final apiUrlOverrideProvider =
    StateNotifierProvider<ApiUrlOverrideNotifier, String?>(
  (_) => ApiUrlOverrideNotifier(),
);

/// URL efetiva: usa o override se setado, senão o de [Env.apiBaseUrl].
final effectiveApiBaseUrlProvider = Provider<String>((ref) {
  final override = ref.watch(apiUrlOverrideProvider);
  return (override != null && override.isNotEmpty)
      ? override
      : Env.apiBaseUrl;
});
