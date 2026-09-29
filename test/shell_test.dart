import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/src/shell/nettia_shell.dart';
import 'package:nettia_core/nettia_core.dart';

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

/// Avanza la animación en varios cuadros (el fondo tiene animación infinita,
/// así que `pumpAndSettle` no termina nunca).
Future<void> _avanzar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _abrirModulo(WidgetTester tester, String titulo) async {
  await tester.tap(find.byTooltip('Menú'));
  await _avanzar(tester);
  await tester.tap(find.text(titulo));
  await _avanzar(tester);
}

void main() {
  testWidgets('cada módulo del menú muestra su propia pantalla', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: NettiaShell(aiService: _FakeAi()),
      ),
    );
    await _avanzar(tester);

    // Módulo 0: calculadora (y solo la calculadora).
    expect(find.text('Cálculo de Red, Máscara y Gateway'), findsOneWidget);
    expect(find.text('Switch (VLANs)'), findsNothing);

    await _abrirModulo(tester, 'Comandos CLI & Plantillas');
    expect(find.text('Switch (VLANs)'), findsOneWidget);
    expect(find.text('Cálculo de Red, Máscara y Gateway'), findsNothing);

    await _abrirModulo(tester, 'Asistente NETIA');
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Switch (VLANs)'), findsNothing);

    await _abrirModulo(tester, 'Guía Metodológica');
    expect(find.textContaining('Configura de abajo hacia arriba'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
