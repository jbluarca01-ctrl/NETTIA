// Pasos de aceptación de t18_entrada_doctor.feature (SPEC-004 T4).
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/doctor_rutas.dart';
import 'package:module_disenador/src/logic/entrada_doctor.dart';
import 'package:module_disenador/src/logic/formulario.dart';

import 'comun.dart';

class _Mundo {
  Diseno? diseno;
  ResultadoDoctor? resultado;
}

var _m = _Mundo();

const _segmentos = [('A', '50'), ('B', '25'), ('C', '12'), ('D', '5')];

List<String> _de(String titulo) => [
  for (final h in _m.resultado!.bloques.singleWhere((b) => b.$1 == titulo).$2) h.mensaje,
];

final _pasos = StepRegistry<void>.fromMap({
  'el diseño del parcial desde el formulario'.mapper(): (_, ctx) async {
    _m.diseno = disenar(
      EntradaDiseno(
        redBase: '192.168.10.0/24',
        segmentos: [for (final (n, h) in _segmentos) (n, [h])],
        sedesExtra: const [EntradaSede('192.168.20.0/24', _segmentos)],
        redEnlaces: '10.0.0.0/30',
      ),
    );
  },
  'pego la configuración de "{lista}" y reviso como "{modo}"'.mapper(): (_, ctx) async {
    final texto = [
      for (final h in ctx.arg<String>(0).split(',')) _m.diseno!.equipos.singleWhere((e) => e.hostname == h).texto,
    ].join('\n');
    _m.resultado = revisarRed(texto, _m.diseno!, ModoRutas.values.byName(ctx.arg<String>(1)));
  },
  'pego y reviso como "{modo}":'.mapper(): (_, ctx) async {
    _m.resultado = revisarRed(docString(ctx.docContent), _m.diseno!, ModoRutas.values.byName(ctx.arg<String>(0)));
  },
  'los bloques son "{lista}"'.mapper(): (_, ctx) async {
    expect([for (final b in _m.resultado!.bloques) b.$1], ctx.arg<String>(0).split(','));
  },
  'ningún bloque tiene hallazgos'.mapper(): (_, ctx) async {
    expect([for (final b in _m.resultado!.bloques) ...b.$2.map((h) => h.mensaje)], isEmpty);
  },
  'el bloque "{t}" dice "{m}"'.mapper(): (_, ctx) async {
    expect(_de(ctx.arg<String>(0)), contains(ctx.arg<String>(1)));
  },
  'el camino entre sedes queda sin problemas'.mapper(): (_, ctx) async {
    expect([for (final h in _m.resultado!.camino ?? const []) h.mensaje], isEmpty);
  },
  'el camino entre sedes dice solo "{m}"'.mapper(): (_, ctx) async {
    expect([for (final h in _m.resultado!.camino!) h.mensaje], [ctx.arg<String>(0)]);
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t18_entrada_doctor.feature', _pasos);
}
