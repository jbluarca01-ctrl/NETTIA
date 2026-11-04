import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/ip.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

/// n sedes 192.168.(10k).0/24 con 1 a 4 segmentos de 2 a 60 hosts.
List<PlanRed> _sedes(List<List<int>> hosts) => [
  for (var k = 0; k < hosts.length; k++)
    planificarRed('192.168.${10 * (k + 1)}.0', 24, [
      for (var j = 0; j < hosts[k].length; j++) Segmento('S$j', hosts[k][j]),
    ], const OpcionesPlan()),
];

final _arbitrario = list(list(integer(min: 2, max: 60), minLength: 1, maxLength: 4), minLength: 2, maxLength: 6);

bool _cubre(String red, String mascara, String ip) {
  final m = ipANumero(mascara)!;
  return ipANumero(ip)! & m == ipANumero(red)!;
}

void main() {
  property('el resumen cubre todos los segmentos de la sede y queda dentro de su red base (SPEC-003-RF5)', () {
    forAll(_arbitrario, (hosts) {
      for (final sede in _sedes(hosts)) {
        final (red, prefijo) = resumenDe(sede);
        expect(prefijo, greaterThanOrEqualTo(sede.cidrBase));
        final mascara = ipATexto((0xFFFFFFFF << (32 - prefijo)) & 0xFFFFFFFF);
        expect(_cubre(sede.redBase, ipATexto((0xFFFFFFFF << (32 - sede.cidrBase)) & 0xFFFFFFFF), red), isTrue);
        for (final s in sede.segmentos) {
          expect(_cubre(red, mascara, s.red) && _cubre(red, mascara, s.broadcast), isTrue);
        }
      }
    });
  });

  property('cada router llega a cada sede remota por su vecino de ese lado (SPEC-003-RF6, RF7, RF9)', () {
    forAll(combine2(_arbitrario, constantFrom([Enrutamiento.estaticaResumida, Enrutamiento.estaticaPorSubred])), (e) {
      final (hosts, enrutamiento) = e;
      final sedes = _sedes(hosts);
      final r = planificarMultisede(sedes, '10.0.0.0/24', enrutamiento);
      expect(r.enlaces, hasLength(sedes.length - 1));
      for (var i = 0; i < sedes.length; i++) {
        final vecinos = {
          if (i > 0) r.enlaces[i - 1].ipDesde,
          if (i < sedes.length - 1) r.enlaces[i].ipHasta,
        };
        for (final ruta in r.rutas[i]) {
          expect(vecinos, contains(ruta.siguienteSalto));
        }
        for (var j = 0; j < sedes.length; j++) {
          for (final s in sedes[j].segmentos) {
            final cubierta = r.rutas[i].any((ruta) => _cubre(ruta.red, ruta.mascara, s.red));
            expect(cubierta, j != i, reason: 'R${i + 1} → sede ${j + 1} ${s.red}');
          }
        }
      }
    });
  });

  property('los enlaces son /30 distintos y consecutivos, con IPs .1 y .2 de cada bloque (SPEC-003-RF3)', () {
    forAll(integer(min: 2, max: 6), (n) {
      final r = planificarMultisede(_sedes(List.filled(n, [10])), '10.0.0.0/24', Enrutamiento.ospf);
      for (var k = 0; k < r.enlaces.length; k++) {
        final base = ipANumero('10.0.0.0')! + 4 * k;
        expect(r.enlaces[k].desde, k);
        expect([r.enlaces[k].red, r.enlaces[k].ipDesde, r.enlaces[k].ipHasta], [ipATexto(base), ipATexto(base + 1), ipATexto(base + 2)]);
      }
    });
  });
}
