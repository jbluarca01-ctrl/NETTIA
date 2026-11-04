import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

PlanRed _sede(String red, int cidr, List<Segmento> segmentos) => planificarRed(red, cidr, segmentos, const OpcionesPlan());

final _tres = [
  _sede('192.168.10.0', 24, const [Segmento('A', 50)]),
  _sede('192.168.20.0', 24, const [Segmento('A', 50)]),
  _sede('192.168.30.0', 24, const [Segmento('A', 50)]),
];

String _error(void Function() f) {
  try {
    f();
  } on DisenoException catch (e) {
    return e.mensaje;
  }
  return 'sin error';
}

void main() {
  test('la red de enlaces acepta espacios alrededor', () {
    final r = planificarMultisede(_tres, '  10.0.0.0 / 29 ', Enrutamiento.ospf);
    expect([for (final e in r.enlaces) e.red], ['10.0.0.0', '10.0.0.4']);
  });

  test('prefijos fuera de 1–32 o IP inválida piden escribir la red', () {
    for (final mal in ['10.0.0.0/33', '10.0.0.0/-1', '10.0.0.0/x', '10.0.0/30', '10.0.0.0/30/1']) {
      expect(_error(() => planificarMultisede(_tres, mal, Enrutamiento.ospf)), startsWith('Escribe la red'), reason: mal);
    }
  });

  test('/32 y /1 se leen; /32 no alcanza y /1 se solapa con las sedes', () {
    expect(
      _error(() => planificarMultisede(_tres, '10.0.0.0/32', Enrutamiento.ospf)),
      'La red de enlaces 10.0.0.0/32 no alcanza: se necesitan 2 enlaces /30.',
    );
    expect(_error(() => planificarMultisede(_tres, '128.0.0.0/1', Enrutamiento.ospf)), 'La red de enlaces se solapa con la sede 1.');
  });

  test('justo lo necesario alcanza: /29 para dos enlaces, /30 para uno', () {
    expect(planificarMultisede(_tres, '10.0.0.8/29', Enrutamiento.ospf).enlaces.last.ipHasta, '10.0.0.14');
    expect(planificarMultisede(_tres.take(2).toList(), '10.0.0.4/30', Enrutamiento.ospf).enlaces.single.ipDesde, '10.0.0.5');
  });

  test('un router del medio tiene primero el enlace al anterior y después al siguiente', () {
    final r = planificarMultisede(_tres, '10.0.0.0/29', Enrutamiento.ospf);
    expect([for (final e in r.enlacesDe(1)) e.desde], [0, 1]);
    expect([for (final e in r.enlacesDe(0)) e.desde], [0]);
    expect([for (final e in r.enlacesDe(2)) e.desde], [1]);
    expect(r.redesOspf(1), ['192.168.20.0 0.0.0.63', '10.0.0.0 0.0.0.3', '10.0.0.4 0.0.0.3']);
  });

  test('router-id por router', () {
    expect(routerId(0), '1.1.1.1');
    expect(routerId(9), '10.10.10.10');
  });

  test('con OSPF no hay rutas estáticas en ningún router', () {
    final r = planificarMultisede(_tres, '10.0.0.0/29', Enrutamiento.ospf);
    expect(r.rutas, [isEmpty, isEmpty, isEmpty]);
    expect(r.enrutamiento, Enrutamiento.ospf);
  });

  test('el resumen de segmentos sueltos cubre desde el primero hasta el último', () {
    final s = _sede('172.16.0.0', 16, const [Segmento('A', 200), Segmento('B', 200), Segmento('C', 200)]);
    expect(resumenDe(s), ('172.16.0.0', 22));
    final uno = _sede('10.1.2.0', 24, const [Segmento('A', 2)]);
    expect(resumenDe(uno), ('10.1.2.0', 29));
  });

  test('se avisa el primer solape en orden de sedes', () {
    final solapadas = [
      _sede('192.168.0.0', 16, const [Segmento('A', 5)]),
      _sede('192.168.1.0', 24, const [Segmento('A', 5)]),
      _sede('192.168.2.0', 24, const [Segmento('A', 5)]),
    ];
    expect(_error(() => planificarMultisede(solapadas, '10.0.0.0/29', Enrutamiento.ospf)), 'Las redes de la sede 1 y la sede 2 se solapan.');
  });

  test('bloques contiguos en cualquier orden no se solapan', () {
    final alReves = [
      _sede('192.168.10.128', 25, const [Segmento('A', 5)]),
      _sede('192.168.10.0', 25, const [Segmento('A', 5)]),
    ];
    expect(planificarMultisede(alReves, '192.168.9.252/30', Enrutamiento.ospf).enlaces.single.ipDesde, '192.168.9.253');
    expect(planificarMultisede(alReves, '192.168.11.0/30', Enrutamiento.ospf).enlaces, hasLength(1));
  });

  test('sedes contiguas sin solape son válidas', () {
    final contiguas = [
      _sede('192.168.10.0', 25, const [Segmento('A', 5)]),
      _sede('192.168.10.128', 25, const [Segmento('A', 5)]),
    ];
    expect(planificarMultisede(contiguas, '192.168.11.0/30', Enrutamiento.estaticaResumida).rutas[0].single.red, '192.168.10.128');
  });
}
