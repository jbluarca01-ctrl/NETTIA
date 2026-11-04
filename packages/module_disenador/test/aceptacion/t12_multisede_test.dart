// Pasos de aceptación de t12_multisede.feature (SPEC-003 T1).
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

import 'comun.dart';

class _Mundo {
  final planes = <PlanRed>[];
  RedMultisede? red;
  DisenoException? error;
}

var _m = _Mundo();

int _router(String hostname) => int.parse(hostname.substring(1)) - 1;

void _planificar(String? enlaces, String enrutamiento) {
  try {
    _m.red = planificarMultisede(_m.planes, enlaces, Enrutamiento.values.byName(enrutamiento));
  } on DisenoException catch (e) {
    _m.error = e;
  }
}

final _pasos = StepRegistry<void>.fromMap({
  'la sede {n} "{red}" con "{segs}"'.mapper(): (_, ctx) async {
    final [red, cidr] = ctx.arg<String>(1).split('/');
    expect(_m.planes, hasLength(int.parse(ctx.arg<String>(0)) - 1));
    _m.planes.add(
      planificarRed(red, int.parse(cidr), [
        for (final s in ctx.arg<String>(2).split(',')) Segmento(s.split(':')[0], int.parse(s.split(':')[1])),
      ], const OpcionesPlan()),
    );
  },
  'planifico con la red de enlaces "{e}" y el enrutamiento "{r}"'.mapper(): (_, ctx) async {
    _planificar(ctx.arg<String>(0), ctx.arg<String>(1));
  },
  'planifico sin red de enlaces y con el enrutamiento "{r}"'.mapper(): (_, ctx) async {
    _planificar(null, ctx.arg<String>(0));
  },
  'el enlace {k} es "{red}" de "{a}" a "{b}"'.mapper(): (_, ctx) async {
    final e = _m.red!.enlaces[int.parse(ctx.arg<String>(0)) - 1];
    expect('${e.red}/30', ctx.arg<String>(1));
    expect('R${e.desde + 1} ${e.ipDesde}', ctx.arg<String>(2));
    expect('R${e.desde + 2} ${e.ipHasta}', ctx.arg<String>(3));
  },
  'el resumen de la sede {n} es "{r}"'.mapper(): (_, ctx) async {
    final (red, prefijo) = resumenDe(_m.planes[int.parse(ctx.arg<String>(0)) - 1]);
    expect('$red/$prefijo', ctx.arg<String>(1));
  },
  'las rutas de "{r}" son "{lista}"'.mapper(): (_, ctx) async {
    expect([
      for (final r in _m.red!.rutas[_router(ctx.arg<String>(0))]) '${r.red} ${r.mascara} ${r.siguienteSalto}',
    ], ctx.arg<String>(1).split(','));
  },
  '"{r}" no tiene rutas estáticas'.mapper(): (_, ctx) async {
    expect(_m.red!.rutas[_router(ctx.arg<String>(0))], isEmpty);
  },
  'las VLAN de la sede {n} son "{l}"'.mapper(): (_, ctx) async {
    expect([for (final s in _m.red!.sedes[int.parse(ctx.arg<String>(0)) - 1].segmentos) '${s.vlan}'], ctx.arg<String>(1).split(','));
  },
  'las redes OSPF de "{r}" son "{lista}"'.mapper(): (_, ctx) async {
    expect(_m.red!.redesOspf(_router(ctx.arg<String>(0))), ctx.arg<String>(1).split(','));
  },
  'el router-id de "{r}" es "{id}"'.mapper(): (_, ctx) async {
    expect(routerId(_router(ctx.arg<String>(0))), ctx.arg<String>(1));
  },
  'el diseño falla con "{m}"'.mapper(): (_, ctx) async {
    expect(_m.red, isNull);
    expect(_m.error?.mensaje, ctx.arg<String>(0));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t12_multisede.feature', _pasos);
}
