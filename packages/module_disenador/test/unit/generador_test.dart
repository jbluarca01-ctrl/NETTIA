import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

PlanRed _plan(List<Segmento> segmentos, {int reservadas = 0}) => planificarRed(
  '10.0.0.0',
  24,
  segmentos,
  OpcionesPlan(reservadas: reservadas),
);

List<String> _lineas(List<ConfigEquipo> equipos, String hostname) =>
    equipos.singleWhere((e) => e.hostname == hostname).lineas;

void main() {
  group('nombreIos', () {
    test('quita tildes, eñes y diéresis', () {
      expect(nombreIos('áéíóú üñ'), 'AEIOU_UN');
    });

    test('quita guiones bajos sobrantes en los extremos', () {
      expect(nombreIos('  ¡Hola, mundo!  '), 'HOLA_MUNDO');
    });

    test('conserva los dígitos', () {
      expect(nombreIos('lab 2b'), 'LAB_2B');
    });
  });

  group('rangosDeAcceso', () {
    test('un puerto por segmento cuando alcanzan justo', () {
      final plan = _plan(const [
        Segmento('A', 5),
        Segmento('B', 5),
        Segmento('C', 5),
      ]);
      expect(rangosDeAcceso(plan, const OpcionesConfig(puertosAcceso: 3)), [
        'FastEthernet0/1 - 1',
        'FastEthernet0/2 - 2',
        'FastEthernet0/3 - 3',
      ]);
    });

    test('reparte en partes iguales y deja el resto sin usar', () {
      final plan = _plan(const [Segmento('A', 5), Segmento('B', 5)]);
      expect(
        rangosDeAcceso(
          plan,
          const OpcionesConfig(
            puertosAcceso: 5,
            prefijoAcceso: 'GigabitEthernet1/0/',
          ),
        ),
        ['GigabitEthernet1/0/1 - 2', 'GigabitEthernet1/0/3 - 4'],
      );
    });
  });

  group('generarConfiguracion', () {
    test('sin DNS ni dominio no agrega esas líneas al pool', () {
      final equipos = generarConfiguracion(
        _plan(const [Segmento('A', 5)]),
        const OpcionesConfig(),
      );
      final r1 = _lineas(equipos, 'R1');
      expect(r1.where((l) => l.startsWith(' dns-server')), isEmpty);
      expect(r1.where((l) => l.startsWith(' domain-name')), isEmpty);
    });

    test('solo el DNS agrega dns-server sin domain-name', () {
      final r1 = _lineas(
        generarConfiguracion(
          _plan(const [Segmento('A', 5)]),
          const OpcionesConfig(dns: '1.1.1.1'),
        ),
        'R1',
      );
      expect(r1, contains(' dns-server 1.1.1.1'));
      expect(r1.where((l) => l.startsWith(' domain-name')), isEmpty);
    });

    test('usa los nombres de equipo e interfaces indicados', () {
      final equipos = generarConfiguracion(
        _plan(const [Segmento('A', 5)]),
        const OpcionesConfig(
          hostnameSwitch: 'ACC1',
          hostnameRouter: 'BORDE',
          troncalSwitch: 'GigabitEthernet0/2',
          interfazRouter: 'GigabitEthernet0/1',
        ),
      );
      expect(equipos.map((e) => e.hostname), ['ACC1', 'BORDE']);
      expect(
        _lineas(equipos, 'ACC1'),
        contains('interface GigabitEthernet0/2'),
      );
      expect(
        _lineas(equipos, 'BORDE'),
        contains('interface GigabitEthernet0/1.10'),
      );
    });

    test('las reservadas se excluyen del DHCP en router-on-a-stick', () {
      final r1 = _lineas(
        generarConfiguracion(
          _plan(const [Segmento('A', 5)], reservadas: 2),
          const OpcionesConfig(),
        ),
        'R1',
      );
      expect(r1, contains('ip dhcp excluded-address 10.0.0.2 10.0.0.3'));
    });

    test('el texto une las líneas con saltos de línea', () {
      expect(const ConfigEquipo('X', ['a', 'b']).texto, 'a\nb');
    });
  });
}
