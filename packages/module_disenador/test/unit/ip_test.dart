import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/ip.dart';

void main() {
  group('ipANumero', () {
    test('convierte los 4 octetos con su peso', () {
      expect(ipANumero('0.0.0.0'), 0);
      expect(ipANumero('10.1.2.3'), 167838211);
      expect(ipANumero('255.255.255.255'), 4294967295);
      expect(ipANumero(' 192.168.1.1 '), 3232235777);
    });

    test('rechaza lo que no es una IPv4', () {
      expect(ipANumero('10.1.2'), isNull);
      expect(ipANumero('10.1.2.3.4'), isNull);
      expect(ipANumero('10.1.2.256'), isNull);
      expect(ipANumero('10.1.-1.3'), isNull);
      expect(ipANumero('10.1.x.3'), isNull);
      expect(ipANumero(''), isNull);
    });
  });

  test('ipATexto es la inversa de ipANumero', () {
    expect(ipATexto(0), '0.0.0.0');
    expect(ipATexto(167838211), '10.1.2.3');
    expect(ipATexto(4294967295), '255.255.255.255');
  });

  group('RangoIp', () {
    test('cantidad incluye ambos extremos', () {
      expect(const RangoIp(10, 10).cantidad, 1);
      expect(const RangoIp(10, 19).cantidad, 10);
    });

    test('contiene solo lo que está entre los extremos', () {
      const r = RangoIp(10, 20);
      expect(r.contiene(9), isFalse);
      expect(r.contiene(10), isTrue);
      expect(r.contiene(20), isTrue);
      expect(r.contiene(21), isFalse);
    });

    test('se muestra como una IP o como desde – hasta', () {
      expect(
        RangoIp(ipANumero('10.0.0.5')!, ipANumero('10.0.0.5')!).toString(),
        '10.0.0.5',
      );
      expect(
        RangoIp(ipANumero('10.0.0.1')!, ipANumero('10.0.0.9')!).toString(),
        '10.0.0.1 – 10.0.0.9',
      );
    });
  });
}
