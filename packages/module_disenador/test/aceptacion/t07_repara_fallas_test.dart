// Pasos de aceptación de t07_repara_fallas.feature (SPEC-001 T1).
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

import 'comun.dart';

class _Mundo {
  PlanRed? plan;
  List<ConfigEquipo>? configs;
  TipoFalla? falla;
  SegmentoPlan? segmento;
}

var _m = _Mundo();

List<String> _hallazgos(String equipo) => [
  for (final h in auditarConfig(_m.configs!.singleWhere((c) => c.hostname == equipo).texto, _m.plan!)) h.mensaje,
];

final _pasos = StepRegistry<void>.fromMap({
  'la red base "{red}" con los segmentos "{s}"'.mapper(): (_, ctx) async {
    final [red, cidr] = ctx.arg<String>(0).split('/');
    _m.plan = planificarRed(red, int.parse(cidr), [
      for (final seg in ctx.arg<String>(1).split(','))
        Segmento(seg.split(':')[0], int.parse(seg.split(':')[1])),
    ], const OpcionesPlan());
  },
  'genero la configuración sin falla'.mapper(): (_, ctx) async {
    _m.configs = generarConfiguracion(_m.plan!, const OpcionesConfig());
  },
  'inyecto la falla "{f}" en el segmento "{s}"'.mapper(): (_, ctx) async {
    _m.falla = TipoFalla.values.byName(ctx.arg<String>(0));
    _m.segmento = _m.plan!.segmentos.singleWhere((s) => s.nombre == ctx.arg<String>(1));
    _m.configs = inyectarFalla(
      generarConfiguracion(_m.plan!, const OpcionesConfig()),
      _m.plan!,
      _m.falla!,
      _m.segmento!,
    );
  },
  'el auditor no reporta nada en "{e}"'.mapper(): (_, ctx) async {
    expect(_hallazgos(ctx.arg<String>(0)), isEmpty);
  },
  'el auditor reporta en "{e}" solo "{h}"'.mapper(): (_, ctx) async {
    expect(_hallazgos(ctx.arg<String>(0)), [ctx.arg<String>(1)]);
  },
  'el síntoma es "{t}"'.mapper(): (_, ctx) async {
    expect(sintomaDe(_m.falla!, _m.segmento!, _m.plan!), ctx.arg<String>(0));
  },
  'la causa es "{t}"'.mapper(): (_, ctx) async {
    expect(causaDe(_m.falla!), ctx.arg<String>(0));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t07_repara_fallas.feature', _pasos);
}
