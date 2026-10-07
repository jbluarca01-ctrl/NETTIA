import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

const double _lado = 20;
const double _s = _lado * 0.58 / 40;
final ColorScheme _esquema = NetworkTheme.darkTheme.colorScheme;

Future<void> _montar(WidgetTester tester, {required bool pensando}) => tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: Scaffold(body: NettiaAvatar(size: _lado, pensando: pensando)),
      ),
    );

CustomPaint _lienzo(WidgetTester tester) => tester.widget<CustomPaint>(
      find.descendant(of: find.byType(NettiaAvatar), matching: find.byType(CustomPaint)).first,
    );

double _t(WidgetTester tester) => ((_lienzo(tester).painter! as dynamic).t as Animation<double>).value;

List<Invocation> _pintar(WidgetTester tester) {
  final canvas = TestRecordingCanvas();
  _lienzo(tester).painter!.paint(canvas, const Size(_lado, _lado));
  return canvas.invocations.map((r) => r.invocation).toList();
}

Iterable<Invocation> _de(List<Invocation> todas, Symbol nombre) => todas.where((i) => i.memberName == nombre);

Paint _paint(Invocation i) => i.positionalArguments.last as Paint;
Offset _off(Invocation i, int n) => i.positionalArguments[n] as Offset;

void _esperaOffset(Offset real, double x, double y) {
  expect(real.dx, closeTo(x, 1e-9));
  expect(real.dy, closeTo(y, 1e-9));
}

