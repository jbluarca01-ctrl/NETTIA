import 'dart:math';

import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/repara.dart';

void main() {
  property('el plan al azar cumple RF1 (SPEC-001-RF1)', () {
    forAll(integer(min: 0, max: 1 << 30), (semilla) {
      final plan = planAlAzar(Random(semilla));
      final nombres = [for (final s in plan.segmentos) s.nombre];
      expect(nombres.length, inInclusiveRange(2, 3));
      expect(nombres.toSet(), hasLength(nombres.length));
      expect([for (final s in plan.segmentos) s.hostsPedidos].every((h) => h >= 5 && h <= 60), isTrue);
      expect(plan.cidrBase, 24);
      expect(RegExp(r'^192\.168\.\d{1,3}\.0$').hasMatch(plan.redBase), isTrue);
    });
  });

  property('toda falla en todo segmento deja un solo hallazgo, en su equipo (SPEC-001-RF3)', () {
    forAll(integer(min: 0, max: 1 << 30), (semilla) {
      final plan = planAlAzar(Random(semilla));
      final limpia = generarConfiguracion(plan, const OpcionesConfig());
      for (final falla in TipoFalla.values) {
        for (final s in plan.segmentos) {
          final configs = inyectarFalla(limpia, plan, falla, s);
          for (final c in configs) {
            final esperados = c.hostname == equipoDe(falla) ? 1 : 0;
            expect(auditarConfig(c.texto, plan), hasLength(esperados), reason: '$falla ${s.nombre} ${c.hostname}');
          }
        }
      }
    });
  });

  property('el ejercicio al azar trae 4 causas distintas con la correcta en su índice (SPEC-001-RF4)', () {
    forAll(integer(min: 0, max: 1 << 30), (semilla) {
      final e = ejercicioAlAzar(Random(semilla));
      expect(e.causas.toSet(), hasLength(4));
      expect(e.causas[e.indiceCorrecta], causaDe(e.falla));
      expect(e.sintoma, sintomaDe(e.falla, e.segmento, e.plan));
      expect(e.responder(e.indiceCorrecta).acierto, isTrue);
    });
  });

  property('la misma semilla da el mismo ejercicio (SPEC-001-RF8)', () {
    forAll(integer(min: 0, max: 1 << 30), (semilla) {
      final a = ejercicioAlAzar(Random(semilla));
      final b = ejercicioAlAzar(Random(semilla));
      expect(b.sintoma, a.sintoma);
      expect(b.causas, a.causas);
      expect([for (final c in b.configs) c.texto], [for (final c in a.configs) c.texto]);
    });
  });
}
