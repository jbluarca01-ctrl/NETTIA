import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/aplicar.dart';
import 'package:module_disenador/src/logic/generador.dart';

const _r1 = ConfigEquipo('R1', [
  'hostname R1',
  'interface GigabitEthernet0/0/0',
  ' no shutdown',
  'exit',
  'interface GigabitEthernet0/0/0.20',
  ' description TI',
  ' encapsulation dot1Q 20',
  ' ip address 192.168.10.65 255.255.255.224',
  'exit',
  'ip dhcp excluded-address 192.168.10.65',
  'ip dhcp pool TI',
  ' network 192.168.10.64 255.255.255.224',
  ' default-router 192.168.10.65',
  'exit',
  'end',
  'write memory',
]);

const _sw = ConfigEquipo('SW1', [
  'hostname SW1',
  'interface range FastEthernet0/13 - 24',
  ' switchport access vlan 20',
  'exit',
  'interface GigabitEthernet0/1',
  ' switchport mode trunk',
  ' switchport trunk allowed vlan 10,20,99',
  'exit',
  'end',
  'write memory',
]);

List<String> _aplicar(ConfigEquipo c, List<String> comandos) => aplicarComandos(c, comandos.join('\n')).config.lineas;

/// Las líneas del bloque que empieza con [encabezado] (sin él ni su exit).
List<String> _bloque(List<String> lineas, String encabezado) {
  final i = lineas.indexOf(encabezado);
  return lineas.sublist(i + 1, lineas.indexOf('exit', i));
}

