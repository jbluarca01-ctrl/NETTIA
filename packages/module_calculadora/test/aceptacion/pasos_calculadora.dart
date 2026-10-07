// Pasos compartidos por los features de la pestaña "Red" y "Conversión".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_calculadora/module_calculadora.dart';
import 'package:module_calculadora/src/logic/conversiones.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

Future<void> _abrir(String pestana) async {
  probador.view.physicalSize = const Size(1200, 3000);
  probador.view.devicePixelRatio = 1;
  addTearDown(probador.view.reset);
  await probador.pumpWidget(
    MaterialApp(
      theme: NetworkTheme.darkTheme,
      home: const Scaffold(body: CalculadoraScreen()),
    ),
  );
  await probador.tap(find.widgetWithText(Tab, pestana));
  await probador.pumpAndSettle();
}

Future<void> _abrirRed(String ip) async {
  await _abrir('Red');
  await probador.enterText(
    find.widgetWithText(TextField, 'Dirección IPv4'),
    ip,
  );
  await probador.pumpAndSettle();
}

/// Pasa la pestaña "Red" a máscara decimal y escribe [mascara].
Future<void> _escribirMascara(String mascara) async {
  await probador.tap(find.text('Máscara dec.'));
  await probador.pumpAndSettle();
  await probador.enterText(
    find.widgetWithText(TextField, 'Máscara decimal (ej. 255.255.255.0)'),
    mascara,
  );
  await probador.pumpAndSettle();
}

/// Valor (a la derecha) de la primera fila cuya etiqueta es [etiqueta].
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

/// Pasos de la calculadora reutilizables entre features.
final Map<LineMapper, StepFunction<void>> pasosCalculadora = {
  'la pestaña "Red" con la IP "{ip}" y el prefijo "{p}"'.mapper(): (
    _,
    ctx,
  ) async {
    final prefijo = int.parse(ctx.arg<String>(1).substring(1));
    await _abrirRed(ctx.arg<String>(0));
    await _escribirMascara(mascaraDePrefijo(prefijo));
  },
  'el selector de CIDR va de "{a}" a "{b}"'.mapper(): (_, ctx) async {
    final selector = probador.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>),
    );
    final valores = [for (final i in selector.items!) '/${i.value}'];
    expect(valores.first, ctx.arg<String>(0));
    expect(valores.last, ctx.arg<String>(1));
  },
  'hay {n} fila "{f}"'.mapper(types: {'n': int}): (_, ctx) async {
    expect(find.text(ctx.arg<String>(1)), findsNWidgets(ctx.arg<int>(0)));
  },
  'hay {n} filas "{f}"'.mapper(types: {'n': int}): (_, ctx) async {
    expect(find.text(ctx.arg<String>(1)), findsNWidgets(ctx.arg<int>(0)));
  },
  'la pestaña "Red" con la IP "{ip}" y la máscara "{m}"'.mapper(): (
    _,
    ctx,
  ) async {
    await _abrirRed(ctx.arg<String>(0));
    await _escribirMascara(ctx.arg<String>(1));
  },
  // Después de las variantes con prefijo o máscara: "{ip}" también
  // calzaría con el resto de esas líneas.
  'la pestaña "Red" con la IP "{ip}"'.mapper(): (_, ctx) async {
    await _abrirRed(ctx.arg<String>(0));
  },
  'la pestaña "Conversión" con la máscara "{m}"'.mapper(): (_, ctx) async {
    await _abrir('Conversión');
    await probador.enterText(find.byType(TextField).first, ctx.arg<String>(0));
    await probador.pumpAndSettle();
  },
  'la pestaña "VLSM" con las redes de ejemplo'.mapper(): (_, ctx) async {
    await _abrir('VLSM');
  },
  'escribo la otra IP "{ip}"'.mapper(): (_, ctx) async {
    await probador.enterText(
      find.widgetWithText(TextField, 'Otra IP o gateway (opcional)'),
      ctx.arg<String>(0),
    );
    await probador.pumpAndSettle();
  },
  'la fila "{f}" dice "{v}"'.mapper(): (_, ctx) async {
    expect(_valorDeFila(ctx.arg<String>(0)), ctx.arg<String>(1));
  },
  'no hay fila "{f}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsNothing);
  },
  'la explicación menciona "{t}"'.mapper(): (_, ctx) async {
    expect(find.textContaining(ctx.arg<String>(0)), findsOneWidget);
  },
};
