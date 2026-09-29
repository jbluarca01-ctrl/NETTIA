// Pasos de aceptación de t05_pantalla.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/module_disenador.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

Future<void> _tocar(Finder f) async {
  await probador.ensureVisible(f);
  await probador.tap(f);
  await probador.pumpAndSettle();
}

final _pasos = StepRegistry<void>.fromMap({
  'la pantalla del Diseñador'.mapper(): (_, ctx) async {
    probador.view.physicalSize = const Size(1200, 4000);
    probador.view.devicePixelRatio = 1;
    addTearDown(probador.view.reset);
    await probador.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        // Sin const: así se ejecuta el constructor de la pantalla.
        home: Scaffold(body: DisenadorScreen()),
      ),
    );
  },
  'abro la pestaña "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.widgetWithText(Tab, ctx.arg<String>(0)));
  },
  'toco "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.text(ctx.arg<String>(0)).last);
  },
  'elijo "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.text(ctx.arg<String>(0)));
  },
  'activo "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.text(ctx.arg<String>(0)));
  },
  'escribo "{v}" en "{campo}"'.mapper(): (_, ctx) async {
    await probador.enterText(
      find.widgetWithText(TextField, ctx.arg<String>(1)),
      ctx.arg<String>(0),
    );
  },
  'escribo "{v}" en el nombre del segmento {n}'.mapper(types: {'n': int}): (
    _,
    ctx,
  ) async {
    await probador.enterText(
      find.byKey(ValueKey('segmento_nombre_${ctx.arg<int>(1)}')),
      ctx.arg<String>(0),
    );
  },
  'escribo "{v}" en los hosts del segmento {n}'.mapper(types: {'n': int}): (
    _,
    ctx,
  ) async {
    await probador.enterText(
      find.byKey(ValueKey('segmento_hosts_${ctx.arg<int>(1)}')),
      ctx.arg<String>(0),
    );
  },
  'quito el segmento {n}'.mapper(types: {'n': int}): (_, ctx) async {
    await _tocar(find.byTooltip('Quitar segmento ${ctx.arg<int>(0)}'));
  },
  'pego la running-config:'.mapper(): (_, ctx) async {
    await probador.enterText(
      find.byKey(const ValueKey('auditar_texto')),
      docString(ctx.docContent),
    );
  },
  'veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsWidgets);
  },
  'no veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsNothing);
  },
  'veo el texto que contiene "{t}"'.mapper(): (_, ctx) async {
    expect(find.textContaining(ctx.arg<String>(0)), findsWidgets);
  },
});

Future<void> main() async {
  await correrFeature('t05_pantalla.feature', _pasos);
}
