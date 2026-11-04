import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/module_disenador.dart';
import 'package:module_disenador/src/campos.dart';
import 'package:module_disenador/src/sede_extra.dart';

Future<void> _mostrar(WidgetTester tester, Widget w) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: w))));
}

/// Un controlador ya liberado lanza al usarlo.
void _liberado(TextEditingController c) => expect(() => c.addListener(() {}), throwsFlutterError);

InputDecoration _decoracion(WidgetTester tester, String clave) =>
    tester.widget<TextField>(find.byKey(ValueKey(clave))).decoration!;

void main() {
  testWidgets('la tarjeta de la sede 2 tiene sus campos, etiquetas, pista y separaciones', (tester) async {
    final sede = SedeExtra(2);
    addTearDown(sede.liberar);
    await _mostrar(tester, TarjetaSede(sede));
    expect(find.byKey(const ValueKey('sede_2')), findsOneWidget);
    expect(find.text('Sede 2 (R2)'), findsOneWidget);
    expect(_decoracion(tester, 'sede2_red').labelText, 'Red base');
    expect(_decoracion(tester, 'sede2_red').hintText, '192.168.20.0/24');
    expect(_decoracion(tester, 'sede2_nombre_1').labelText, 'Nombre');
    expect(_decoracion(tester, 'sede2_hosts_1').labelText, 'Hosts');
    expect(tester.widget<Card>(find.byType(Card)).margin, const EdgeInsets.only(bottom: 12));
    expect(tester.widget<ExpansionTile>(find.byType(ExpansionTile)).childrenPadding, const EdgeInsets.all(12));
    expect(tester.widget<SizedBox>(find.byWidgetPredicate((w) => w is SizedBox && w.width != null && w.height == null)).width, 12);
  });

  testWidgets('la pista de la sede 3 es 192.168.30.0/24', (tester) async {
    final sede = SedeExtra(3);
    addTearDown(sede.liberar);
    await _mostrar(tester, TarjetaSede(sede));
    expect(_decoracion(tester, 'sede3_red').hintText, '192.168.30.0/24');
  });

  test('liberar suelta la red y todas las filas', () {
    final sede = SedeExtra(2);
    sede.filas.add((TextEditingController(), TextEditingController()));
    final filas = [...sede.filas];
    sede.liberar();
    _liberado(sede.red);
    for (final (n, h) in filas) {
      _liberado(n);
      _liberado(h);
    }
  });

  testWidgets('quitar una fila la libera después del cuadro', (tester) async {
    final sede = SedeExtra(2);
    addTearDown(sede.liberar);
    await _mostrar(tester, TarjetaSede(sede));
    final (nombre, hosts) = sede.filas.single;
    await tester.tap(find.byTooltip('Quitar segmento 1 de la sede 2'));
    await tester.pumpAndSettle();
    _liberado(nombre);
    _liberado(hosts);
    expect(sede.filas, isEmpty);
  });

  testWidgets('campoTexto deja 12 debajo', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _mostrar(tester, campoTexto(c, 'X'));
    expect(tester.widget<Padding>(find.byType(Padding).first).padding, const EdgeInsets.only(bottom: 12));
  });

  testWidgets('al bajar los routers y al cerrar la pantalla se liberan las sedes', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DisenadorScreen())));
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    final sedes = [for (final t in tester.widgetList<TarjetaSede>(find.byType(TarjetaSede))) t.sede];
    expect([for (final s in sedes) s.numero], [2, 3]);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    _liberado(sedes[1].red);
    await tester.pumpWidget(const SizedBox());
    _liberado(sedes[0].red);
  });
}
