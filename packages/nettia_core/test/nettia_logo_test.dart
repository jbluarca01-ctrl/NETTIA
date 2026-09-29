import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

void main() {
  group('segmentoLogo', () {
    test('antes de empezar el tramo vale 0', () {
      expect(segmentoLogo(0.0, 0.2, 0.6), 0.0);
    });

    test('a la mitad del tramo vale 0.5', () {
      expect(segmentoLogo(0.4, 0.2, 0.6), closeTo(0.5, 1e-9));
    });

    test('después de terminar el tramo se satura en 1', () {
      expect(segmentoLogo(1.0, 0.2, 0.6), 1.0);
    });
  });

  group('coloresDeLogoCambiaron', () {
    const base = (lineColor: Colors.white, accent: Colors.blue, accent2: Colors.teal);

    bool conCambio({Color? lineColor, Color? accent, Color? accent2}) => coloresDeLogoCambiaron(
          lineColorAntes: base.lineColor,
          lineColorAhora: lineColor ?? base.lineColor,
          accentAntes: base.accent,
          accentAhora: accent ?? base.accent,
          accent2Antes: base.accent2,
          accent2Ahora: accent2 ?? base.accent2,
        );

    test('sin ningún cambio, no hay que repintar', () {
      expect(conCambio(), isFalse);
    });

    test('cada color por separado dispara el repintado', () {
      expect(conCambio(lineColor: Colors.red), isTrue);
      expect(conCambio(accent: Colors.red), isTrue);
      expect(conCambio(accent2: Colors.red), isTrue);
    });
  });

  testWidgets('NettiaLogo usa los colores dados en vez de los del tema', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(
          body: NettiaLogo(color: Colors.red, accent: Colors.green, accent2: Colors.blue),
        ),
      ),
    );
    expect(find.byType(NettiaLogo), findsOneWidget);
  });

  testWidgets('NettiaLogo sin colores dados usa los del tema (rama de fallback)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: NettiaLogo()),
      ),
    );
    expect(find.byType(NettiaLogo), findsOneWidget);
  });

  testWidgets('AnimatedNettiaLogo recorre toda la animación y se asienta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        // Sin `const`: un constructor `const` se evalúa en compilación y
        // nunca aparece "cubierto" para el instrumentador de línea.
        home: Scaffold(body: AnimatedNettiaLogo()),
      ),
    );
    // Recorre varios puntos del reloj de animación (0.0 -> 1.0), ejerciendo
    // _seg/_node/_drawPartial en distintos progresos, incluida la saturación.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedNettiaLogo), findsOneWidget);
  });

  testWidgets('AnimatedNettiaLogo sin colores dados usa los del tema', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: AnimatedNettiaLogo()),
      ),
    );
    await tester.pump();
    expect(find.byType(AnimatedNettiaLogo), findsOneWidget);
  });
}
