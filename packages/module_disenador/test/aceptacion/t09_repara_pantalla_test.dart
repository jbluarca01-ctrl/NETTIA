// Pasos de aceptación de t09_repara_pantalla.feature (SPEC-001 T2).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/module_disenador.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/repara.dart';
import 'package:module_disenador/src/repara_tab.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

Future<void> _mostrar(Widget pantalla) async {
  probador.view.physicalSize = const Size(1200, 6000);
  probador.view.devicePixelRatio = 1;
  addTearDown(probador.view.reset);
  await probador.pumpWidget(MaterialApp(theme: NetworkTheme.darkTheme, home: Scaffold(body: pantalla)));
}

Future<void> _tocar(Finder f) async {
  await probador.ensureVisible(f);
  await probador.tap(f);
  await probador.pumpAndSettle();
}

/// Las causas en el orden en que se muestran: la i-ésima tiene la clave
/// exacta `repara_causa_<i>`.
List<ListTile> _causas() {
  final causas = <ListTile>[];
  for (var i = 0; find.byKey(ValueKey('repara_causa_$i')).evaluate().isNotEmpty; i++) {
    causas.add(probador.widget<ListTile>(find.byKey(ValueKey('repara_causa_$i'))));
  }
  return causas;
}

List<String> _textosCausas() => [for (final c in _causas()) (c.title! as Text).data!];

final _pasos = StepRegistry<void>.fromMap({
  'la pantalla del Diseñador'.mapper(): (_, ctx) async {
    // Sin const: así se ejecuta el constructor de la pantalla.
    await _mostrar(DisenadorScreen());
  },
  'la pestaña con un ejercicio de la falla "{f}" en "{s}" de la red "{red}" con "{segs}"'.mapper(): (_, ctx) async {
    final [red, cidr] = ctx.arg<String>(2).split('/');
    final plan = planificarRed(red, int.parse(cidr), [
      for (final seg in ctx.arg<String>(3).split(','))
        Segmento(seg.split(':')[0], int.parse(seg.split(':')[1])),
    ], const OpcionesPlan());
    final falla = TipoFalla.values.byName(ctx.arg<String>(0));
    final segmento = plan.segmentos.singleWhere((s) => s.nombre == ctx.arg<String>(1));
    await _mostrar(RepararTab(crear: () => armarEjercicio(plan, falla, segmento, Random(0))));
  },
  'abro la pestaña "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.widgetWithText(Tab, ctx.arg<String>(0)));
  },
  'toco "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.widgetWithText(FilledButton, ctx.arg<String>(0)));
  },
  'elijo "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.widgetWithText(ListTile, ctx.arg<String>(0)));
  },
  'elijo una causa incorrecta'.mapper(): (_, ctx) async {
    final incorrecta = _textosCausas().firstWhere((c) => c != causaDe(TipoFalla.sinPool));
    await _tocar(find.widgetWithText(ListTile, incorrecta));
  },
  'veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsOneWidget);
  },
  'no veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsNothing);
  },
  'veo el resultado "{t}"'.mapper(): (_, ctx) async {
    final resultado = find.byKey(const ValueKey('repara_resultado'));
    expect(find.descendant(of: resultado, matching: find.text(ctx.arg<String>(0))), findsOneWidget);
  },
  'la única causa marcada es "{t}"'.mapper(): (_, ctx) async {
    final marcadas = [
      for (final c in _causas())
        if ((c.leading! as Icon).icon == Icons.radio_button_checked) (c.title! as Text).data!,
    ];
    expect(marcadas, [ctx.arg<String>(0)]);
  },
  'no veo el resultado'.mapper(): (_, ctx) async {
    expect(find.byKey(const ValueKey('repara_resultado')), findsNothing);
  },
  'hay {n} causas para elegir'.mapper(types: {'n': int}): (_, ctx) async {
    expect(_textosCausas().toSet(), hasLength(ctx.arg<int>(0)));
  },
});

Future<void> main() async {
  await correrFeature('t09_repara_pantalla.feature', _pasos);
}
