import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';

void main() {
  const config = '''
hostname SW-CORE-01
ip domain-name empresa-real.com
enable secret 5 \$1\$abcd\$XyZ123hashhash
enable password miclave123
username admin privilege 15 secret 9 \$9\$hashultra
username soporte password 7 0822455D0A16
snmp-server community publica-real RO
tacacs-server key 7 060506324F41
line vty 0 4
 password cisco123
interface GigabitEthernet0/0
 description Enlace a SW-CORE-01
 ip address 203.0.114.10 255.255.255.252
interface GigabitEthernet0/1
 ip address 192.168.10.1 255.255.255.0
ip route 0.0.0.0 0.0.0.0 203.0.114.9
access-list 10 permit 10.0.0.0 0.0.0.255
''';

  test('oculta secretos de configuración y conserva el comando', () {
    final r = sanitizarDatosSensibles(config);
    final t = r.texto;
    expect(t, contains('enable secret 5 <OCULTO>'));
    expect(t, contains('enable password <OCULTO>'));
    expect(t, contains('username admin privilege 15 secret 9 <OCULTO>'));
    expect(t, contains('username soporte password 7 <OCULTO>'));
    expect(t, contains('snmp-server community <OCULTO> RO'));
    expect(t, contains('tacacs-server key 7 <OCULTO>'));
    expect(t, contains(' password <OCULTO>')); // línea vty
    for (final secreto in <String>[
      'miclave123',
      'hashhash',
      'hashultra',
      '0822455D0A16',
      'publica-real',
      '060506324F41',
      'cisco123',
    ]) {
      expect(t, isNot(contains(secreto)), reason: secreto);
    }
  });

  test('IPs públicas → marcadores consistentes; privadas y máscaras intactas', () {
    final t = sanitizarDatosSensibles(config).texto;
    expect(t, contains('ip address IP-PUBLICA-1 255.255.255.252'));
    expect(t, contains('ip route 0.0.0.0 0.0.0.0 IP-PUBLICA-2'));
    expect(t, contains('192.168.10.1 255.255.255.0'));
    expect(t, contains('permit 10.0.0.0 0.0.0.255'));
    expect(t, isNot(contains('203.0.114')));
  });

  test('la misma IP pública recibe siempre el mismo marcador', () {
    final t = sanitizarDatosSensibles('ping 8.8.8.8 y luego 8.8.4.4 y otra vez 8.8.8.8').texto;
    expect(t, 'ping IP-PUBLICA-1 y luego IP-PUBLICA-2 y otra vez IP-PUBLICA-1');
  });

  test('hostname y dominio se ocultan también donde reaparecen', () {
    final t = sanitizarDatosSensibles(config).texto;
    expect(t, contains('hostname HOST-1'));
    expect(t, contains('description Enlace a HOST-1'));
    expect(t, contains('ip domain-name DOMINIO.LOCAL'));
    expect(t, isNot(contains('SW-CORE-01')));
    expect(t, isNot(contains('empresa-real')));
  });

  test('no destruye palabras corrientes ni la pregunta', () {
    const pregunta = 'hostname switch\n¿Cómo configuro el switch y el router para una VLAN?';
    final r = sanitizarDatosSensibles(pregunta);
    expect(r.texto, contains('¿Cómo configuro el switch y el router para una VLAN?'));
  });

  test('claves de API, claves privadas y "password: valor" en texto libre', () {
    final r = sanitizarDatosSensibles(
      'mi key es sk-abcdefghijklmnopqrstuvwxyz1234 y password: hunter2\n'
      '-----BEGIN RSA PRIVATE KEY-----\nMIIEow...\n-----END RSA PRIVATE KEY-----',
    );
    expect(r.texto, contains('<CLAVE-API-OCULTA>'));
    expect(r.texto, contains('password: <OCULTO>'));
    expect(r.texto, contains('<CLAVE-PRIVADA-OCULTA>'));
    expect(r.texto, isNot(contains('hunter2')));
    expect(r.texto, isNot(contains('MIIEow')));
  });

  test('un texto sin datos sensibles queda idéntico', () {
    const limpio = '¿Cómo divido 192.168.1.0/24 en 16 subredes? Uso 10.0.0.0 y 172.16.5.1.';
    final r = sanitizarDatosSensibles(limpio);
    expect(r.texto, limpio);
    expect(r.total, 0);
  });

  test('los rangos de documentación y las máscaras no cuentan como públicas', () {
    final r = sanitizarDatosSensibles('203.0.113.5 198.51.100.7 192.0.2.1 255.255.255.0 0.0.0.255');
    expect(r.total, 0);
  });

  test('el resumen cuenta por categoría', () {
    final r = sanitizarDatosSensibles(config);
    expect(r.total, greaterThan(8));
    expect(r.resumen, contains('IP(s) pública(s)'));
    expect(r.resumen, contains('contraseña(s)'));
    expect(r.ocultados['comunidad(es) SNMP'], 1);
  });

  test('está activado por defecto en los ajustes', () {
    expect(AiSettingsService.instance.sanitizeBeforeSend, isTrue);
  });
}
