import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/generador_multisede.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

void main() {
  property('cada equipo de la red generada pasa la auditoría de su sede (SPEC-003-RF10)', () {
    forAll(
      combine2(
        list(list(integer(min: 2, max: 60), minLength: 1, maxLength: 4), minLength: 2, maxLength: 6),
        constantFrom(Enrutamiento.values),
      ),
      (e) {
        final (hosts, enrutamiento) = e;
        final sedes = [
          for (var k = 0; k < hosts.length; k++)
            planificarRed('192.168.${10 * (k + 1)}.0', 24, [
              for (var j = 0; j < hosts[k].length; j++) Segmento('S$j', hosts[k][j]),
            ], const OpcionesPlan()),
        ];
        final red = planificarMultisede(sedes, '10.0.0.0/24', enrutamiento);
        final equipos = generarMultisede(red, [for (final _ in sedes) const OpcionesConfig()]);
        expect([for (final c in equipos) c.hostname], [
          for (var k = 1; k <= sedes.length; k++) ...['SW$k', 'R$k'],
        ]);
        for (var k = 0; k < sedes.length; k++) {
          for (final c in equipos.sublist(2 * k, 2 * k + 2)) {
            expect(auditarConfig(c.texto, sedes[k]), isEmpty, reason: c.hostname);
          }
          final router = equipos[2 * k + 1].lineas;
          expect(router.where((l) => l.startsWith(' description ENLACE a R')), hasLength(red.enlacesDe(k).length));
        }
      },
    );
  });
}
