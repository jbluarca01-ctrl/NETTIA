// Pasos de aceptación de t07_repara_fallas.feature (SPEC-001 T1).
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/aplicar.dart';
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
  List<ConfigEquipo>? antes;
  List<String> noReconocidos = const [];
}

var _m = _Mundo();

List<String> _hallazgos(String equipo) => [
  for (final h in auditarConfig(_m.configs!.singleWhere((c) => c.hostname == equipo).texto, _m.plan!)) h.mensaje,
];

final _pasos = StepRegistry<void>.fromMap({
  // SPEC-002 T1 (t10_repara_aplicar.feature).
  'aplico a "{e}" los comandos "{c}"'.mapper(): (_, ctx) async {
    _m.antes = _m.configs;
    final equipo = ctx.arg<String>(0);
    final viejo = _m.configs!.singleWhere((c) => c.hostname == equipo);
    final r = aplicarComandos(viejo, ctx.arg<String>(1).split(';').join('\n'));
    _m.noReconocidos = r.noReconocidos;
    _m.configs = [for (final c in _m.configs!) c.hostname == equipo ? r.config : c];
  },
  'no quedó ningún comando sin reconocer'.mapper(): (_, ctx) async {
    expect(_m.noReconocidos, isEmpty);
  },
  'no se reconocieron "{lista}"'.mapper(): (_, ctx) async {
    expect(_m.noReconocidos, ctx.arg<String>(0).split(','));
  },
  'la configuración de "{e}" no cambió'.mapper(): (_, ctx) async {
    String texto(List<ConfigEquipo> cs) => cs.singleWhere((c) => c.hostname == ctx.arg<String>(0)).texto;
    expect(texto(_m.configs!), texto(_m.antes!));
  },
  'las últimas líneas de "{e}" son "{lista}"'.mapper(): (_, ctx) async {
    final esperadas = ctx.arg<String>(1).split(';');
    final lineas = _m.configs!.singleWhere((c) => c.hostname == ctx.arg<String>(0)).lineas;
    expect([for (final l in lineas.skip(lineas.length - esperadas.length)) l.trim()], esperadas);
  },
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
  await correrFeature('t10_repara_aplicar.feature', _pasos);
}
