import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

void main() {
  Future<void> montar(WidgetTester tester, {required bool dark, required bool procesando}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: dark ? NetworkTheme.darkTheme : NetworkTheme.lightTheme,
        home: Scaffold(
          body: NetworkBackdrop(
            isProcessing: procesando,
            child: const Text('contenido'),
          ),
        ),
      ),
    );
  }

  testWidgets('siempre muestra el contenido hijo encima del fondo', (tester) async {
    await montar(tester, dark: true, procesando: false);
    expect(find.text('contenido'), findsOneWidget);
  });

  List<Color> coloresDelFondo(WidgetTester tester) {
    final caja = tester.widgetList<DecoratedBox>(find.descendant(
      of: find.byType(NetworkBackdrop),
      matching: find.byType(DecoratedBox),
    )).map((d) => d.decoration).whereType<BoxDecoration>().firstWhere((d) => d.gradient is LinearGradient);
    return (caja.gradient! as LinearGradient).colors;
  }

  testWidgets('el degradado de fondo en oscuro usa los tres tonos azul noche', (tester) async {
    await montar(tester, dark: true, procesando: false);
    expect(coloresDelFondo(tester), const [Color(0xFF04070C), Color(0xFF060A10), Color(0xFF0C1322)]);
  });

  testWidgets('el degradado de fondo en claro usa los tres tonos grises claros', (tester) async {
    await montar(tester, dark: false, procesando: false);
    expect(coloresDelFondo(tester), const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)]);
  });

  final pulso = find.byKey(const Key('network-backdrop-pulso'));

  testWidgets('sin isDark no aparece el pulso, aunque isProcessing sea true', (tester) async {
    await montar(tester, dark: false, procesando: true);
    expect(pulso, findsNothing);
  });

  testWidgets('en oscuro sin isProcessing no aparece el pulso', (tester) async {
    await montar(tester, dark: true, procesando: false);
    expect(pulso, findsNothing);
  });

  testWidgets('solo con isDark e isProcessing ambos verdaderos aparece el pulso', (tester) async {
    await montar(tester, dark: true, procesando: true);
    expect(pulso, findsOneWidget);
  });

  testWidgets('en modo oscuro procesando, el pulso sigue montado tras animar en bucle', (tester) async {
    await montar(tester, dark: true, procesando: true);

    // Recorre varios puntos del pulso (ida y vuelta, reverse: true).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('contenido'), findsOneWidget);
  });
}
