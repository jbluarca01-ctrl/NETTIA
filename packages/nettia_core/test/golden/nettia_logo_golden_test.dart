import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

/// Golden tests: comparan el píxel renderizado contra una imagen de
/// referencia en `test/golden/goldens/`. Cubren la geometría exacta de
/// [_NettiaLogoPainter] y [_AnimatedNettiaPainter] (constantes numéricas de
/// `paint()`) que un test de solo-lógica no puede ejercitar, porque ahí no
/// hay rama ni valor de retorno que comparar: es dibujo puro.
const _boundaryKey = Key('golden-boundary');

Future<void> _montar(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: NetworkTheme.darkTheme,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: RepaintBoundary(key: _boundaryKey, child: child),
        ),
      ),
    ),
  );
}

final _boundary = find.byKey(_boundaryKey);

void main() {
  testWidgets('NettiaLogo estático coincide con la referencia', (tester) async {
    await _montar(
      tester,
      const NettiaLogo(size: 80, color: Colors.white, accent: Color(0xFF3FA7FF), accent2: Color(0xFF4EC9B0)),
    );
    await expectLater(
      _boundary,
      matchesGoldenFile('goldens/nettia_logo_estatico.png'),
    );
  });

  testWidgets('AnimatedNettiaLogo a mitad de la animación coincide con la referencia', (tester) async {
    await _montar(
      tester,
      const AnimatedNettiaLogo(
        size: 80,
        color: Colors.white,
        accent: Color(0xFF3FA7FF),
        accent2: Color(0xFF4EC9B0),
      ),
    );
    // Duración total 900ms: 450ms = t=0.5.
    await tester.pump(const Duration(milliseconds: 450));
    await expectLater(
      _boundary,
      matchesGoldenFile('goldens/nettia_logo_animado_50.png'),
    );
  });

  testWidgets('AnimatedNettiaLogo al terminar la animación coincide con la referencia', (tester) async {
    await _montar(
      tester,
      const AnimatedNettiaLogo(
        size: 80,
        color: Colors.white,
        accent: Color(0xFF3FA7FF),
        accent2: Color(0xFF4EC9B0),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await expectLater(
      _boundary,
      matchesGoldenFile('goldens/nettia_logo_animado_100.png'),
    );
  });
}
