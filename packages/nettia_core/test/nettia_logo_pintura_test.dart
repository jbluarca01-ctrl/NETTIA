import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

const Color _linea = Color(0xFF112233);
const Color _acento = Color(0xFF445566);
const Color _acento2 = Color(0xFF778899);

Widget _app(Widget logo) => MaterialApp(home: Scaffold(body: logo));

List<Invocation> _pintar(WidgetTester tester, Type logo) {
  final lienzo = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(logo), matching: find.byType(CustomPaint)).first,
  );
  final canvas = TestRecordingCanvas();
  lienzo.painter!.paint(canvas, const Size(40, 40));
  return canvas.invocations.map((r) => r.invocation).toList();
}

List<Invocation> _de(List<Invocation> todas, Symbol nombre) =>
    todas.where((i) => i.memberName == nombre).toList();

Paint _paint(Invocation i) => i.positionalArguments.last as Paint;
Offset _off(Invocation i, int n) => i.positionalArguments[n] as Offset;

void _en(Offset real, double x, double y) {
  expect(real.dx, closeTo(x, 1e-9));
  expect(real.dy, closeTo(y, 1e-9));
}

int _argb(Color c) => c.toARGB32();

void main() {
  test('tamaños por defecto: 28 el logo fijo y 64 el animado', () {
    expect(const NettiaLogo().size, 28);
    expect(const AnimatedNettiaLogo().size, 64);
  });

  testWidgets('el logo fijo dibuja tres trazos y cuatro nodos con su geometría', (tester) async {
    await tester.pumpWidget(_app(
      NettiaLogo(size: 40, color: _linea, accent: _acento, accent2: _acento2),
    ));
    final llamadas = _pintar(tester, NettiaLogo);

    final lineas = _de(llamadas, #drawLine);
    expect(lineas, hasLength(3));
    _en(_off(lineas[0], 0), 8, 8);
    _en(_off(lineas[0], 1), 8, 32);
    _en(_off(lineas[1], 0), 32, 8);
    _en(_off(lineas[1], 1), 32, 32);
    _en(_off(lineas[2], 0), 8, 32);
    _en(_off(lineas[2], 1), 32, 8);
    for (final l in lineas) {
      expect(_paint(l).strokeWidth, 3.5);
      expect(_paint(l).strokeCap, StrokeCap.round);
    }
    expect(_argb(_paint(lineas[0]).color), _argb(_linea));
    expect(_argb(_paint(lineas[1]).color), _argb(_linea));
    expect(_argb(_paint(lineas[2]).color), _argb(_acento));

    final nodos = _de(llamadas, #drawCircle);
    expect(nodos, hasLength(4));
    const esperado = [(8.0, 8.0, _acento), (8.0, 32.0, _acento2), (32.0, 8.0, _acento2), (32.0, 32.0, _acento)];
    for (var i = 0; i < 4; i++) {
      _en(_off(nodos[i], 0), esperado[i].$1, esperado[i].$2);
      expect(nodos[i].positionalArguments[1], 5);
      expect(_argb(_paint(nodos[i]).color), _argb(esperado[i].$3));
    }
  });

  testWidgets('el logo animado en t=0 no dibuja ningún trazo ni nodo todavía', (tester) async {
    await tester.pumpWidget(_app(AnimatedNettiaLogo(size: 40, color: _linea, accent: _acento, accent2: _acento2)));
    final llamadas = _pintar(tester, AnimatedNettiaLogo);
    expect(_de(llamadas, #drawLine), isEmpty);
    expect(_de(llamadas, #drawCircle), isEmpty);
  });

  testWidgets('el logo animado a mitad de la animación dibuja trazos y nodos parciales exactos', (tester) async {
    await tester.pumpWidget(_app(AnimatedNettiaLogo(size: 40, color: _linea, accent: _acento, accent2: _acento2)));
    await tester.pump(const Duration(milliseconds: 450));
    final llamadas = _pintar(tester, AnimatedNettiaLogo);

    final lineas = _de(llamadas, #drawLine);
    expect(lineas, hasLength(3));
    _en(_off(lineas[0], 0), 8, 8);
    _en(_off(lineas[0], 1), 8, 8 + 24 * 0.9);
    _en(_off(lineas[1], 0), 32, 8);
    _en(_off(lineas[1], 1), 32, 8 + 24 * 0.7);
    _en(_off(lineas[2], 0), 8, 32);
    _en(_off(lineas[2], 1), 8 + 24 * (0.2 / 0.55), 32 - 24 * (0.2 / 0.55));
    for (final l in lineas) {
      expect(_paint(l).strokeWidth, 3.5);
      expect(_paint(l).strokeCap, StrokeCap.round);
    }
    expect(_argb(_paint(lineas[0]).color), _argb(_linea));
    expect(_argb(_paint(lineas[1]).color), _argb(_linea));
    expect(_argb(_paint(lineas[2]).color), _argb(_acento));

    final nodos = _de(llamadas, #drawCircle);
    expect(nodos, hasLength(3));
    _en(_off(nodos[0], 0), 8, 8);
    expect(nodos[0].positionalArguments[1], 5);
    _en(_off(nodos[1], 0), 8, 32);
    expect(nodos[1].positionalArguments[1], 5);
    _en(_off(nodos[2], 0), 32, 8);
    final k = 0.3 / 0.35;
    expect(nodos[2].positionalArguments[1] as double, closeTo(5 * Curves.easeOutBack.transform(k), 1e-9));
    expect(_paint(nodos[2]).color.a, closeTo(k, 0.01));
  });
}
