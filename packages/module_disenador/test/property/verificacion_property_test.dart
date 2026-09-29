import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/verificacion.dart';

void main() {
  property(
    'un paso por VLAN, interfaz y PC, más troncal, ping entre VLAN y DHCP',
    () {
      forAll(combine2(integer(min: 1, max: 6), boolean()), (entrada) {
        final (n, l3) = entrada;
        final plan = planificarRed('10.0.0.0', 16, [
          for (var i = 0; i < n; i++) Segmento('S$i', 10),
        ], const OpcionesPlan());
        final pasos = planVerificacion(
          plan,
          OpcionesConfig(
            topologia: l3 ? Topologia.switchCapa3 : Topologia.routerOnAStick,
          ),
        );
        final esperados = 4 * n + (l3 ? 0 : 1) + (n > 1 ? 1 : 0) + 1;
        expect(pasos, hasLength(esperados));
        for (final s in plan.segmentos) {
          expect(
            pasos.where(
              (p) =>
                  p.comando == 'ping ${s.gateway}' &&
                  p.equipo == 'PC de ${s.nombre}',
            ),
            hasLength(1),
          );
        }
      });
    },
  );
}
