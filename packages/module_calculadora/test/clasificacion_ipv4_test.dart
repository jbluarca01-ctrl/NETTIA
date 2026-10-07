import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/src/logic/clasificacion_ipv4.dart';

void main() {
  group('clase por el primer octeto (bordes)', () {
    for (final (ip, clase) in <(String, ClaseIpv4)>[
      ('1.0.0.1', ClaseIpv4.a),
      ('126.0.0.1', ClaseIpv4.a),
      ('127.0.0.1', ClaseIpv4.a),
      ('128.0.0.1', ClaseIpv4.b),
      ('191.255.0.1', ClaseIpv4.b),
      ('192.0.0.1', ClaseIpv4.c),
      ('223.0.0.1', ClaseIpv4.c),
      ('224.0.0.1', ClaseIpv4.d),
      ('239.0.0.1', ClaseIpv4.d),
      ('240.0.0.1', ClaseIpv4.e),
      ('255.0.0.1', ClaseIpv4.e),
    ]) {
      test('$ip → ${clase.letra}', () {
        expect(clasificarIpv4(ip)!.clase, clase);
      });
    }
  });

  group('tipo (bordes de cada rango)', () {
    for (final (ip, tipo) in <(String, TipoIpv4)>[
      ('9.255.255.255', TipoIpv4.publica),
      ('10.0.0.0', TipoIpv4.privada),
      ('10.255.255.255', TipoIpv4.privada),
      ('11.0.0.0', TipoIpv4.publica),
      ('172.15.255.255', TipoIpv4.publica),
      ('172.16.0.0', TipoIpv4.privada),
      ('172.31.255.255', TipoIpv4.privada),
      ('172.32.0.0', TipoIpv4.publica),
      ('171.16.0.1', TipoIpv4.publica),
      ('192.167.0.1', TipoIpv4.publica),
      ('192.168.0.1', TipoIpv4.privada),
      ('192.169.0.1', TipoIpv4.publica),
      ('193.168.0.1', TipoIpv4.publica),
      ('169.253.0.1', TipoIpv4.publica),
      ('169.254.0.1', TipoIpv4.apipa),
      ('169.255.0.1', TipoIpv4.publica),
      ('168.254.0.1', TipoIpv4.publica),
      ('126.255.255.255', TipoIpv4.publica),
      ('127.0.0.1', TipoIpv4.loopback),
      ('0.0.0.0', TipoIpv4.noEspecificada),
      ('0.0.0.1', TipoIpv4.reservada),
      ('1.0.0.0', TipoIpv4.publica),
      ('223.255.255.255', TipoIpv4.publica),
      ('224.0.0.0', TipoIpv4.multicast),
      ('239.255.255.255', TipoIpv4.multicast),
      ('240.0.0.0', TipoIpv4.experimental),
      ('255.255.255.254', TipoIpv4.experimental),
      ('255.255.255.255', TipoIpv4.broadcastLimitado),
      ('255.255.254.255', TipoIpv4.experimental),
    ]) {
      test('$ip → ${tipo.texto}', () {
        expect(clasificarIpv4(ip)!.tipo, tipo);
      });
    }
  });

  test('textos de la clase y su máscara por defecto', () {
    expect(clasificarIpv4('10.0.0.1')!.claseTexto, 'A · /8 (255.0.0.0)');
    expect(clasificarIpv4('172.20.0.1')!.claseTexto, 'B · /16 (255.255.0.0)');
    expect(
      clasificarIpv4('192.168.0.1')!.claseTexto,
      'C · /24 (255.255.255.0)',
    );
    expect(clasificarIpv4('224.0.0.1')!.claseTexto, 'D · sin máscara');
    expect(clasificarIpv4('240.0.0.1')!.claseTexto, 'E · sin máscara');
  });

  test('solo las públicas y las privadas se asignan a un host', () {
    expect(TipoIpv4.publica.asignable, isTrue);
    expect(TipoIpv4.privada.asignable, isTrue);
    for (final t in TipoIpv4.values.where(
      (t) => t != TipoIpv4.publica && t != TipoIpv4.privada,
    )) {
      expect(t.asignable, isFalse, reason: t.name);
    }
  });

  group('explicación completa', () {
    for (final (ip, texto) in <(String, String)>[
      (
        '10.15.3.7',
        'Clase A: el primer octeto (10) está en 1–126. Máscara por defecto '
            '/8 (255.0.0.0). Privada: bloque RFC 1918 10.0.0.0/8. Se '
            'reutiliza en otras redes y necesita NAT para salir a Internet.',
      ),
      (
        '172.20.5.9',
        'Clase B: el primer octeto (172) está en 128–191. Máscara por '
            'defecto /16 (255.255.0.0). Privada: bloque RFC 1918 '
            '172.16.0.0/12 (172.16 a 172.31). Se reutiliza en otras redes y '
            'necesita NAT para salir a Internet.',
      ),
      (
        '192.168.1.20',
        'Clase C: el primer octeto (192) está en 192–223. Máscara por '
            'defecto /24 (255.255.255.0). Privada: bloque RFC 1918 '
            '192.168.0.0/16. Se reutiliza en otras redes y necesita NAT para '
            'salir a Internet.',
      ),
      (
        '224.10.10.10',
        'Clase D: el primer octeto (224) está en 224–239. No tiene máscara '
            'por defecto. Multicast: un origen hacia un grupo de destinos. No '
            'se asigna a un host.',
      ),
    ]) {
      test(ip, () => expect(clasificarIpv4(ip)!.explicacion, texto));
    }
  });

  group('explicación', () {
    test('la clase justifica con el rango del primer octeto', () {
      expect(
        clasificarIpv4('10.15.3.7')!.explicacion,
        startsWith('Clase A: el primer octeto (10) está en 1–126. '),
      );
      expect(
        clasificarIpv4('224.10.10.10')!.explicacion,
        startsWith('Clase D: el primer octeto (224) está en 224–239. '),
      );
    });

    test('127 y 0 quedan fuera del rango de hosts de la clase A', () {
      expect(
        clasificarIpv4('127.0.0.1')!.explicacion,
        startsWith('Clase A: el primer octeto (127) está reservado '
            '(los hosts de clase A van de 1 a 126). '),
      );
      expect(
        clasificarIpv4('0.1.2.3')!.explicacion,
        contains('el primer octeto (0) está reservado'),
      );
    });

    test('privada: nombra su bloque RFC 1918 y el NAT', () {
      expect(
        clasificarIpv4('10.15.3.7')!.explicacion,
        endsWith('Privada: bloque RFC 1918 10.0.0.0/8. Se reutiliza en '
            'otras redes y necesita NAT para salir a Internet.'),
      );
      expect(
        clasificarIpv4('172.31.0.1')!.explicacion,
        contains('bloque RFC 1918 172.16.0.0/12 (172.16 a 172.31)'),
      );
      expect(
        clasificarIpv4('192.168.1.20')!.explicacion,
        contains('bloque RFC 1918 192.168.0.0/16'),
      );
    });

    test('pública: avisa la trampa de 172 solo cuando aplica', () {
      expect(
        clasificarIpv4('172.15.1.1')!.explicacion,
        endsWith('Pública: única y enrutable en Internet. Ojo: el bloque '
            'privado de clase B va de 172.16 a 172.31.'),
      );
      expect(
        clasificarIpv4('172.32.0.1')!.explicacion,
        contains('Ojo: el bloque privado'),
      );
      expect(
        clasificarIpv4('8.8.8.8')!.explicacion,
        endsWith('Pública: única y enrutable en Internet.'),
      );
    });

    test('especiales: cada una con su descripción', () {
      for (final (ip, texto) in <(String, String)>[
        ('127.0.0.1', 'Loopback: tráfico hacia el propio equipo'),
        ('169.254.10.5', 'APIPA: el equipo se la autoasignó porque falló'),
        ('224.0.0.5', 'Multicast: un origen hacia un grupo'),
        ('240.0.0.1', 'Experimental: reservada'),
        ('255.255.255.255', 'Broadcast limitado: a todos los equipos'),
        ('0.0.0.0', 'No especificada: origen durante DHCP'),
        ('0.0.0.9', 'Reservada: la red 0 significa'),
      ]) {
        expect(clasificarIpv4(ip)!.explicacion, contains(texto), reason: ip);
      }
    });
  });

  group('entradas inválidas devuelven null', () {
    for (final ip in <String>[
      '',
      '1.2.3',
      '1.2.3.4.5',
      '256.1.1.1',
      '1.2.3.999',
      'a.b.c.d',
      '1..2.3',
      '1.2.3.4 ',
      '-1.2.3.4',
    ]) {
      test('"$ip"', () => expect(clasificarIpv4(ip), isNull));
    }
  });
}
