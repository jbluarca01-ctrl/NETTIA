// Pasos de aceptación de t16_doctor_rutas.feature (SPEC-004 T2).
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/doctor_rutas.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/generador_multisede.dart';
import 'package:module_disenador/src/logic/lectura_config.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/tabla_rutas.dart';

import 'comun.dart';

class _Mundo {
  RedMultisede? red;
  final esperadas = <String, ConfigEquipo>{};
  final textos = <String, List<String>>{};
  final porRouter = <String, List<Hallazgo>>{};
  List<Hallazgo> camino = const [];
  List<Hallazgo> tabla = const [];
}

var _m = _Mundo();

int _indice(String hostname) => int.parse(hostname.substring(1)) - 1;

List<String> _mensajes(List<Hallazgo> hs) => [for (final h in hs) h.mensaje];

/// Índice de la línea de [hostname] que, sin sangría, es [linea].
int _linea(String hostname, String linea) {
  final i = _m.textos[hostname]!.indexWhere((l) => l.trim() == linea);
  expect(i, isNot(-1), reason: 'no está "$linea" en $hostname');
  return i;
}

String _sangria(String l) => l.substring(0, l.length - l.trimLeft().length);

PlanRed _sede(String red) => planificarRed(red, 24, const [
  Segmento('A', 50),
  Segmento('B', 25),
  Segmento('C', 12),
  Segmento('D', 5),
], const OpcionesPlan());

final _pasos = StepRegistry<void>.fromMap({
  'el diseño del parcial con el enrutamiento "{e}"'.mapper(): (_, ctx) async {
    _m.red = planificarMultisede(
      [_sede('192.168.10.0'), _sede('192.168.20.0')],
      '10.0.0.0/30',
      Enrutamiento.values.byName(ctx.arg<String>(0)),
    );
    for (final c in generarMultisede(_m.red!, const [OpcionesConfig(), OpcionesConfig()])) {
      _m.esperadas[c.hostname] = c;
      _m.textos[c.hostname] = [...c.lineas];
    }
  },
  'el diseño de tres sedes con el enrutamiento "{e}"'.mapper(): (_, ctx) async {
    _m.red = planificarMultisede(
      [_sede('192.168.10.0'), _sede('192.168.20.0'), planificarRed('192.168.30.0', 24, const [Segmento('A', 50)], const OpcionesPlan())],
      '10.0.0.0/29',
      Enrutamiento.values.byName(ctx.arg<String>(0)),
    );
    for (final c in generarMultisede(_m.red!, const [OpcionesConfig(), OpcionesConfig(), OpcionesConfig()])) {
      _m.esperadas[c.hostname] = c;
      _m.textos[c.hostname] = [...c.lineas];
    }
  },
  'la corrección de "{h}" es "{c}"'.mapper(): (_, ctx) async {
    expect(_m.porRouter[ctx.arg<String>(0)]!.single.correccion.join(';'), ctx.arg<String>(1));
  },
  'la corrección del hallazgo "{m}" es "{c}"'.mapper(): (_, ctx) async {
    final h = _m.porRouter.values.expand((x) => x).firstWhere((h) => h.mensaje == ctx.arg<String>(0));
    expect(h.correccion.join(';'), ctx.arg<String>(1));
  },
  'el camino entre sedes tiene {n} problemas'.mapper(): (_, ctx) async {
    expect(_m.camino, hasLength(int.parse(ctx.arg<String>(0))));
  },
  // SPEC-004 T3 (t17_tabla_rutas.feature).
  'reviso la tabla de "{h}":'.mapper(): (_, ctx) async {
    _m.tabla = diagnosticarTabla(leerTabla(docString(ctx.docContent)), _indice(ctx.arg<String>(0)), _m.red!);
  },
  'la corrección de la tabla es "{c}"'.mapper(): (_, ctx) async {
    expect(_m.tabla.single.correccion.join(';'), ctx.arg<String>(0));
  },
  'la tabla no tiene problemas'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.tabla), isEmpty);
  },
  'la tabla dice solo "{m}"'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.tabla), [ctx.arg<String>(0)]);
  },
  'en "{h}" cambio "{a}" por "{b}"'.mapper(): (_, ctx) async {
    final h = ctx.arg<String>(0);
    final i = _linea(h, ctx.arg<String>(1));
    _m.textos[h]![i] = '${_sangria(_m.textos[h]![i])}${ctx.arg<String>(2)}';
  },
  'en "{h}" pongo "{l}" después de "{a}"'.mapper(): (_, ctx) async {
    final h = ctx.arg<String>(0);
    final i = _linea(h, ctx.arg<String>(2));
    _m.textos[h]!.insert(i + 1, '${_sangria(_m.textos[h]![i])}${ctx.arg<String>(1)}');
  },
  'en "{h}" quito "{l}"'.mapper(): (_, ctx) async {
    final h = ctx.arg<String>(0);
    _m.textos[h]!.removeAt(_linea(h, ctx.arg<String>(1)));
  },
  'reviso "{lista}" como "{modo}"'.mapper(): (_, ctx) async {
    final modo = ModoRutas.values.byName(ctx.arg<String>(1));
    final pegados = <int, ConfigLeida>{};
    for (final h in ctx.arg<String>(0).split(',')) {
      final real = leerConfig(_m.textos[h]!.join('\n'));
      pegados[_indice(h)] = real;
      _m.porRouter[h] = diagnosticarRouter(real, leerConfig(_m.esperadas[h]!.texto), _indice(h), _m.red!, modo);
    }
    _m.camino = diagnosticarCamino(pegados, _m.red!, modo);
  },
  'el doctor no dice nada de "{h}"'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.porRouter[ctx.arg<String>(0)]!), isEmpty);
  },
  'el doctor dice de "{h}" solo "{m}"'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.porRouter[ctx.arg<String>(0)]!), [ctx.arg<String>(1)]);
  },
  'el doctor dice de "{h}" "{m}"'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.porRouter[ctx.arg<String>(0)]!), contains(ctx.arg<String>(1)));
  },
  'la corrección es "{c}"'.mapper(): (_, ctx) async {
    final h = _m.porRouter.values.expand((x) => x).single;
    expect(h.correccion.join(';'), ctx.arg<String>(0));
  },
  'el camino entre sedes no tiene problemas'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.camino), isEmpty);
  },
  'el camino entre sedes dice solo "{m}"'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.camino), [ctx.arg<String>(0)]);
  },
  'el camino entre sedes dice "{m}"'.mapper(): (_, ctx) async {
    expect(_mensajes(_m.camino), contains(ctx.arg<String>(0)));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t16_doctor_rutas.feature', _pasos);
  await correrFeature('t17_tabla_rutas.feature', _pasos);
}