void main() {
  testWidgets('en reposo pinta fondo, borde, tres trazos y cuatro nodos, sin anillo ni señal', (tester) async {
    await _montar(tester, pensando: false);
    final llamadas = _pintar(tester);

    expect(_de(llamadas, #drawArc), isEmpty);
    final circulos = _de(llamadas, #drawCircle).toList();
    expect(circulos, hasLength(6));

    _esperaOffset(_off(circulos[0], 0), 10, 10);
    expect(circulos[0].positionalArguments[1], 10);
    expect(_paint(circulos[0]).color.toARGB32(), _esquema.surfaceContainerHighest.toARGB32());

    expect(circulos[1].positionalArguments[1], 9.5);
    expect(_paint(circulos[1]).style, PaintingStyle.stroke);
    expect(_paint(circulos[1]).strokeWidth, 1);
    expect(_paint(circulos[1]).color.toARGB32(), _esquema.outline.toARGB32());

    final traslado = _de(llamadas, #translate).single;
    expect(traslado.positionalArguments[0] as double, closeTo(4.2, 1e-9));
    expect(traslado.positionalArguments[1] as double, closeTo(4.2, 1e-9));

    for (var i = 2; i < 6; i++) {
      expect(circulos[i].positionalArguments[1] as double, closeTo(5 * _s, 1e-9));
    }
  });

  testWidgets('pensando a un cuarto de ciclo pinta anillo, trazos, señal y nodos con su geometría exacta', (tester) async {
    await _montar(tester, pensando: true);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_t(tester), closeTo(0.25, 1e-9));
    final llamadas = _pintar(tester);

    final arco = _de(llamadas, #drawArc).single;
    final rect = arco.positionalArguments[0] as Rect;
    _esperaOffset(rect.center, 10, 10);
    expect(rect.width, closeTo(17, 1e-9));
    expect(arco.positionalArguments[1] as double, closeTo(math.pi / 2, 1e-9));
    expect(arco.positionalArguments[2] as double, closeTo(math.pi * 0.9, 1e-9));
    expect(arco.positionalArguments[3], false);
    expect(_paint(arco).strokeWidth, 1.5);
    expect(_paint(arco).strokeCap, StrokeCap.round);
    expect(_paint(arco).style, PaintingStyle.stroke);
    expect(_paint(arco).shader, isNotNull);

    final traslado = _de(llamadas, #translate).single;
    expect(traslado.positionalArguments[0] as double, closeTo(4.2, 1e-9));
    expect(traslado.positionalArguments[1] as double, closeTo(4.7, 1e-9));

    final lineas = _de(llamadas, #drawLine).toList();
    expect(lineas, hasLength(3));
    final linea = NetworkTheme.darkTheme.textTheme.bodyLarge!.color;
    _esperaOffset(_off(lineas[0], 0), 8 * _s, 8 * _s);
    _esperaOffset(_off(lineas[0], 1), 8 * _s, 32 * _s);
    _esperaOffset(_off(lineas[1], 0), 32 * _s, 8 * _s);
    _esperaOffset(_off(lineas[1], 1), 32 * _s, 32 * _s);
    _esperaOffset(_off(lineas[2], 0), 8 * _s, 32 * _s);
    _esperaOffset(_off(lineas[2], 1), 32 * _s, 8 * _s);
    for (final l in lineas) {
      expect(_paint(l).strokeWidth, closeTo(3.5 * _s, 1e-6));
      expect(_paint(l).strokeCap, StrokeCap.round);
    }
    expect(_paint(lineas[0]).color.toARGB32(), (linea)!.toARGB32());
    expect(_paint(lineas[1]).color.toARGB32(), (linea).toARGB32());
    expect(_paint(lineas[2]).color.toARGB32(), _esquema.primary.toARGB32());

    final circulos = _de(llamadas, #drawCircle).toList();
    expect(circulos, hasLength(7));
    _esperaOffset(_off(circulos[2], 0), 14 * _s, 26 * _s);
    expect(circulos[2].positionalArguments[1] as double, closeTo(3.2 * _s, 1e-9));
    expect(_paint(circulos[2]).color.toARGB32() & 0x00FFFFFF, 0x00FFFFFF);
    expect(_paint(circulos[2]).color.a, closeTo(0.9, 0.01));

    const centros = [(8.0, 8.0), (32.0, 8.0), (32.0, 32.0), (8.0, 32.0)];
    const factores = [1.0, 1.45, 1.0, 1.0];
    final colores = [_esquema.primary, _esquema.tertiary, _esquema.primary, _esquema.tertiary];
    for (var i = 0; i < 4; i++) {
      final nodo = circulos[3 + i];
      _esperaOffset(_off(nodo, 0), centros[i].$1 * _s, centros[i].$2 * _s);
      expect(nodo.positionalArguments[1] as double, closeTo(5 * _s * factores[i], 1e-9));
      expect(_paint(nodo).color.toARGB32(), colores[i].toARGB32());
    }
  });

  testWidgets('sin pensar no queda ninguna animación programada', (tester) async {
    await _montar(tester, pensando: false);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('pensando sigue programando cuadros mientras dura el ciclo', (tester) async {
    await _montar(tester, pensando: true);
    await tester.pump(const Duration(milliseconds: 2500));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  Future<void> reconstruir(WidgetTester tester, {required bool pensando}) => _montar(tester, pensando: pensando);

  testWidgets('reconstruir con pensando=false sin cambio no arranca ninguna animación', (tester) async {
    await _montar(tester, pensando: false);
    await reconstruir(tester, pensando: false);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_t(tester), 0);
  });

  testWidgets('reconstruir con pensando=true sin cambio no interrumpe el bucle', (tester) async {
    await _montar(tester, pensando: true);
    await tester.pump(const Duration(milliseconds: 400));
    await reconstruir(tester, pensando: true);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('al dejar de pensar, vuelve a 0 en 300 ms y mientras tanto sigue pintando el anillo', (tester) async {
    await _montar(tester, pensando: true);
    await tester.pump(const Duration(milliseconds: 400));
    await reconstruir(tester, pensando: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(_t(tester), closeTo(0.625, 0.02));
    expect(_de(_pintar(tester), #drawArc), hasLength(1));

    await tester.pumpAndSettle();
    expect(_t(tester), 0);
    expect(_de(_pintar(tester), #drawArc), isEmpty);
  });
}
