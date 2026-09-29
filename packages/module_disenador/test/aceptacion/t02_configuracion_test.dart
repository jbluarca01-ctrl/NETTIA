// Pasos de aceptación de t02_configuracion.feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

import 'comun.dart';

class _Mundo {
  String red = '';
  int cidr = 0;
  final segmentos = <Segmento>[];
  int reservadas = 0;
  bool gatewayAlFinal = false;
  Topologia topologia = Topologia.routerOnAStick;
  String hostnameSwitch = 'SW1';
  int puertos = 24;
  String dns = '';
  String dominio = '';
  String clave = '';
  List<ConfigEquipo>? equipos;
  String? error;
}

var _m = _Mundo();

String _config(String hostname) =>
    _m.equipos!.singleWhere((e) => e.hostname == hostname).texto;

final _pasos = StepRegistry<void>.fromMap({
  'la red base "{red}" con los segmentos "{s}"'.mapper(): (_, ctx) async {
    final partes = ctx.arg<String>(0).split('/');
    _m.red = partes[0];
    _m.cidr = int.parse(partes[1]);
    for (final seg in ctx.arg<String>(1).split(',')) {
      final [nombre, hosts] = seg.split(':');
      _m.segmentos.add(Segmento(nombre, int.parse(hosts)));
    }
  },
  'la topología router-on-a-stick'.mapper(): (_, ctx) async {
    _m.topologia = Topologia.routerOnAStick;
  },
  'la topología switch capa 3 con hostname "{h}"'.mapper(): (_, ctx) async {
    _m.topologia = Topologia.switchCapa3;
    _m.hostnameSwitch = ctx.arg<String>(0);
  },
  'el DNS "{d}" y el dominio "{dom}"'.mapper(): (_, ctx) async {
    _m.dns = ctx.arg<String>(0);
    _m.dominio = ctx.arg<String>(1);
  },
  'la clave de enable "{c}"'.mapper(): (_, ctx) async {
    _m.clave = ctx.arg<String>(0);
  },
  '{r} IPs reservadas y el gateway al final'.mapper(types: {'r': int}): (
    _,
    ctx,
  ) async {
    _m.reservadas = ctx.arg<int>(0);
    _m.gatewayAlFinal = true;
  },
  '{p} puertos de acceso en el switch'.mapper(types: {'p': int}): (
    _,
    ctx,
  ) async {
    _m.puertos = ctx.arg<int>(0);
  },
  'genero la configuración'.mapper(): (_, ctx) async {
    try {
      final plan = planificarRed(
        _m.red,
        _m.cidr,
        _m.segmentos,
        OpcionesPlan(
          reservadas: _m.reservadas,
          gatewayAlFinal: _m.gatewayAlFinal,
        ),
      );
      _m.equipos = generarConfiguracion(
        plan,
        OpcionesConfig(
          topologia: _m.topologia,
          hostnameSwitch: _m.hostnameSwitch,
          puertosAcceso: _m.puertos,
          dns: _m.dns,
          dominio: _m.dominio,
          enableSecret: _m.clave,
        ),
      );
    } on DisenoException catch (e) {
      _m.error = e.mensaje;
    }
  },
  'se generan {n} equipos'.mapper(types: {'n': int}): (_, ctx) async {
    expect(_m.equipos, hasLength(ctx.arg<int>(0)));
  },
  'la configuración de "{h}" es:'.mapper(): (_, ctx) async {
    expect(_config(ctx.arg<String>(0)), docString(ctx.docContent));
  },
  'la configuración de "{h}" contiene "{t}"'.mapper(): (_, ctx) async {
    expect(
      _config(ctx.arg<String>(0)).split('\n'),
      contains(ctx.arg<String>(1)),
    );
  },
  'la generación se rechaza con "{msg}"'.mapper(): (_, ctx) async {
    expect(_m.equipos, isNull);
    expect(_m.error, ctx.arg<String>(0));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t02_configuracion.feature', _pasos);
}
