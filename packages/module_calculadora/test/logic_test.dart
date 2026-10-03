import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/src/logic/ipv4_subnetting.dart';
import 'package:module_calculadora/src/logic/ipv6.dart';

void main() {
  group('dividir en N subredes (IPv4)', () {
    test('192.168.1.0/24 en 16 subredes → /28 (el caso del parcial)', () {
      final d = dividirEnSubredes('192.168.1.0', 24, 16);
      expect(d.bitsPrestados, 4);
      expect(d.nuevoCidr, 28);
      expect(d.subredes, hasLength(16));
      final primera = d.subredes.first;
      expect(primera.red, '192.168.1.0');
      expect(primera.mascara, '255.255.255.240');
      expect(primera.primerHost, '192.168.1.1');
      expect(primera.ultimoHost, '192.168.1.14');
      expect(primera.broadcast, '192.168.1.15');
      expect(primera.hostsUtiles, 14);
      expect(d.subredes[1].red, '192.168.1.16');
      final ultima = d.subredes.last;
      expect(ultima.red, '192.168.1.240');
      expect(ultima.broadcast, '192.168.1.255');
      expect(d.avisos, isEmpty);
    });

    test('10 subredes: salen 16 y se avisa de las libres', () {
      final d = dividirEnSubredes('192.168.1.0', 24, 10);
      expect(d.subredes, hasLength(16));
      expect(d.subredesPedidas, 10);
      expect(d.avisos.single, contains('6 libres'));
    });

    test('172.16.0.0/16 en 5 subredes → /19 con salto de 32 en el 3.er octeto', () {
      final d = dividirEnSubredes('172.16.0.0', 16, 5);
      expect(d.nuevoCidr, 19);
      expect(d.subredes, hasLength(8));
      expect(d.subredes[1].red, '172.16.32.0');
      expect(d.subredes[1].mascara, '255.255.224.0');
      expect(d.subredes[1].hostsUtiles, 8190);
    });

    test('muchas subredes pedidas: lista solo las primeras 24 y da el total',
        () {
      // 1000 subredes → 10 bits → 1024 desde /8.
      final d = dividirEnSubredes('10.0.0.0', 8, 1000);
      expect(maxSubredesListadas, 24);
      expect(d.totalSubredes, 1024);
      expect(d.subredes, hasLength(24));
      expect(d.subredesPedidas, 1000);
      expect(d.avisos,
          contains('Se listan solo las primeras 24 de 1024 subredes.'));
    });

    test('la subred número k se calcula aunque no esté listada', () {
      // 32 subredes /29 desde 192.168.1.0/24: la #25 empieza en 24 × 8.
      final d = dividirEnSubredes('192.168.1.0', 24, 32);
      expect(d.subredes, hasLength(24));
      final s = subredNumero(d, 25);
      expect(s.indice, 25);
      expect(s.red, '192.168.1.192');
      expect(s.broadcast, '192.168.1.199');
      expect(s.mascara, '255.255.255.248');
      expect(subredNumero(d, 1).red, d.subredes.first.red);
    });

    test('el total de subredes coincide con la lista cuando es pequeña', () {
      expect(dividirEnSubredes('192.168.1.0', 24, 16).totalSubredes, 16);
    });

    test('una IP que no es de red se normaliza y se avisa', () {
      final d = dividirEnSubredes('192.168.1.77', 24, 4);
      expect(d.redOriginal, '192.168.1.0');
      expect(d.avisos.first, contains('no es la dirección de red'));
    });

    test('errores de validación', () {
      expect(() => dividirEnSubredes('300.1.1.1', 24, 4),
          throwsA(isA<SubneteoException>()));
      expect(() => dividirEnSubredes('192.168.1.0', 24, 1),
          throwsA(isA<SubneteoException>()));
      // /24 + 7 bits = /31: no válido.
      expect(() => dividirEnSubredes('192.168.1.0', 24, 100),
          throwsA(isA<SubneteoException>()));
    });
  });

  group('dividir por hosts por subred', () {
    test('/24 con 50 hosts por subred → /26, 4 subredes de 62 hosts', () {
      final d = dividirPorHosts('192.168.0.0', 24, 50);
      expect(d.nuevoCidr, 26);
      expect(d.subredes, hasLength(4));
      expect(d.subredes.first.hostsUtiles, 62);
      expect(d.subredes[2].red, '192.168.0.128');
    });

    test('exactamente 62 hosts cabe en /26; 63 ya necesita /25', () {
      expect(dividirPorHosts('10.0.0.0', 24, 62).nuevoCidr, 26);
      expect(dividirPorHosts('10.0.0.0', 24, 63).nuevoCidr, 25);
    });

    test(
        'un prefijo grande no construye todas las subredes: lista las '
        'primeras 24, da el total y avisa', () {
      // 16 hosts → /27; desde /8 son 2^19 = 524288 subredes.
      final d = dividirPorHosts('10.0.0.0', 8, 16);
      expect(d.totalSubredes, 524288);
      expect(d.subredes, hasLength(24));
      expect(d.subredes.last.indice, 24);
      expect(d.subredes.last.red, '10.0.2.224');
      expect(d.avisos,
          contains('Se listan solo las primeras 24 de 524288 subredes.'));
    });

    test('hasta 24 subredes se listan todas, sin aviso', () {
      // 16 hosts → /27; desde /23 son 2^4 = 16.
      final d = dividirPorHosts('10.0.0.0', 23, 16);
      expect(d.totalSubredes, 16);
      expect(d.subredes, hasLength(16));
      expect(d.avisos, isEmpty);
    });

    test('32 subredes ya pasan del máximo: se listan 24 y se avisa', () {
      // 16 hosts → /27; desde /22 son 2^5 = 32.
      final d = dividirPorHosts('10.0.0.0', 22, 16);
      expect(d.totalSubredes, 32);
      expect(d.subredes, hasLength(24));
      expect(
          d.avisos, contains('Se listan solo las primeras 24 de 32 subredes.'));
    });

    test('más hosts de los que caben en la red original falla', () {
      expect(() => dividirPorHosts('192.168.0.0', 24, 300),
          throwsA(isA<SubneteoException>()));
    });
  });

  group('VLSM', () {
    test('100, 50, 25 y 10 hosts en 192.168.1.0/24', () {
      final r = calcularVlsm('192.168.1.0', 24, const <RequerimientoVlsm>[
        RequerimientoVlsm('Ventas', 100),
        RequerimientoVlsm('TI', 50),
        RequerimientoVlsm('Lab', 25),
        RequerimientoVlsm('Gestión', 10),
      ]);
      final s = r.subredes;
      expect((s[0].nombre, s[0].red, s[0].cidr), ('Ventas', '192.168.1.0', 25));
      expect((s[1].nombre, s[1].red, s[1].cidr), ('TI', '192.168.1.128', 26));
      expect((s[2].nombre, s[2].red, s[2].cidr), ('Lab', '192.168.1.192', 27));
      expect((s[3].nombre, s[3].red, s[3].cidr),
          ('Gestión', '192.168.1.224', 28));
      expect(s[0].broadcast, '192.168.1.127');
      expect(r.direccionesLibres, 16);
    });

    test('ordena de mayor a menor aunque se ingresen desordenados', () {
      final r = calcularVlsm('10.0.0.0', 24, const <RequerimientoVlsm>[
        RequerimientoVlsm('chica', 2),
        RequerimientoVlsm('grande', 120),
      ]);
      expect(r.subredes.first.nombre, 'grande');
      expect(r.subredes.last.red, '10.0.0.128');
      expect(r.subredes.last.cidr, 30);
    });

    test('si no caben, falla con un mensaje claro', () {
      expect(
        () => calcularVlsm('192.168.1.0', 24, const <RequerimientoVlsm>[
          RequerimientoVlsm('a', 200),
          RequerimientoVlsm('b', 100),
        ]),
        throwsA(isA<SubneteoException>()
            .having((e) => e.mensaje, 'mensaje', contains('No caben'))),
      );
    });
  });

  group('IPv6', () {
    test('abreviar según RFC 5952', () {
      expect(Ipv6.parse('2001:0db8:0000:0000:0000:ff00:0042:8329').abreviada,
          '2001:db8::ff00:42:8329');
      expect(Ipv6.parse('0000:0000:0000:0000:0000:0000:0000:0000').abreviada,
          '::');
      expect(Ipv6.parse('0:0:0:0:0:0:0:1').abreviada, '::1');
      // Un solo grupo en cero no se comprime.
      expect(Ipv6.parse('2001:db8:0:1:1:1:1:1').abreviada,
          '2001:db8:0:1:1:1:1:1');
      // Con dos rachas iguales se comprime la primera (ejemplo de RFC 5952).
      expect(Ipv6.parse('2001:db8:0:0:1:0:0:1').abreviada, '2001:db8::1:0:0:1');
      // Se comprime la racha más larga aunque no sea la primera.
      expect(Ipv6.parse('2001:0:0:1:0:0:0:1').abreviada, '2001:0:0:1::1');
    });

    test('expandir', () {
      expect(Ipv6.parse('2001:db8::1').expandida,
          '2001:0db8:0000:0000:0000:0000:0000:0001');
      expect(Ipv6.parse('::').expandida,
          '0000:0000:0000:0000:0000:0000:0000:0000');
      expect(Ipv6.parse('FE80::1').expandida,
          'fe80:0000:0000:0000:0000:0000:0000:0001');
    });

    test('rechaza texto inválido', () {
      for (final malo in <String>[
        '',
        '2001:db8::1::2',
        '2001:db8',
        '12345::1',
        'g::1',
        '1:2:3:4:5:6:7:8:9',
        '2001:db8::1/64',
      ]) {
        expect(() => Ipv6.parse(malo), throwsA(isA<Ipv6Exception>()),
            reason: malo);
      }
    });

    test('tipos de dirección', () {
      String tipo(String a) => clasificarIpv6(Ipv6.parse(a)).nombre;
      expect(tipo('::'), 'No especificada');
      expect(tipo('::1'), 'Loopback');
      expect(tipo('fe80::1'), 'Link-local');
      expect(tipo('febf::1'), 'Link-local');
      expect(tipo('fec0::1'), 'Otra / reservada');
      expect(tipo('fd12:3456:789a::1'), 'Local única (ULA)');
      expect(tipo('fc00::1'), 'Local única (ULA)');
      expect(tipo('ff02::1'), 'Multicast');
      expect(tipo('2001:db8:acad::1'), 'Documentación');
      expect(tipo('2a00:1450::1'), 'Unicast global (GUA)');
      expect(tipo('::ffff:102:304'), 'IPv4 mapeada');
      expect(clasificarIpv6(Ipv6.parse('ff02::1')).descripcion,
          contains('enlace local'));
    });

    test('EUI-64 invierte el bit U/L e inserta fffe', () {
      final id = eui64DesdeMac('00:1A:2B:3C:4D:5E');
      expect(id.map((g) => g.toRadixString(16).padLeft(4, '0')).join(':'),
          '021a:2bff:fe3c:4d5e');
      // Si el bit ya estaba en 1, se apaga.
      expect(eui64DesdeMac('02-1a-2b-3c-4d-5e')[0], 0x001a);
      final dir = direccionEui64(Ipv6.parse('2001:db8:acad:1::'),
          '00:1A:2B:3C:4D:5E');
      expect(dir.abreviada, '2001:db8:acad:1:21a:2bff:fe3c:4d5e');
      expect(() => eui64DesdeMac('00:1A:2B'), throwsA(isA<Ipv6Exception>()));
    });

    test('de /48 a /64 hay 65 536 subredes; se listan las primeras 24', () {
      final d = subnetearIpv6('2001:db8:acad::', 48, 64);
      expect(d.totalSubredes, BigInt.from(65536));
      expect(d.primeras, hasLength(24));
      expect(d.primeras[0].red.abreviada, '2001:db8:acad::');
      expect(d.primeras[1].red.abreviada, '2001:db8:acad:1::');
      expect(d.primeras[23].red.abreviada, '2001:db8:acad:17::');
    });

    test('pocas subredes: se listan todas; y se normaliza la red', () {
      final d = subnetearIpv6('2001:db8:acad:ff::1', 48, 50);
      expect(d.totalSubredes, BigInt.from(4));
      expect(d.primeras, hasLength(4));
      expect(d.avisos, isNotEmpty);
      expect(d.redOriginal.abreviada, '2001:db8:acad::');
      expect(d.primeras[3].red.abreviada, '2001:db8:acad:c000::');
      expect(() => subnetearIpv6('2001:db8::', 64, 48),
          throwsA(isA<Ipv6Exception>()));
    });
  });
}
