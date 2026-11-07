import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/src/shell/nettia_shell.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'soporte/instantanea.dart';

/// Barra superior del shell (separada de build el 2026-11-06 para el gate de
/// SPEC-005): aspecto fijado con instantáneas y comportamiento de sus botones.
///
///   Escenario: sin IA lista, el botón de Configuración no lleva punto
///   Escenario: con API Key o en modo offline, lleva el punto verde
///   Escenario: Menú abre el menú lateral y Configuración abre Ajustes
class _FakeAi implements AiDiagnosisService {
  @override
  void cancelarStream() {}

  @override
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'General',
  }) =>
      const Stream<String>.empty();
}

Future<void> _avanzar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: NetworkTheme.darkTheme, home: NettiaShell(aiService: _FakeAi())),
  );
  await _avanzar(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ai = AiSettingsService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await ai.load();
    await ai.setActiveProvider(AiProviderType.openRouter);
    await ai.setApiKey(AiProviderType.openRouter, '');
  });

  testWidgets('sin IA lista, el botón de Configuración no lleva punto', (tester) async {
    await _montar(tester);
    expectInstantanea(instantanea(tester, find.byType(AppBar)), 'shell_barra_sin_ia');
    expect(find.byTooltip('Menú'), findsOneWidget);
    expect(find.byTooltip('Configuración & Sistema'), findsOneWidget);
  });

  testWidgets('con API Key lleva el punto verde', (tester) async {
    await ai.setApiKey(AiProviderType.openRouter, 'k-1');
    await _montar(tester);
    expectInstantanea(instantanea(tester, find.byType(AppBar)), 'shell_barra_con_ia');
  });

  testWidgets('en modo offline también lleva el punto verde', (tester) async {
    await ai.setActiveProvider(AiProviderType.offline);
    await _montar(tester);
    final punto = find.descendant(
      of: find.byTooltip('Configuración & Sistema'),
      matching: find.byType(Container),
    );
    expect(punto, findsOneWidget);
  });

  testWidgets('Menú abre el menú lateral y Configuración abre Ajustes', (tester) async {
    await _montar(tester);
    await tester.tap(find.byTooltip('Menú'));
    await _avanzar(tester);
    expect(find.byType(Drawer), findsOneWidget);
    await tester.tapAt(const Offset(780, 300));
    await _avanzar(tester);
    await tester.tap(find.byTooltip('Configuración & Sistema'));
    await _avanzar(tester);
    expect(find.byType(NetworkSettingsScreen), findsOneWidget);
  });

  testWidgets('el logo de la barra mide 22 y usa los colores del tema', (tester) async {
    await _montar(tester);
    final logo = tester.widget<NettiaLogo>(
      find.descendant(of: find.byType(AppBar), matching: find.byType(NettiaLogo)),
    );
    final tema = NetworkTheme.darkTheme;
    expect(logo.size, 22);
    expect(logo.color, tema.textTheme.bodyLarge!.color);
    expect(logo.accent, tema.colorScheme.primary);
    expect(logo.accent2, tema.colorScheme.tertiary);
  });
}
