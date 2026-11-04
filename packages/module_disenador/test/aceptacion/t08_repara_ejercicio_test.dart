// Pasos de aceptación de t08_repara_ejercicio.feature (SPEC-001 T1).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/repara.dart';

import 'comun.dart';

class _Mundo {
  EjercicioRepara? ejercicio;
  ResultadoRepara? resultado;
}

var _m = _Mundo();

final _pasos = StepRegistry<void>.fromMap({
  'un ejercicio de la red base "{red}" con los segmentos "{s}" y la falla "{f}" en "{seg}"'.mapper(): (_, ctx) async {
    final [red, cidr] = ctx.arg<String>(0).split('/');
    final plan = planificarRed(red, int.parse(cidr), [
      for (final seg in ctx.arg<String>(1).split(','))
        Segmento(seg.split(':')[0], int.parse(seg.split(':')[1])),
    ], const OpcionesPlan());
    _m.ejercicio = armarEjercicio(
      plan,
      TipoFalla.values.byName(ctx.arg<String>(2)),
      plan.segmentos.singleWhere((s) => s.nombre == ctx.arg<String>(3)),
      Random(0),
    );
  },
  'hay {n} causas distintas'.mapper(types: {'n': int}): (_, ctx) async {
    expect(_m.ejercicio!.causas.toSet(), hasLength(ctx.arg<int>(0)));
    expect(_m.ejercicio!.causas, hasLength(ctx.arg<int>(0)));
  },
  'la causa "{c}" está entre ellas'.mapper(): (_, ctx) async {
    expect(_m.ejercicio!.causas, contains(ctx.arg<String>(0)));
  },
  'elijo la causa "{c}"'.mapper(): (_, ctx) async {
    _m.resultado = _m.ejercicio!.responder(_m.ejercicio!.causas.indexOf(ctx.arg<String>(0)));
  },
  'elijo una causa que no es la correcta'.mapper(): (_, ctx) async {
    final e = _m.ejercicio!;
    _m.resultado = e.responder(e.indiceCorrecta == 0 ? 1 : 0);
  },
  'la respuesta es correcta'.mapper(): (_, ctx) async {
    expect(_m.resultado!.acierto, isTrue);
  },
  'la respuesta es incorrecta'.mapper(): (_, ctx) async {
    expect(_m.resultado!.acierto, isFalse);
  },
  'la causa correcta mostrada es "{c}"'.mapper(): (_, ctx) async {
    expect(_m.resultado!.causaCorrecta, ctx.arg<String>(0));
  },
  'el diagnóstico es "{t}"'.mapper(): (_, ctx) async {
    expect([for (final h in _m.resultado!.hallazgos) h.mensaje], [ctx.arg<String>(0)]);
  },
  'la corrección es "{t}"'.mapper(): (_, ctx) async {
    expect(_m.resultado!.hallazgos.single.correccion.join(' / '), ctx.arg<String>(0));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t08_repara_ejercicio.feature', _pasos);
}
