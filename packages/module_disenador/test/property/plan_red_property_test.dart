import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/ip.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

void main() {
  property('todo plan válido respeta las invariantes de direccionamiento', () {
    forAll(
      combine4(
        list(integer(min: 1, max: 60), minLength: 1, maxLength: 6),
        integer(min: 0, max: 5),
        integer(min: 0, max: 50),
        boolean(),
      ),
      (entrada) {
        final (hosts, reservadas, crecimiento, alFinal) = entrada;
        final plan = planificarRed(
          '10.0.0.0',
          16,
          [for (var i = 0; i < hosts.length; i++) Segmento('S$i', hosts[i])],
          OpcionesPlan(
            reservadas: reservadas,
            crecimientoPct: crecimiento,
            gatewayAlFinal: alFinal,
          ),
        );
        final base = RangoIp(
          ipANumero('10.0.0.0')!,
          ipANumero('10.0.255.255')!,
        );
        final bloques = <RangoIp>[];
        for (final s in plan.segmentos) {
          final bloque = RangoIp(ipANumero(s.red)!, ipANumero(s.broadcast)!);
          expect(
            base.contiene(bloque.desde) && base.contiene(bloque.hasta),
            isTrue,
          );
          for (final otro in bloques) {
            expect(
              bloque.hasta < otro.desde || bloque.desde > otro.hasta,
              isTrue,
            );
          }
          bloques.add(bloque);

          final gw = ipANumero(s.gateway)!;
          expect(gw > bloque.desde && gw < bloque.hasta, isTrue);
          expect(s.dhcp.contiene(gw), isFalse);
          expect(
            s.dhcp.desde > bloque.desde && s.dhcp.hasta < bloque.hasta,
            isTrue,
          );
          final res = s.reservadas;
          if (res != null) {
            expect(res.cantidad, reservadas);
            expect(res.contiene(gw), isFalse);
            expect(res.hasta < s.dhcp.desde, isTrue);
          }
          final conCrecimiento =
              (s.hostsPedidos * (100 + crecimiento) + 99) ~/ 100;
          expect(s.dhcp.cantidad, greaterThanOrEqualTo(conCrecimiento));
        }
        final vlans = {for (final s in plan.segmentos) s.vlan};
        expect(vlans, hasLength(hosts.length));
        expect(vlans.contains(99), isFalse);
      },
    );
  });

  property('la explicación pide el bloque más chico donde cabe', () {
    forAll(
      combine3(
        integer(min: 1, max: 300),
        integer(min: 0, max: 5),
        integer(min: 0, max: 50),
      ),
      (entrada) {
        final (hosts, reservadas, crecimiento) = entrada;
        final s = planificarRed('10.0.0.0', 16, [
          Segmento('S', hosts),
        ], OpcionesPlan(reservadas: reservadas, crecimientoPct: crecimiento))
            .segmentos
            .single;
        final m = RegExp(
          r'^Necesita (\d+) direcciones \((\d+) hosts.* \+ 1 gateway\) → '
          r'/(\d+) con (\d+) útiles\.$',
        ).firstMatch(s.explicacion)!;
        final necesarias = int.parse(m[1]!);
        final utiles = int.parse(m[4]!);
        expect(int.parse(m[2]!), greaterThanOrEqualTo(hosts));
        expect(int.parse(m[3]!), s.cidr);
        expect(utiles, (1 << (32 - s.cidr)) - 2);
        expect(necesarias, lessThanOrEqualTo(utiles));
        expect(necesarias, greaterThan((1 << (31 - s.cidr)) - 2));
      },
    );
  });
}