void main() {
  test('conserva el hostname y no toca la configuración original', () {
    final r = aplicarComandos(_r1, 'int g0/0/0\nshutdown');
    expect(r.config.hostname, 'R1');
    expect(_bloque(_r1.lineas, 'interface GigabitEthernet0/0/0'), [' no shutdown']);
  });

  test('shutdown y no shutdown se reemplazan entre sí, al final del bloque', () {
    final l = _aplicar(_r1, ['interface GigabitEthernet0/0/0.20', 'shutdown']);
    expect(_bloque(l, 'interface GigabitEthernet0/0/0.20'), [
      ' description TI',
      ' encapsulation dot1Q 20',
      ' ip address 192.168.10.65 255.255.255.224',
      ' shutdown',
    ]);
    final l2 = _aplicar(ConfigEquipo('R1', l), ['interface GigabitEthernet0/0/0.20', 'no shutdown']);
    expect(_bloque(l2, 'interface GigabitEthernet0/0/0.20').last, ' no shutdown');
    expect(_bloque(l2, 'interface GigabitEthernet0/0/0.20'), isNot(contains(' shutdown')));
  });

  test('cada comando de interfaz reemplaza la línea de su tipo', () {
    final l = _aplicar(_r1, [
      'interface GigabitEthernet0/0/0.20',
      'description  OTRA   COSA',
      'encapsulation dot1q 30',
      'ip address 10.0.0.1 255.0.0.0',
    ]);
    expect(_bloque(l, 'interface GigabitEthernet0/0/0.20'), [
      ' description OTRA COSA',
      ' encapsulation dot1Q 30',
      ' ip address 10.0.0.1 255.0.0.0',
    ]);
  });

  test('encapsulation con native conserva native', () {
    final l = _aplicar(_r1, ['int g0/0/0.20', 'encapsulation dot1Q 99 native']);
    expect(_bloque(l, 'interface GigabitEthernet0/0/0.20'), contains(' encapsulation dot1Q 99 native'));
  });

  test('los comandos de switch reemplazan su línea y allowed add amplía sin repetir', () {
    final l = _aplicar(_sw, [
      'interface g0/1',
      'switchport mode access',
      'switchport access vlan 5',
      'switchport trunk native vlan 99',
      'switchport trunk allowed vlan add 30,20,40',
    ]);
    expect(_bloque(l, 'interface GigabitEthernet0/1'), [
      ' switchport mode access',
      ' switchport access vlan 5',
      ' switchport trunk native vlan 99',
      ' switchport trunk allowed vlan 10,20,99,30,40',
    ]);
  });

  test('allowed vlan sin add reemplaza la lista', () {
    final l = _aplicar(_sw, ['interface GigabitEthernet0/1', 'switchport trunk allowed vlan 10,99']);
    expect(_bloque(l, 'interface GigabitEthernet0/1'), [' switchport mode trunk', ' switchport trunk allowed vlan 10,99']);
  });

  test('allowed vlan add sin lista previa no cambia nada (ya se permiten todas)', () {
    final l = _aplicar(_sw, ['interface range fa0/13 - 24', 'switchport trunk allowed vlan add 30']);
    expect(_bloque(l, 'interface range FastEthernet0/13 - 24'), [' switchport access vlan 20']);
  });

  test('los nombres abreviados se resuelven con o sin espacios en el rango', () {
    for (final nombre in ['range fa0/13-24', 'range FastEth0/13 - 24', 'RANGE f0/13 -24']) {
      final l = _aplicar(_sw, ['int $nombre', 'switchport access vlan 7']);
      expect(_bloque(l, 'interface range FastEthernet0/13 - 24'), [' switchport access vlan 7'], reason: nombre);
    }
  });

  test('un nombre sin tipo o de otro tipo no se resuelve: crea una interfaz nueva', () {
    final l = _aplicar(_r1, ['interface 0/0/0', 'shutdown', 'interface Fa0/0/0', 'shutdown']);
    expect(_bloque(l, 'interface GigabitEthernet0/0/0'), [' no shutdown']);
    expect(_bloque(l, 'interface 0/0/0'), [' shutdown']);
    expect(_bloque(l, 'interface Fa0/0/0'), [' shutdown']);
  });

  test('una interfaz nueva se crea antes de end con el nombre escrito', () {
    final l = _aplicar(_r1, ['interface Loopback0', 'ip address 1.1.1.1 255.255.255.255']);
    expect(l.sublist(l.length - 5), [
      'interface Loopback0',
      ' ip address 1.1.1.1 255.255.255.255',
      'exit',
      'end',
      'write memory',
    ]);
  });

  test('sin end, lo nuevo va al final', () {
    final l = _aplicar(const ConfigEquipo('R1', ['hostname R1']), ['ip dhcp excluded-address 1.1.1.1', 'ip dhcp pool A']);
    expect(l, ['hostname R1', 'ip dhcp excluded-address 1.1.1.1', 'ip dhcp pool A', 'exit']);
  });

  test('los pools se resuelven sin distinguir mayúsculas y aceptan sus comandos', () {
    final l = _aplicar(_r1, [
      'ip dhcp pool ti',
      'network 192.168.10.64 255.255.255.224',
      'default-router 192.168.10.66',
      'dns-server 8.8.8.8',
      'domain-name lab.local',
    ]);
    expect(_bloque(l, 'ip dhcp pool TI'), [
      ' network 192.168.10.64 255.255.255.224',
      ' default-router 192.168.10.66',
      ' dns-server 8.8.8.8',
      ' domain-name lab.local',
    ]);
  });

  test('excluded-address se agrega una sola vez, antes de end', () {
    final l = _aplicar(_r1, ['ip dhcp excluded-address 192.168.10.65', 'ip dhcp excluded-address 192.168.10.70 192.168.10.72']);
    expect(l.where((x) => x == 'ip dhcp excluded-address 192.168.10.65'), hasLength(1));
    expect(l[l.length - 3], 'ip dhcp excluded-address 192.168.10.70 192.168.10.72');
  });

  test('interface y pool cambian de bloque directamente; exit y end vuelven al modo global', () {
    final r = aplicarComandos(
      _r1,
      'int g0/0/0\nip dhcp pool TI\ndefault-router 1.1.1.1\nend\ndefault-router 2.2.2.2\nint g0/0/0\nexit\nshutdown',
    );
    expect(_bloque(r.config.lineas, 'ip dhcp pool TI'), contains(' default-router 1.1.1.1'));
    expect(r.noReconocidos, ['default-router 2.2.2.2', 'shutdown']);
  });

  test('los comandos de un modo no valen en el otro', () {
    final r = aplicarComandos(_r1, 'ip dhcp pool TI\nshutdown\nint g0/0/0\ndefault-router 1.1.1.1\nnetwork 1.0.0.0 255.0.0.0');
    expect(r.noReconocidos, ['shutdown', 'default-router 1.1.1.1', 'network 1.0.0.0 255.0.0.0']);
    expect(r.config.lineas, _r1.lineas);
  });

  test('se aceptan sin cambios enable, configure terminal, conf t, write memory, wr, vacías y comentarios', () {
    final r = aplicarComandos(_r1, 'enable\nCONFIGURE TERMINAL\nconf t\n\n   \n! nota\nwrite memory\nwr\nexit');
    expect(r.noReconocidos, isEmpty);
    expect(r.config.lineas, _r1.lineas);
  });

  test('los no reconocidos van normalizados (sin espacios de más) y en orden', () {
    final r = aplicarComandos(_r1, '  router   ospf 1 \r\nvlan 5\nip  route 0.0.0.0 0.0.0.0 1.1.1.1');
    expect(r.noReconocidos, ['router ospf 1', 'vlan 5', 'ip route 0.0.0.0 0.0.0.0 1.1.1.1']);
  });

  test('los argumentos fijos se escriben en minúsculas y los comandos en mayúsculas valen', () {
    final l = _aplicar(_sw, [
      'INTERFACE GIGABITETHERNET0/1',
      'SWITCHPORT MODE ACCESS',
      'switchport mode TRUNK',
      'ENCAPSULATION DOT1Q 99 NATIVE',
      'SWITCHPORT TRUNK ALLOWED VLAN ADD 30',
      'IP DHCP POOL ti',
      'IP DHCP EXCLUDED-ADDRESS 9.9.9.9',
    ]);
    expect(_bloque(l, 'interface GigabitEthernet0/1'), [
      ' switchport mode trunk',
      ' encapsulation dot1Q 99 native',
      ' switchport trunk allowed vlan 10,20,99,30',
    ]);
    expect(l, containsAllInOrder(['ip dhcp pool ti', 'exit', 'ip dhcp excluded-address 9.9.9.9', 'end']));
  });

  test('un nombre sin "range" no se resuelve a un rango', () {
    const sw = ConfigEquipo('SW1', ['interface range FastEthernet0/1 - 2', ' shutdown', 'exit']);
    final l = _aplicar(sw, ['int fa0/1-2', 'no shutdown']);
    expect(l, ['interface range FastEthernet0/1 - 2', ' shutdown', 'exit', 'interface fa0/1-2', ' no shutdown', 'exit']);
  });

  test('con end en la primera línea lo nuevo va antes de end', () {
    final l = _aplicar(const ConfigEquipo('R1', ['end', 'write memory']), ['ip dhcp excluded-address 1.1.1.1']);
    expect(l, ['ip dhcp excluded-address 1.1.1.1', 'end', 'write memory']);
  });

  test('un bloque en la primera línea se edita bien', () {
    const sw = ConfigEquipo('SW1', ['interface GigabitEthernet0/1', ' switchport trunk allowed vlan 10', 'exit']);
    final l = _aplicar(sw, ['int g0/1', 'switchport trunk allowed vlan add 20']);
    expect(l, ['interface GigabitEthernet0/1', ' switchport trunk allowed vlan 10,20', 'exit']);
  });

  test('un bloque al final, sin exit ni end, se edita bien', () {
    const r1 = ConfigEquipo('R1', ['hostname R1', 'interface Gi0/0', ' shutdown']);
    final l = _aplicar(r1, ['int gi0/0', 'no shutdown', 'description X']);
    expect(l, ['hostname R1', 'interface Gi0/0', ' no shutdown', ' description X']);
  });

  test('un comando incompleto no se reconoce', () {
    final r = aplicarComandos(_r1, 'interface\nint g0/0/0\nip address 1.1.1.1\nencapsulation dot1Q\nswitchport access vlan x');
    expect(r.noReconocidos, ['interface', 'ip address 1.1.1.1', 'encapsulation dot1Q', 'switchport access vlan x']);
  });
}
