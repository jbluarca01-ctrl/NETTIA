import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

/// Golden tests de [NetworkBackdrop]: los gradientes y el tamaño/posición
/// del resplandor y el pulso son valores fijos dibujados directamente, sin
/// rama ni retorno que un test normal pueda comparar.
const _boundaryKey = Key('golden-boundary-backdrop');
final _boundary = find.byKey(_boundaryKey);

Future<void> _montar(WidgetTester tester, {required bool dark, required bool procesando}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: dark ? NetworkTheme.darkTheme : NetworkTheme.lightTheme,
      home: Scaffold(
        body: RepaintBoundary(
          key: _boundaryKey,
          child: SizedBox(
            width: 200,
            height: 200,
            child: NetworkBackdrop(
              isProcessing: procesando,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('modo oscuro sin procesar coincide con la referencia', (tester) async {
    await _montar(tester, dark: true, procesando: false);
    await expectLater(_boundary, matchesGoldenFile('goldens/network_backdrop_oscuro.png'));
  });

  testWidgets('modo claro coincide con la referencia', (tester) async {
    await _montar(tester, dark: false, procesando: false);
    await expectLater(_boundary, matchesGoldenFile('goldens/network_backdrop_claro.png'));
  });

  testWidgets('modo oscuro procesando, a mitad del pulso, coincide con la referencia', (tester) async {
    await _montar(tester, dark: true, procesando: true);
    // Duración total 2400ms: 1200ms = pico del pulso (reverse: true).
    await tester.pump(const Duration(milliseconds: 1200));
    await expectLater(_boundary, matchesGoldenFile('goldens/network_backdrop_pulso_pico.png'));
  });
}
