// Pasos de aceptación de t13_config_multisede.feature (SPEC-003 T2).
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/generador_multisede.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

import 'comun.dart';

class _Mundo {
  final planes = <PlanRed>[];
  final opciones = <OpcionesConfig>[];
  List<ConfigEquipo>? equipos;
}

var _m = _Mundo();

List<String> _lineas(String hostname) => [
  for (final l in _m.equipos!.singleWhere((c) => c.hostname == hostname).lineas) l.trim(),
];

PlanRed _plan(String red, List<Segmento> segmentos) {
  final [base, cidr] = red.split('/');
  return planificarRed(base, int.parse(cidr), segmentos, const OpcionesPlan());
}

final _pasos = StepRegistry<void>.fromMap({
  'la sede {n} "{red}" con "{segs}"'.mapper(): (_, ctx) async {
    expect(_m.planes, hasLength(int.parse(ctx.arg<String>(0)) - 1));
    _m.planes.add(
      _plan(ctx.arg<String>(1), [
        for (final s in ctx.arg<String>(2).split(',')) Segmento(s.split(':')[0], int.parse(s.split(':')[1])),
      ]),
    );
    _m.opciones.add(const OpcionesConfig());
  },
  'la sede {n} tiene {s} switches con "{segs}"'.mapper(): (_, ctx) async {
    final i = int.parse(ctx.arg<String>(0)) - 1;
    final reparto = {
      for (final s in ctx.arg<String>(2).split(','))
        s.split(':')[0]: [for (final n in s.split(':')[1].split('+')) int.parse(n)],
    };
    _m.planes[i] = _plan('${_m.planes[i].redBase}/${_m.planes[i].cidrBase}', [
      for (final MapEntry(key: nombre, value: pcs) in reparto.entries) Segmento(nombre, pcs.reduce((a, b) => a + b)),
    ]);
    _m.opciones[i] = OpcionesConfig(switches: int.parse(ctx.arg<String>(1)), pcPorSwitch: reparto);
  },
  'genero la red con los enlaces "{e}" y el enrutamiento "{r}"'.mapper(): (_, ctx) async {
    final red = planificarMultisede(_m.planes, ctx.arg<String>(0), Enrutamiento.values.byName(ctx.arg<String>(1)));
    _m.equipos = generarMultisede(red, _m.opciones);
  },
  'los equipos son "{lista}"'.mapper(): (_, ctx) async {
    expect([for (final c in _m.equipos!) c.hostname], ctx.arg<String>(0).split(','));
  },
  '"{h}" tiene seguidas las líneas "{lista}"'.mapper(): (_, ctx) async {
    final lineas = _lineas(ctx.arg<String>(0));
    final esperadas = ctx.arg<String>(1).split(';');
    final seguidas = [
      for (var i = 0; i + esperadas.length <= lineas.length; i++) lineas.sublist(i, i + esperadas.length).join('\n'),
    ];
    expect(seguidas, contains(esperadas.join('\n')), reason: lineas.join('\n'));
  },
  '"{h}" no tiene ninguna línea que empiece con "{p}"'.mapper(): (_, ctx) async {
    expect(_lineas(ctx.arg<String>(0)).where((l) => l.startsWith(ctx.arg<String>(1))), isEmpty);
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t13_config_multisede.feature', _pasos);
}
