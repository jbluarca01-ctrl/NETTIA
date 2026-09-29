// Pasos de aceptación de t04_auditoria.feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

import 'comun.dart';

class _Mundo {
  PlanRed? plan;
  String config = '';
  List<Hallazgo> hallazgos = const [];
}

var _m = _Mundo();

String _linea(Hallazgo h) =>
    '${h.gravedad == Gravedad.critico ? 'CRÍTICO' : 'AVISO'} | '
    '${h.mensaje} | ${h.correccion.join(' / ')}';

final _pasos = StepRegistry<void>.fromMap({
  'la red base "{red}" con los segmentos "{s}"'.mapper(): (_, ctx) async {
    final [red, cidr] = ctx.arg<String>(0).split('/');
    _m.plan = planificarRed(red, int.parse(cidr), [
      for (final seg in ctx.arg<String>(1).split(','))
        Segmento(seg.split(':')[0], int.parse(seg.split(':')[1])),
    ], const OpcionesPlan());
  },
  'la running-config:'.mapper(): (_, ctx) async {
    _m.config = docString(ctx.docContent);
  },
  'audito la configuración'.mapper(): (_, ctx) async {
    _m.hallazgos = auditarConfig(_m.config, _m.plan!);
  },
  'no hay hallazgos'.mapper(): (_, ctx) async {
    expect(_m.hallazgos.map(_linea), isEmpty);
  },
  'los hallazgos son:'.mapper(): (_, ctx) async {
    expect(_m.hallazgos.map(_linea).join('\n'), docString(ctx.docContent));
  },
});

Future<void> main() async {
  setUp(() => _m = _Mundo());
  await correrFeature('t04_auditoria.feature', _pasos);
}
