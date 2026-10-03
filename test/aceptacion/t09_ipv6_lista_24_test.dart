// Pasos de aceptación de t09_ipv6_lista_24.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_calculadora/module_calculadora.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

/// `find.text` no ve el contenido de `SelectableText`; este cubre ambos.
Finder _t(String texto) => find.byWidgetPredicate(
  (w) =>
      (w is Text && w.data == texto) ||
      (w is SelectableText && w.data == texto),
);

final _pasos = StepRegistry<void>.fromMap({
  'la pestaña "{p}" de la Calculadora abierta'.mapper(): (_, ctx) async {
    probador.view.physicalSize = const Size(1200, 4000);
    probador.view.devicePixelRatio = 1;
    addTearDown(probador.view.reset);
    await probador.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: CalculadoraScreen()),
      ),
    );
    await probador.tap(find.widgetWithText(Tab, ctx.arg<String>(0)));
    await probador.pumpAndSettle();
  },
  'el resumen dice "{e}" "{v}"'.mapper(): (_, ctx) async {
    final fila = find
        .ancestor(of: find.text(ctx.arg<String>(0)), matching: find.byType(Row))
        .first;
    expect(
      find.descendant(of: fila, matching: _t(ctx.arg<String>(1))),
      findsOneWidget,
    );
  },
  'veo el título "{t}"'.mapper(): (_, ctx) async {
    expect(_t(ctx.arg<String>(0)), findsOneWidget);
  },
  'veo la subred "{s}"'.mapper(): (_, ctx) async {
    expect(_t(ctx.arg<String>(0)), findsOneWidget);
  },
  'no veo la subred "{s}"'.mapper(): (_, ctx) async {
    expect(_t(ctx.arg<String>(0)), findsNothing);
  },
});

Future<void> main() async {
  await correrFeature('t09_ipv6_lista_24.feature', _pasos);
}
