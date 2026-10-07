// Pasos de aceptación de t06_vlsm_rango_libre.feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_calculadora/src/logic/ipv4_subnetting.dart';

import 'comun.dart';
import 'pasos_calculadora.dart';

late ResultadoVlsm _r;

void _vlsm(String red, List<int> hosts) {
  final partes = red.split('/');
  _r = calcularVlsm(partes[0], int.parse(partes[1]), [
    for (var i = 0; i < hosts.length; i++) RequerimientoVlsm('R$i', hosts[i]),
  ]);
}

final _pasos = StepRegistry<void>.fromMap({
  ...pasosCalculadora,
  'la VLSM de "{red}" con {a}, {b}, {c} y {d} hosts'.mapper(
    types: {'a': int, 'b': int, 'c': int, 'd': int},
  ): (_, ctx) async {
    _vlsm(ctx.arg<String>(0), [for (var i = 1; i <= 4; i++) ctx.arg<int>(i)]);
  },
  'la VLSM de "{red}" con {a} y {b} hosts'.mapper(
    types: {'a': int, 'b': int},
  ): (_, ctx) async {
    _vlsm(ctx.arg<String>(0), [ctx.arg<int>(1), ctx.arg<int>(2)]);
  },
  'el rango libre es "{r}"'.mapper(): (_, ctx) async {
    expect(_r.rangoLibre, ctx.arg<String>(0));
  },
  'no hay rango libre'.mapper(): (_, ctx) async {
    expect(_r.rangoLibre, isNull);
  },
});

void main() => correrFeature('t06_vlsm_rango_libre.feature', _pasos);
