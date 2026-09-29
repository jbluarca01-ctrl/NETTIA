// Pasos de aceptación de t02_doctor_pestana.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_comandos/module_comandos.dart';
import 'package:module_comandos/src/doctor_tab.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

Future<void> _abrir(Widget pantalla) async {
  probador.view.physicalSize = const Size(1400, 4000);
  probador.view.devicePixelRatio = 1;
  addTearDown(probador.view.reset);
  await probador.pumpWidget(
    MaterialApp(theme: NetworkTheme.darkTheme, home: Scaffold(body: pantalla)),
  );
}

final _pasos = StepRegistry<void>.fromMap({
  'la pestaña Doctor abierta'.mapper(): (_, ctx) async {
    final c = DoctorConsolaControlador();
    addTearDown(c.dispose);
    await _abrir(DoctorConsolaTab(c));
  },
  'la pantalla de Comandos CLI'.mapper(): (_, ctx) async {
    await _abrir(const ComandosScreen());
  },
  'abro la pestaña "{t}"'.mapper(): (_, ctx) async {
    await probador.tap(find.widgetWithText(Tab, ctx.arg<String>(0)));
    await probador.pumpAndSettle();
  },
  'pego y diagnostico:'.mapper(): (_, ctx) async {
    await probador.enterText(
      find.byKey(const ValueKey('doctor_texto')),
      docString(ctx.docContent),
    );
    await probador.tap(find.text('Diagnosticar'));
    await probador.pumpAndSettle();
  },
  'veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsWidgets);
  },
  'veo el texto que contiene "{t}"'.mapper(): (_, ctx) async {
    expect(find.textContaining(ctx.arg<String>(0)), findsWidgets);
  },
  'no veo el texto que contiene "{t}"'.mapper(): (_, ctx) async {
    expect(find.textContaining(ctx.arg<String>(0)), findsNothing);
  },
});

Future<void> main() async {
  await correrFeature('t02_doctor_pestana.feature', _pasos);
}
