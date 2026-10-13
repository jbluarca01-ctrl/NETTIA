import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/fisica.dart';
import 'package:module_disenador/src/logic/opciones.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

void main() {
  test(
    'una lista de PC más corta que los switches vale 0 en los que faltan',
    () {
      final plan = planificarRed('10.0.0.0', 24, const [
        Segmento('A', 5),
        Segmento('B', 5),
      ], const OpcionesPlan());
      final f = disenarFisica(
        plan,
        const OpcionesConfig(
          switches: 2,
          conexion: Conexion.ambos,
          pcPorSwitch: {
            'A': [5],
            'B': [0, 5],
          },
        ),
      );
      expect([for (final (s, _) in f.switches[0].acceso) s.nombre], ['A']);
      expect([for (final (s, _) in f.switches[1].acceso) s.nombre], ['B']);
    },
  );
}
