import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

void main() {
  property('nombreIos siempre da un nombre que IOS acepta', () {
    forAll(string(maxLength: 40), (nombre) {
      final s = nombreIos(nombre);
      expect(RegExp(r'^[A-Z0-9_]*$').hasMatch(s), isTrue);
      expect(s.startsWith('_') || s.endsWith('_'), isFalse);
      expect(s.contains('__'), isFalse);
    });
  });

  property('los rangos de acceso no se solapan y caben en el switch', () {
    forAll(combine2(integer(min: 1, max: 6), integer(min: 1, max: 48)), (
      entrada,
    ) {
      final (n, puertos) = entrada;
      final plan = planificarRed('10.0.0.0', 16, [
        for (var i = 0; i < n; i++) Segmento('S$i', 10),
      ], const OpcionesPlan());
      final o = OpcionesConfig(puertosAcceso: puertos);
      if (puertos < n) {
        expect(() => rangosDeAcceso(plan, o), throwsA(isA<DisenoException>()));
        return;
      }
      var ultimo = 0;
      for (final r in rangosDeAcceso(plan, o)) {
        final [desde, hasta] =
            r
                .substring('FastEthernet0/'.length)
                .split(' - ')
                .map(int.parse)
                .toList();
        expect(desde, ultimo + 1);
        expect(hasta, greaterThanOrEqualTo(desde));
        ultimo = hasta;
      }
      expect(ultimo, lessThanOrEqualTo(puertos));
    });
  });

  property('cada submodo de la configuración se cierra con exit', () {
    forAll(combine2(integer(min: 1, max: 6), boolean()), (entrada) {
      final (n, l3) = entrada;
      final plan = planificarRed('10.0.0.0', 16, [
        for (var i = 0; i < n; i++) Segmento('S$i', 10),
      ], const OpcionesPlan());
      final equipos = generarConfiguracion(
        plan,
        OpcionesConfig(
          topologia: l3 ? Topologia.switchCapa3 : Topologia.routerOnAStick,
          dns: '8.8.8.8',
        ),
      );
      final submodo = RegExp(r'^(vlan |interface |ip dhcp pool )');
      for (final e in equipos) {
        var abierto = false;
        for (final l in e.lineas.where((l) => !l.startsWith(' '))) {
          if (abierto) {
            expect(l, 'exit');
            abierto = false;
          } else {
            expect(l, isNot('exit'));
            abierto = submodo.hasMatch(l);
          }
        }
        expect(abierto, isFalse);
      }
    });
  });
}
