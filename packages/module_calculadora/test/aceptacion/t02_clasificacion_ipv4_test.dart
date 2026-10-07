// Pasos de aceptación de t02_clasificacion_ipv4.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_calculadora/module_calculadora.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

Future<void> _abrirRed(String ip) async {
  probador.view.physicalSize = const Size(1200, 3000);
  probador.view.devicePixelRatio = 1;
  addTearDown(probador.view.reset);
  await probador.pumpWidget(
    MaterialApp(
      theme: NetworkTheme.darkTheme,
      home: const Scaffold(body: CalculadoraScreen()),
    ),
  );
  await probador.enterText(
    find.widgetWithText(TextField, 'Dirección IPv4'),
    ip,
  );
  await probador.pumpAndSettle();
}

/// Valor (a la derecha) de la fila cuya etiqueta es [etiqueta].
String _valorDeFila(String etiqueta) {
  final fila = find.ancestor(
    of: find.text(etiqueta),
    matching: find.byType(Row),
  );
  final valor = find.descendant(
    of: fila.first,
    matching: find.byType(SelectableText),
  );
  return probador.widget<SelectableText>(valor.first).data!;
}

final _pasos = StepRegistry<void>.fromMap({
  'la pestaña "Red" con la IP "{ip}"'.mapper(): (_, ctx) async {
    await _abrirRed(ctx.arg<String>(0));
  },
  'la pestaña "Red" con la IP "{ip}" y el prefijo "{p}"'.mapper(): (
    _,
    ctx,
  ) async {
    await _abrirRed(ctx.arg<String>(0));
    await probador.tap(find.byType(DropdownButtonFormField<int>));
    await probador.pumpAndSettle();
    await probador.tap(find.text(ctx.arg<String>(1)).last);
    await probador.pumpAndSettle();
  },
  'la fila "{f}" dice "{v}"'.mapper(): (_, ctx) async {
    expect(_valorDeFila(ctx.arg<String>(0)), ctx.arg<String>(1));
  },
  'la explicación menciona "{t}"'.mapper(): (_, ctx) async {
    expect(find.textContaining(ctx.arg<String>(0)), findsOneWidget);
  },
});

void main() => correrFeature('t02_clasificacion_ipv4.feature', _pasos);
