import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

String _error(void Function() f) {
  try {
    f();
  } on DisenoException catch (e) {
    return e.mensaje;
  }
  return 'sin error';
}

PlanRed _plan(List<Segmento> s, [OpcionesPlan o = const OpcionesPlan()]) =>
    planificarRed('192.168.0.0', 24, s, o);

void main() {
  test('opciones por defecto', () {
    const o = OpcionesPlan();
    expect(o.gatewayAlFinal, isFalse);
    expect(o.reservadas, 0);
    expect(o.crecimientoPct, 0);
    expect(o.vlanNativa, 99);
  });

  test('el plan conserva red base, prefijo, opciones y avisos', () {
    const o = OpcionesPlan(reservadas: 2);
    final p = planificarRed('10.0.0.77', 24, [const Segmento('A', 5)], o);
    expect(p.redBase, '10.0.0.0');
    expect(p.cidrBase, 24);
    expect(p.opciones, same(o));
    expect(p.avisos, [
      '10.0.0.77 no es la dirección de red de /24; se usó 10.0.0.0/24.',
    ]);
    expect(p.segmentos.single.hostsPedidos, 5);
  });

  test('el crecimiento redondea hacia arriba', () {
    // 10 hosts +15 % = 11,5 → 12; +1 gateway = 13 → cabe en /28 (14 útiles).
    final p = _plan([
      const Segmento('A', 10),
    ], const OpcionesPlan(crecimientoPct: 15));
    expect(p.segmentos.single.cidr, 28);
    // 14 hosts +15 % = 16,1 → 17; +1 = 18 → ya no cabe en /28, pasa a /27.
    final q = _plan([
      const Segmento('A', 14),
    ], const OpcionesPlan(crecimientoPct: 15));
    expect(q.segmentos.single.cidr, 27);
  });

  test('una sola IP reservada se muestra como una IP', () {
    final p = _plan([
      const Segmento('A', 5),
    ], const OpcionesPlan(reservadas: 1));
    final s = p.segmentos.single;
    expect(s.gateway, '192.168.0.1');
    expect(s.reservadas.toString(), '192.168.0.2');
    expect(s.dhcp.toString(), '192.168.0.3 – 192.168.0.14');
  });

  test('gateway al final sin reservadas', () {
    // 4 hosts + gateway = 5 → /29 (6 útiles).
    final s =
        _plan([
          const Segmento('A', 4),
        ], const OpcionesPlan(gatewayAlFinal: true)).segmentos.single;
    expect(s.gateway, '192.168.0.6');
    expect(s.reservadas, isNull);
    expect(s.dhcp.toString(), '192.168.0.1 – 192.168.0.5');
    expect(s.utilizacionPct, 80);
  });

  test('las VLAN automáticas saltan la nativa', () {
    final p = _plan([
      const Segmento('A', 5),
      const Segmento('B', 5),
      const Segmento('C', 5),
    ], const OpcionesPlan(vlanNativa: 20));
    expect([for (final s in p.segmentos) s.vlan], [10, 30, 40]);
  });

  test('los nombres se recortan', () {
    expect(_plan([const Segmento('  A  ', 5)]).segmentos.single.nombre, 'A');
  });

  group('validaciones', () {
    test('sin segmentos', () {
      expect(
        _error(() => _plan([])),
        'Agrega al menos un segmento con sus hosts.',
      );
    });
    test('nombre vacío', () {
      expect(
        _error(() => _plan([const Segmento('  ', 5)])),
        'Cada segmento necesita un nombre.',
      );
    });
    test('hosts', () {
      expect(
        _error(() => _plan([const Segmento('A', 0)])),
        '"A" necesita al menos 1 host.',
      );
      expect(_plan([const Segmento('A', 1)]).segmentos.single.cidr, 30);
    });
    test('reservadas y crecimiento negativos', () {
      expect(
        _error(
          () => _plan([
            const Segmento('A', 5),
          ], const OpcionesPlan(reservadas: -1)),
        ),
        'Las IPs reservadas no pueden ser negativas.',
      );
      expect(
        _error(
          () => _plan([
            const Segmento('A', 5),
          ], const OpcionesPlan(crecimientoPct: -1)),
        ),
        'El crecimiento no puede ser negativo.',
      );
    });
    test('bordes de VLAN válidas', () {
      for (final v in [2, 1001, 1006, 4094]) {
        expect(_plan([Segmento('A', 5, vlan: v)]).segmentos.single.vlan, v);
      }
      for (final v in [0, 1, 1002, 1005, 4095]) {
        expect(
          _error(() => _plan([Segmento('A', 5, vlan: v)])),
          'La VLAN $v no es válida para "A": usa 2–1001 o 1006–4094 '
          '(la 1 y la 1002–1005 están reservadas).',
        );
      }
    });
    test('VLAN nativa inválida', () {
      expect(
        _error(
          () => _plan([
            const Segmento('A', 5),
          ], const OpcionesPlan(vlanNativa: 1002)),
        ),
        'La VLAN nativa 1002 no es válida: usa 2–1001 o 1006–4094.',
      );
      expect(
        _plan([
          const Segmento('A', 5),
        ], const OpcionesPlan(vlanNativa: 1)).segmentos.single.vlan,
        10,
      );
    });
    test('errores de la calculadora se convierten en errores de diseño', () {
      expect(
        _error(
          () => planificarRed('300.0.0.0', 24, [
            const Segmento('A', 5),
          ], const OpcionesPlan()),
        ),
        'Dirección IPv4 inválida. Se esperan 4 octetos de 0 a 255.',
      );
    });
  });

  test('toString de la excepción es su mensaje', () {
    expect(const DisenoException('x').toString(), 'x');
  });
}
