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
}
