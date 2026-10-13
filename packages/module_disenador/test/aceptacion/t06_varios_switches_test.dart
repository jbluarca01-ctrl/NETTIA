// Pasos de aceptación de t06_varios_switches.feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/verificacion.dart';

import 'comun.dart';

class _Mundo {
  String red = '';
  int cidr = 0;
  final segmentos = <Segmento>[];
  final pcPorSwitch = <String, List<int>>{};
  int switches = 1;
  Conexion conexion = Conexion.alRouter;
  List<ConfigEquipo>? equipos;
  List<PasoVerificacion>? pasos;
  String? error;
}

var _m = _Mundo();

const _conexiones = {
  'cada uno al router': Conexion.alRouter,
  'en cadena': Conexion.enCadena,
  'ambos': Conexion.ambos,
};

String _config(String hostname) =>
    _m.equipos!.singleWhere((e) => e.hostname == hostname).texto;

OpcionesConfig _opciones() => OpcionesConfig(
  switches: _m.switches,
  conexion: _m.conexion,
  pcPorSwitch: _m.pcPorSwitch,
);

PlanRed _plan() =>
    planificarRed(_m.red, _m.cidr, _m.segmentos, const OpcionesPlan());

final _pasos = StepRegistry<void>.fromMap({
  'la red base "{red}" con las PC por switch "{s}"'.mapper(): (_, ctx) async {
    final partes = ctx.arg<String>(0).split('/');
    _m.red = partes[0];
    _m.cidr = int.parse(partes[1]);
    for (final seg in ctx.arg<String>(1).split(',')) {
      final [nombre, pcs] = seg.split(':');
      final porSwitch = pcs.split('+').map(int.parse).toList();
      _m.segmentos.add(Segmento(nombre, porSwitch.reduce((a, b) => a + b)));
      _m.pcPorSwitch[nombre] = porSwitch;
    }
  },
  '{n} switches conectados "{c}"'.mapper(types: {'n': int}): (_, ctx) async {
    _m.switches = ctx.arg<int>(0);
    _m.conexion = _conexiones[ctx.arg<String>(1)]!;
  },
  'genero la configuración'.mapper(): (_, ctx) async {
    try {
      _m.equipos = generarConfiguracion(_plan(), _opciones());
    } on DisenoException catch (e) {
      _m.error = e.mensaje;
    }
  },
  'genero el plan de verificación'.mapper(): (_, ctx) async {
    _m.pasos = planVerificacion(_plan(), _opciones());
  },
  'se generan los equipos "{e}"'.mapper(): (_, ctx) async {
    expect(_m.equipos!.map((e) => e.hostname).join(','), ctx.arg<String>(0));
  },
  'la configuración de "{h}" incluye:'.mapper(): (_, ctx) async {
    expect(_config(ctx.arg<String>(0)), contains(docString(ctx.docContent)));
  },
  'la configuración de "{h}" tiene {n} {veces} "{t}"'.mapper(
    types: {'n': int},
  ): (_, ctx) async {
    expect(
      ctx.arg<String>(3).allMatches(_config(ctx.arg<String>(0))),
      hasLength(ctx.arg<int>(1)),
    );
  },
  'la generación se rechaza con "{msg}"'.mapper(): (_, ctx) async {
    expect(_m.equipos, isNull);
    expect(_m.error, ctx.arg<String>(0));
  },
  'la verificación incluye los pasos:'.mapper(): (_, ctx) async {
    final lineas = [
      for (final p in _m.pasos!) '${p.equipo} | ${p.comando} | ${p.esperado}',
    ];
    for (final l in docString(ctx.docContent).split('\n')) {
      expect(lineas, contains(l));
    }
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t06_varios_switches.feature', _pasos);
}
