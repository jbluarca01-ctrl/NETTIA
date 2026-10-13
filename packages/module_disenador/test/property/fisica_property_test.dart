import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/fisica.dart';
import 'package:module_disenador/src/logic/opciones.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

void main() {
  property('con switches enlazados, cada VLAN cuelga una vez y los troncales '
      'coinciden en ambos extremos', () {
    forAll(
      combine3(
        integer(min: 1, max: 3),
        boolean(),
        list(
          list(integer(min: 0, max: 4), minLength: 3, maxLength: 3),
          minLength: 1,
          maxLength: 4,
        ),
      ),
      (entrada) {
        final (n, cadena, filas) = entrada;
        final pcs = {
          for (var i = 0; i < filas.length; i++) 'S$i': filas[i].sublist(0, n),
        };
        final total = [for (final l in pcs.values) l.reduce((a, b) => a + b)];
        final usados = [
          for (var i = 0; i < n; i++) pcs.values.any((l) => l[i] > 0),
        ];
        if (total.contains(0) || usados.contains(false)) return;
        final plan = planificarRed('10.0.0.0', 16, [
          for (var i = 0; i < filas.length; i++) Segmento('S$i', total[i]),
        ], const OpcionesPlan());
        final f = disenarFisica(
          plan,
          OpcionesConfig(
            switches: n,
            conexion: cadena ? Conexion.enCadena : Conexion.ambos,
            pcPorSwitch: pcs,
          ),
        );
        final colgadas = [
          for (final i in f.router)
            for (final s in i.segmentos) s.vlan,
        ];
        expect(
          colgadas..sort(),
          [for (final s in plan.segmentos) s.vlan]..sort(),
        );
        expect(f.router, hasLength(cadena ? 1 : n));
        for (final sw in f.switches) {
          for (final t in sw.troncales.where((t) => t.vecino != 'R1')) {
            final otro = f.switches.singleWhere((s) => s.hostname == t.vecino);
            final vuelta = otro.troncales.singleWhere(
              (x) => x.vecino == sw.hostname,
            );
            expect(vuelta.vlans, t.vlans);
          }
          final acceso = [for (final (s, _) in sw.acceso) s.nombre];
          final i = f.switches.indexOf(sw);
          expect(acceso, [
            for (final s in plan.segmentos)
              if (pcs[s.nombre]![i] > 0) s.nombre,
          ]);
        }
      },
    );
  });
}
