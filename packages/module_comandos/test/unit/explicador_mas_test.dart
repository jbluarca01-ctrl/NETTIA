import 'package:flutter_test/flutter_test.dart';
import 'package:module_comandos/src/logic/explicador_show.dart';

ExplicacionShow _e(String texto) => explicarSalidaShow(texto)!;

String _lineas(ExplicacionShow e) =>
    e.hallazgos.map((h) => '${h.nivel.name} | ${h.titulo} | ${h.detalle}').join('\n');

const _cabeceraTrunk =
    'Port        Mode         Encapsulation  Status        Native vlan\n';

String _trunk(String permitidas, String activas, {String extra = ''}) =>
    '${_cabeceraTrunk}Gig0/1      on           802.1q         trunking      1\n\n'
    'Port        Vlans allowed on trunk\nGig0/1      $permitidas\n\n'
    'Port        Vlans allowed and active in management domain\n'
    'Gig0/1      $activas\n$extra';

void main() {
  group('show ip route', () {
    test('un código sin nombre conocido se muestra tal cual', () {
      final e = _e('C   10.0.0.0/30 is directly connected, Serial0/0/0\n'
          'I   10.9.0.0/16 [100/1] via 10.0.0.2\n');
      expect(e.hallazgos.last.titulo, 'I: 10.9.0.0/16');
    });
  });

  group('show interfaces trunk', () {
    test('la tabla de spanning tree no se confunde con las activas', () {
      final e = _e(_trunk('10,20,30,40', '10,20,30',
          extra: '\nPort        Vlans in spanning tree forwarding state and not pruned\n'
              'Gig0/1      10\n'));
      expect(e.hallazgos.first.detalle, startsWith('40. '));
    });

    test('rangos y varias VLAN faltantes separadas por coma', () {
      final e = _e(_trunk('10-12', '10'));
      expect(e.hallazgos.first.detalle, startsWith('11,12. '));
    });

    test('20 faltantes se avisan; 21 ya no (lista demasiado larga)', () {
      expect(_e(_trunk('1-21', '1')).hallazgos.first.nivel, Nivel.aviso);
      expect(_e(_trunk('1-22', '1')).hallazgos.first.nivel, Nivel.ok);
    });

    test('sin faltantes no hay aviso', () {
      expect(_lineas(_e(_trunk('10,20', '10,20'))),
          'ok | Gig0/1: trunk activo | Encapsulación 802.1q, VLAN nativa 1, permite 10,20.');
    });

    test('"none" es una lista vacía', () {
      expect(_e(_trunk('none', 'none')).hallazgos.single.nivel, Nivel.ok);
    });

    test('sin la tabla de permitidas se muestra "?"', () {
      final e = _e('${_cabeceraTrunk}Gig0/1      on   802.1q   trunking   1\n');
      expect(e.hallazgos.single.detalle, endsWith('permite ?.'));
    });

    test('un puerto que no es trunk dice su modo', () {
      final e = _e('${_cabeceraTrunk}Fa0/24      auto   n-802.1q   not-trunking   1\n');
      expect(e.hallazgos.single.detalle, contains('en modo auto no forma trunk'));
    });

    test('sin puertos avisa que no hay trunk', () {
      final e = _e(_cabeceraTrunk);
      expect(_lineas(e), startsWith('aviso | No hay ningún trunk'));
      expect(e.resumen, '0 trunk activos de 0.');
    });
  });

  group('ipconfig', () {
    String ipconfig(String ip, String mascara, String gw) =>
        'IP Address......: $ip\nSubnet Mask.....: $mascara\nDefault Gateway.: $gw\n';

    test('red de clase A con el primer octeto bien calculado', () {
      expect(_e(ipconfig('10.0.0.5', '255.0.0.0', '10.0.0.1')).resumen,
          'IP 10.0.0.5/8 en la red 10.0.0.0.');
    });

    test('la red sale del AND aunque la IP no sea la primera', () {
      expect(_e(ipconfig('192.168.20.200', '255.255.255.128', '192.168.20.129')).resumen,
          'IP 192.168.20.200/25 en la red 192.168.20.128.');
    });

    test('/32', () {
      expect(_e(ipconfig('10.0.0.5', '255.255.255.255', '0.0.0.0')).resumen,
          'IP 10.0.0.5/32 en la red 10.0.0.5.');
    });

    test('el gateway igual a la IP es un problema', () {
      expect(_e(ipconfig('192.168.1.5', '255.255.255.0', '192.168.1.5')).hallazgos.single.titulo,
          'El gateway es la propia IP de la PC');
    });

    test('máscara no contigua, 0.0.0.0 o IP 0.0.0.0: sin IP válida', () {
      for (final (ip, m) in [
        ('192.168.1.5', '255.0.255.0'),
        ('192.168.1.5', '0.0.0.0'),
        ('0.0.0.0', '255.255.255.0'),
      ]) {
        expect(_e(ipconfig(ip, m, '0.0.0.0')).hallazgos.single.titulo,
            'Sin dirección IPv4', reason: '$ip $m');
      }
    });
  });

  group('arp -a', () {
    test('una entrada fija lo dice', () {
      final e = _e('Internet Address   Physical Address   Type\n'
          '192.168.1.255      FF-FF-FF-FF-FF-FF  static\n');
      expect(_lineas(e),
          'ok | 192.168.1.255 → FF-FF-FF-FF-FF-FF | Entrada fija (static): no la aprendió ARP.');
    });
  });

  test('orden: problemas, avisos y lo que está bien, estable entre iguales', () {
    const ok = Hallazgo(Nivel.ok, 'ok', '');
    const aviso = Hallazgo(Nivel.aviso, 'aviso', '');
    const problema = Hallazgo(Nivel.problema, 'problema', '');
    const aviso2 = Hallazgo(Nivel.aviso, 'aviso2', '');
    expect(
      ordenarHallazgos([ok, aviso, problema, aviso2]).map((h) => h.titulo),
      ['problema', 'aviso', 'aviso2', 'ok'],
    );
  });
}
