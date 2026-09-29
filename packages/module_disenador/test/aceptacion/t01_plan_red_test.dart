// Pasos de aceptación de t01_plan_red.feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

import 'comun.dart';

class _Mundo {
  String red = '';
  int cidr = 0;
  final segmentos = <Segmento>[];
  int reservadas = 0;
  bool gatewayAlFinal = false;
  int crecimiento = 0;
  PlanRed? plan;
  String? error;
}

var _m = _Mundo();

SegmentoPlan _seg(String nombre) =>
    _m.plan!.segmentos.singleWhere((s) => s.nombre == nombre);

final _pasos = StepRegistry<void>.fromMap({
  'la red base "{red}"'.mapper(): (_, ctx) async {
    final partes = ctx.arg<String>(0).split('/');
    _m.red = partes[0];
    _m.cidr = int.parse(partes[1]);
  },
  'el segmento "{n}" con {h} hosts'.mapper(types: {'h': int}): (_, ctx) async {
    _m.segmentos.add(Segmento(ctx.arg<String>(0), ctx.arg<int>(1)));
  },
  'el segmento "{n}" con {h} hosts en la VLAN {v}'.mapper(
    types: {'h': int, 'v': int},
  ): (_, ctx) async {
    _m.segmentos.add(
      Segmento(ctx.arg<String>(0), ctx.arg<int>(1), vlan: ctx.arg<int>(2)),
    );
  },
  '{r} IPs reservadas por segmento'.mapper(types: {'r': int}): (_, ctx) async {
    _m.reservadas = ctx.arg<int>(0);
  },
  'el gateway en la última IP útil'.mapper(): (_, ctx) async {
    _m.gatewayAlFinal = true;
  },
  'un crecimiento del {p} %'.mapper(types: {'p': int}): (_, ctx) async {
    _m.crecimiento = ctx.arg<int>(0);
  },
  'planifico la red'.mapper(): (_, ctx) async {
    try {
      _m.plan = planificarRed(
        _m.red,
        _m.cidr,
        _m.segmentos,
        OpcionesPlan(
          reservadas: _m.reservadas,
          gatewayAlFinal: _m.gatewayAlFinal,
          crecimientoPct: _m.crecimiento,
        ),
      );
    } on DisenoException catch (e) {
      _m.error = e.mensaje;
    }
  },
  'el segmento "{n}" queda en la VLAN {v} con la red "{red}"'.mapper(
    types: {'v': int},
  ): (_, ctx) async {
    final s = _seg(ctx.arg<String>(0));
    expect(s.vlan, ctx.arg<int>(1));
    expect('${s.red}/${s.cidr}', ctx.arg<String>(2));
  },
  'el segmento "{n}" tiene máscara "{m}" y wildcard "{w}"'.mapper(): (
    _,
    ctx,
  ) async {
    final s = _seg(ctx.arg<String>(0));
    expect(s.mascara, ctx.arg<String>(1));
    expect(s.wildcard, ctx.arg<String>(2));
  },
  'el segmento "{n}" tiene gateway "{g}" y broadcast "{b}"'.mapper(): (
    _,
    ctx,
  ) async {
    final s = _seg(ctx.arg<String>(0));
    expect(s.gateway, ctx.arg<String>(1));
    expect(s.broadcast, ctx.arg<String>(2));
  },
  'el segmento "{n}" reparte por DHCP "{r}" con {c} direcciones'.mapper(
    types: {'c': int},
  ): (_, ctx) async {
    final s = _seg(ctx.arg<String>(0));
    expect(s.dhcp.toString(), ctx.arg<String>(1));
    expect(s.dhcp.cantidad, ctx.arg<int>(2));
  },
  'el segmento "{n}" reserva "{r}"'.mapper(): (_, ctx) async {
    expect(_seg(ctx.arg<String>(0)).reservadas.toString(), ctx.arg<String>(1));
  },
  'el segmento "{n}" no reserva direcciones'.mapper(): (_, ctx) async {
    expect(_seg(ctx.arg<String>(0)).reservadas, isNull);
  },
  'el segmento "{n}" tiene una utilización del {p} %'.mapper(
    types: {'p': int},
  ): (_, ctx) async {
    expect(_seg(ctx.arg<String>(0)).utilizacionPct, ctx.arg<int>(1));
  },
  'quedan {n} direcciones libres'.mapper(types: {'n': int}): (_, ctx) async {
    expect(_m.plan!.direccionesLibres, ctx.arg<int>(0));
  },
  'el diseño se rechaza con "{msg}"'.mapper(): (_, ctx) async {
    expect(_m.plan, isNull);
    expect(_m.error, ctx.arg<String>(0).replaceAll(r'\"', '"'));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t01_plan_red.feature', _pasos);
}
