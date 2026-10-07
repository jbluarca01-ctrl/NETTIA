// Pasos de aceptación de t01_gateway_subredes.feature.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart' hide DataTable;
import 'package:module_calculadora/module_calculadora.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

String? _copiado;

DataTable get _tabla => probador.widget<DataTable>(find.byType(DataTable));

List<String> get _columnas => [
  for (final c in _tabla.columns) (c.label as Text).data!,
];

String _celda(DataCell c) => (c.child as SelectableText).data!;

final _pasos = StepRegistry<void>.fromMap({
  'la calculadora en la pestaña "{t}"'.mapper(): (_, ctx) async {
    probador.view.physicalSize = const Size(1600, 4000);
    probador.view.devicePixelRatio = 1;
    addTearDown(probador.view.reset);
    _copiado = null;
    probador.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (llamada) async {
        if (llamada.method == 'Clipboard.setData') {
          _copiado = (llamada.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => probador.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await probador.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: CalculadoraScreen()),
      ),
    );
    await probador.tap(find.widgetWithText(Tab, ctx.arg<String>(0)));
    await probador.pumpAndSettle();
  },
  'la tabla tiene la columna "{c}"'.mapper(): (_, ctx) async {
    expect(_columnas, contains(ctx.arg<String>(0)));
  },
  'la fila "{fila}" tiene el gateway "{ip}"'.mapper(): (_, ctx) async {
    final columna = _columnas.indexOf('Gateway');
    final fila = _tabla.rows.singleWhere(
      (r) => _celda(r.cells.first) == ctx.arg<String>(0),
    );
    expect(_celda(fila.cells[columna]), ctx.arg<String>(1));
  },
  'copio la tabla'.mapper(): (_, ctx) async {
    await probador.tap(find.text('Copiar tabla'));
    await probador.pump();
  },
  'el texto copiado tiene la columna "{c}"'.mapper(): (_, ctx) async {
    expect(_copiado!.split('\n').first.split('\t'), contains(ctx.arg<String>(0)));
  },
  'el texto copiado tiene la fila "{fila}"'.mapper(): (_, ctx) async {
    expect(_copiado!.split('\n'), contains(ctx.arg<String>(0)));
  },
});

Future<void> main() => correrFeature('t01_gateway_subredes.feature', _pasos);
