// Pasos de aceptación de t01_doctor_consola.feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_comandos/src/logic/doctor_consola.dart';

import 'comun.dart';

String _salida = '';
List<Diagnostico> _diagnosticos = const [];

String _linea(Diagnostico d) =>
    '${d.titulo} | ${d.causa} | ${d.solucion.join(' / ')}';

final _pasos = StepRegistry<void>.fromMap({
  'la salida de consola:'.mapper(): (_, ctx) async {
    _salida = ctx.docContent!;
  },
  'la diagnostico'.mapper(): (_, ctx) async {
    _diagnosticos = diagnosticarConsola(_salida);
  },
  'los diagnósticos son:'.mapper(): (_, ctx) async {
    expect(_diagnosticos.map(_linea).join('\n'), ctx.docContent!.trim());
  },
  'no hay diagnósticos'.mapper(): (_, ctx) async {
    expect(_diagnosticos, isEmpty);
  },
});

Future<void> main() async {
  setUp(() {
    _salida = '';
    _diagnosticos = const [];
  });
  await correrFeature('t01_doctor_consola.feature', _pasos);
}
