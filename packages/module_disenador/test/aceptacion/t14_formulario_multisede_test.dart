// Pasos de aceptación de t14_formulario_multisede.feature (SPEC-003 T3).
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/formulario.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

import 'comun.dart';

class _Mundo {
  String red = '';
  List<(String, List<String>)> segmentos = const [];
  final sedes = <EntradaSede>[];
  String enlaces = '';
  Enrutamiento enrutamiento = Enrutamiento.estaticaResumida;
  Topologia topologia = Topologia.routerOnAStick;
  Diseno? diseno;
  String? error;
}

var _m = _Mundo();

List<(String, String)> _filas(String texto) => [for (final s in texto.split(',')) (s.split(':')[0], s.split(':')[1])];

final _pasos = StepRegistry<void>.fromMap({
  'el formulario con la red "{red}" y los segmentos "{s}"'.mapper(): (_, ctx) async {
    _m
      ..red = ctx.arg<String>(0)
      ..segmentos = [for (final (n, h) in _filas(ctx.arg<String>(1))) (n, [h])];
  },
  'la sede {k} del formulario con la red "{red}" y los segmentos "{s}"'.mapper(): (_, ctx) async {
    expect(_m.sedes, hasLength(int.parse(ctx.arg<String>(0)) - 2));
    _m.sedes.add(EntradaSede(ctx.arg<String>(1), _filas(ctx.arg<String>(2))));
  },
  'la red de enlaces del formulario es "{e}"'.mapper(): (_, ctx) async {
    _m.enlaces = ctx.arg<String>(0);
  },
  'el enrutamiento del formulario es "{r}"'.mapper(): (_, ctx) async {
    _m.enrutamiento = Enrutamiento.values.byName(ctx.arg<String>(0));
  },
  'la topología del formulario es switch capa 3'.mapper(): (_, ctx) async {
    _m.topologia = Topologia.switchCapa3;
  },
  'diseño'.mapper(): (_, ctx) async {
    try {
      _m.diseno = disenar(
        EntradaDiseno(
          redBase: _m.red,
          segmentos: _m.segmentos,
          topologia: _m.topologia,
          sedesExtra: _m.sedes,
          redEnlaces: _m.enlaces,
          enrutamiento: _m.enrutamiento,
        ),
      );
    } on DisenoException catch (e) {
      _m.error = e.mensaje;
    }
  },
  'los equipos del diseño son "{lista}"'.mapper(): (_, ctx) async {
    expect([for (final c in _m.diseno!.equipos) c.hostname], ctx.arg<String>(0).split(','));
  },
  'la verificación pide en "{e}" el comando "{c}" y espera "{t}"'.mapper(): (_, ctx) async {
    expect(
      [for (final p in _m.diseno!.verificacion) '${p.equipo}|${p.comando}|${p.esperado}'],
      contains('${ctx.arg<String>(0)}|${ctx.arg<String>(1)}|${ctx.arg<String>(2)}'),
    );
  },
  'el formulario dice "{t}"'.mapper(): (_, ctx) async {
    expect(_m.diseno, isNull);
    expect(_m.error, ctx.arg<String>(0));
  },
  'la configuración de "{e}" auditada contra su plan no tiene hallazgos'.mapper(): (_, ctx) async {
    final texto = _m.diseno!.equipos.singleWhere((c) => c.hostname == ctx.arg<String>(0)).texto;
    expect(auditarConfig(texto, _m.diseno!.planPara(texto)), isEmpty);
  },
  'un texto sin hostname se audita contra la red "{red}"'.mapper(): (_, ctx) async {
    expect(_m.diseno!.planPara('interface X').redBase, ctx.arg<String>(0));
  },
  'el diseño no tiene varios routers'.mapper(): (_, ctx) async {
    expect(_m.diseno!.red, isNull);
    expect(_m.diseno!.planPara('hostname R1').redBase, _m.diseno!.plan.redBase);
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t14_formulario_multisede.feature', _pasos);
}
