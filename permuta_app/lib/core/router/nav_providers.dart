import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aba atual do AppShell. Quem manipula: a própria bottom bar e qualquer
/// tela que queira navegar (ex: card de setor na Home → Descobrir).
final currentTabProvider = StateProvider<int>((_) => 0);

/// Filtro de setor inicial pra Descoberta. Quando outra tela seta isso e
/// pula pra aba 1, a Descoberta abre já com aquele setor pré-selecionado.
final setorInicialProvider = StateProvider<String?>((_) => null);

/// Índices fixos das abas — fonte única de verdade.
/// Lotes + Itens viraram uma aba só: "Acervo".
class AppTab {
  static const home = 0;
  static const descobrir = 1;
  static const acervo = 2;
  static const negocios = 3;
  static const perfil = 4;
}
