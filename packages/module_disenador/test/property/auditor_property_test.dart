import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

void main() {
  property('la configuración generada del plan no tiene hallazgos', () {
    forAll(
      combine4(
        list(integer(min: 1, max: 60), minLength: 1, maxLength: 5),
        integer(min: 0, max: 4),
        boolean(),
        boolean(),
      ),
      (entrada) {
        final (hosts, reservadas, alFinal, l3) = entrada;
        final plan = planificarRed('10.0.0.0', 16, [
          for (var i = 0; i < hosts.length; i++) Segmento('S $i', hosts[i]),
        ], OpcionesPlan(reservadas: reservadas, gatewayAlFinal: alFinal));
        final equipos = generarConfiguracion(
          plan,
          OpcionesConfig(
            topologia: l3 ? Topologia.switchCapa3 : Topologia.routerOnAStick,
          ),
        );
        for (final e in equipos) {
          expect(auditarConfig(e.texto, plan).map((h) => h.mensaje), isEmpty);
        }
      },
    );
  });

  property('cualquier texto se audita sin errores', () {
    final plan = planificarRed('10.0.0.0', 24, const [
      Segmento('A', 10),
    ], const OpcionesPlan());
    forAll(string(maxLength: 300), (texto) {
      expect(() => auditarConfig(texto, plan), returnsNormally);
    });
  });
}
