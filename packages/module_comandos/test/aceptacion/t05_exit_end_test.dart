// Pasos de aceptación de t05_exit_end.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_comandos/module_comandos.dart';

import 'comun.dart';

final _pasos = StepRegistry<void>.fromMap({
  'la pantalla de Comandos CLI'.mapper(): (_, ctx) async {
    probador.view.physicalSize = const Size(1400, 4000);
    probador.view.devicePixelRatio = 1;
    addTearDown(probador.view.reset);
    await probador.pumpWidget(
      const MaterialApp(home: Scaffold(body: ComandosScreen())),
    );
  },
  'abro la pestaña "{t}"'.mapper(): (_, ctx) async {
    await probador.tap(find.widgetWithText(Tab, ctx.arg<String>(0)));
    await probador.pumpAndSettle();
  },
  'veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsWidgets);
  },
  'veo {n} {veces} "{t}"'.mapper(types: {'n': int}): (_, ctx) async {
    expect(find.text(ctx.arg<String>(2)), findsNWidgets(ctx.arg<int>(0)));
  },
});

Future<void> main() async {
  await correrFeature('t05_exit_end.feature', _pasos);
}
