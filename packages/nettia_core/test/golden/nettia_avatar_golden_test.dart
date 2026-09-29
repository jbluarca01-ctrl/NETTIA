import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

/// Golden tests de [_AvatarPainter]: la geometría del avatar (círculo, anillo
/// giratorio, logo interno, señal y nodos) es dibujo puro sobre `Canvas`,
/// sin rama ni valor de retorno que un test normal pueda comparar.
const _boundaryKey = Key('golden-boundary-avatar');
final _boundary = find.byKey(_boundaryKey);

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

void main() {
  testWidgets('NettiaAvatar en reposo (pensando=false) coincide con la referencia', (tester) async {
    await _montar(tester, const NettiaAvatar(size: 80));
    await expectLater(_boundary, matchesGoldenFile('goldens/nettia_avatar_reposo.png'));
  });

  testWidgets('NettiaAvatar pensando a mitad del ciclo coincide con la referencia', (tester) async {
    await _montar(tester, const NettiaAvatar(size: 80, pensando: true));
    // Duración total 1600ms: 800ms = t=0.5.
    await tester.pump(const Duration(milliseconds: 800));
    await expectLater(_boundary, matchesGoldenFile('goldens/nettia_avatar_pensando_50.png'));
  });

  testWidgets('NettiaAvatar pensando al final del ciclo coincide con la referencia', (tester) async {
    await _montar(tester, const NettiaAvatar(size: 80, pensando: true));
    await tester.pump(const Duration(milliseconds: 1600));
    await expectLater(_boundary, matchesGoldenFile('goldens/nettia_avatar_pensando_100.png'));
  });
}
