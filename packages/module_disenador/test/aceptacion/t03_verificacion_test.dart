// Pasos de aceptación de t03_verificacion.feature.
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
  Topologia topologia = Topologia.routerOnAStick;
  String hostnameSwitch = 'SW1';
  List<PasoVerificacion> pasos = const [];
}

var _m = _Mundo();

String _linea(PasoVerificacion p) =>
    '${p.equipo} | ${p.comando} | ${p.esperado}';

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
  'genero el plan de verificación'.mapper(): (_, ctx) async {
    final plan = planificarRed(
      _m.red,
      _m.cidr,
      _m.segmentos,
      const OpcionesPlan(),
    );
    _m.pasos = planVerificacion(
      plan,
      OpcionesConfig(
        topologia: _m.topologia,
        hostnameSwitch: _m.hostnameSwitch,
      ),
    );
  },
  'los pasos de verificación son:'.mapper(): (_, ctx) async {
    expect(_m.pasos.map(_linea).join('\n'), docString(ctx.docContent));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t03_verificacion.feature', _pasos);
}
