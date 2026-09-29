import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

// VENTAS: VLAN 10, 192.168.10.0/26, gateway .1.
// TI: VLAN 20, 192.168.10.64/27, gateway .65.
PlanRed _plan({int reservadas = 0}) => planificarRed('192.168.10.0', 24, const [
  Segmento('VENTAS', 50),
  Segmento('TI', 20),
], OpcionesPlan(reservadas: reservadas));

List<String> _msj(String config, {PlanRed? plan}) =>
    auditarConfig(config, plan ?? _plan()).map((h) => h.mensaje).toList();

const _ventasOk =
    'interface Vlan10\n ip address 192.168.10.1 255.255.255.192\n';
const _poolVentas =
    'ip dhcp pool VENTAS\n network 192.168.10.0 255.255.255.192\n'
    ' default-router 192.168.10.1\n';
const _tiSinGateway = 'TI: ninguna interfaz tiene el gateway 192.168.10.65.';

void main() {
  group('lectura del texto', () {
    test('ignora comentarios, líneas vacías y fines de línea CRLF', () {
      expect(
        _msj(
          'interface Vlan10\r\n!\r\n\r\n'
          ' ip address 192.168.10.1 255.255.255.192\r\n',
        ),
        [_tiSinGateway],
      );
    });

    test('una línea con sangría fuera de un bloque se ignora', () {
      expect(_msj(' ip address 192.168.10.65 255.255.255.224\n$_ventasOk'), [
        _tiSinGateway,
      ]);
    });

    test('una línea global cierra el bloque anterior', () {
      expect(
        _msj(
          'interface Vlan10\nhostname R1\n'
          ' ip address 192.168.10.1 255.255.255.192\n'
          'interface Vlan20\n ip address 192.168.10.65 255.255.255.224\n',
        ),
        ['VENTAS: ninguna interfaz tiene el gateway 192.168.10.1.'],
      );
    });
  });

  group('interfaces y gateways', () {
    test('subinterfaz sin bloque de la física: sin aviso de física', () {
      final h = auditarConfig(
        'interface Gi0/0.10\n encapsulation dot1Q 10\n'
        ' ip address 192.168.10.1 255.255.255.192\n',
        _plan(),
      );
      expect(h.single.mensaje, _tiSinGateway);
      expect(h.single.gravedad, Gravedad.critico);
      expect(h.single.correccion.first, 'interface Gi0/0.20');
    });

    test('gateway sin máscara', () {
      expect(
        _msj('interface Vlan10\n ip address 192.168.10.1\n'),
        contains(
          'VENTAS: el gateway 192.168.10.1 tiene máscara ?; '
          'el plan dice 255.255.255.192.',
        ),
      );
    });

    test('interfaz del gateway apagada', () {
      final h = auditarConfig('$_ventasOk shutdown\n', _plan());
      expect(h.first.mensaje, 'VENTAS: Vlan10 está apagada (shutdown).');
      expect(h.first.correccion, ['interface Vlan10', 'no shutdown']);
    });
  });

  group('DHCP', () {
    test('pool sin default-router', () {
      expect(
        _msj(
          'ip dhcp excluded-address 192.168.10.1\n'
          'ip dhcp pool VENTAS\n network 192.168.10.0 255.255.255.192\n',
        ),
        contains('VENTAS: el pool DHCP no entrega gateway (default-router).'),
      );
    });

    test('solo con pools no revisa interfaces', () {
      expect(_msj('ip dhcp excluded-address 192.168.10.1\n$_poolVentas'), [
        'TI: no hay pool DHCP para 192.168.10.64/27.',
      ]);
    });

    test('una exclusión con IP inválida no cuenta', () {
      expect(
        _msj('ip dhcp excluded-address x\n$_poolVentas'),
        contains(startsWith('VENTAS: el gateway 192.168.10.1 no está')),
      );
    });

    test('una exclusión con el final inválido excluye solo la primera', () {
      expect(
        _msj('ip dhcp excluded-address 192.168.10.1 x\n$_poolVentas'),
        isNot(contains(startsWith('VENTAS: el gateway'))),
      );
    });

    test('reservadas cubiertas por la exclusión no dan aviso', () {
      expect(
        _msj(
          'ip dhcp excluded-address 192.168.10.1\n'
          'ip dhcp excluded-address 192.168.10.2 192.168.10.3\n$_poolVentas',
          plan: _plan(reservadas: 2),
        ),
        ['TI: no hay pool DHCP para 192.168.10.64/27.'],
      );
    });

    test('reservadas excluidas a medias dan aviso con la corrección', () {
      final h = auditarConfig(
        'ip dhcp excluded-address 192.168.10.1 192.168.10.2\n$_poolVentas',
        _plan(reservadas: 2),
      );
      expect(
        h.first.mensaje,
        'VENTAS: las IPs reservadas 192.168.10.2 – 192.168.10.3 no están '
        'excluidas del DHCP.',
      );
      expect(h.first.correccion, [
        'ip dhcp excluded-address 192.168.10.2 192.168.10.3',
      ]);
    });
  });

  group('switch', () {
    const accesos =
        'interface Fa0/1\n switchport access vlan 10\n'
        'interface Fa0/2\n switchport access vlan 20\n';

    List<String> troncal(String lineas) => _msj(
      '${accesos}interface Gi0/1\n switchport mode trunk\n'
      ' switchport trunk native vlan 99\n$lineas',
    );

    test('nativa correcta y todas las VLAN permitidas', () {
      expect(troncal(' switchport trunk allowed vlan all\n'), isEmpty);
    });

    test('sin lista de permitidas se permiten todas', () {
      expect(troncal(''), isEmpty);
    });

    test('allowed vlan add suma a la lista anterior', () {
      expect(
        troncal(
          ' switchport trunk allowed vlan 10\n'
          ' switchport trunk allowed vlan add 20\n',
        ),
        isEmpty,
      );
    });

    test('un rango incluye sus extremos', () {
      expect(troncal(' switchport trunk allowed vlan 10-20\n'), isEmpty);
    });

    test('las partes inválidas de la lista se ignoran', () {
      expect(troncal(' switchport trunk allowed vlan x,10\n'), [
        'Gi0/1: el troncal no permite la VLAN 20 (TI).',
      ]);
    });

    test('un puerto sin VLAN de acceso no cuenta', () {
      expect(_msj('interface Fa0/1\n switchport mode access\n'), [
        'VENTAS: ningún puerto de acceso está en la VLAN 10.',
        'TI: ningún puerto de acceso está en la VLAN 20.',
      ]);
    });

    test('la VLAN de acceso de un troncal no cuenta como acceso', () {
      expect(
        _msj(
          'interface Fa0/2\n switchport access vlan 20\n'
          'interface Gi0/1\n switchport mode trunk\n'
          ' switchport trunk native vlan 99\n switchport access vlan 10\n',
        ),
        ['VENTAS: ningún puerto de acceso está en la VLAN 10.'],
      );
    });
  });
}
