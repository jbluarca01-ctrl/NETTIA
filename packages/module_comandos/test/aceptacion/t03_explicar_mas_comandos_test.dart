// Pasos de aceptación de t03_explicar_mas_comandos.feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_comandos/src/logic/explicador_show.dart';

import 'comun.dart';

String _salida = '';
ExplicacionShow? _e;

String _linea(Hallazgo h) => '${h.nivel.name} | ${h.titulo} | ${h.detalle}';

bool _hay(Nivel nivel, String titulo) =>
    _e!.hallazgos.any((h) => h.nivel == nivel && h.titulo.startsWith(titulo));

final _pasos = StepRegistry<void>.fromMap({
  'la salida pegada:'.mapper(): (_, ctx) async {
    _salida = docString(ctx.docContent);
  },
  'la explico'.mapper(): (_, ctx) async {
    _e = explicarSalidaShow(_salida);
  },
  'el comando es "{c}"'.mapper(): (_, ctx) async {
    expect(_e!.tipo.comando, ctx.arg<String>(0));
  },
  'el resumen es "{r}"'.mapper(): (_, ctx) async {
    expect(_e!.resumen, ctx.arg<String>(0));
  },
  'los hallazgos son:'.mapper(): (_, ctx) async {
    expect(_e!.hallazgos.map(_linea).join('\n'), docString(ctx.docContent));
  },
  'hay un problema "{t}"'.mapper(): (_, ctx) async {
    expect(_hay(Nivel.problema, ctx.arg<String>(0)), isTrue);
  },
  'hay un aviso "{t}"'.mapper(): (_, ctx) async {
    expect(_hay(Nivel.aviso, ctx.arg<String>(0)), isTrue);
  },
});

void main() => correrFeature('t03_explicar_mas_comandos.feature', _pasos);
