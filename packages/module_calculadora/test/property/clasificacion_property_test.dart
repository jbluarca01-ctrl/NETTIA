import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:module_calculadora/src/logic/clasificacion_ipv4.dart';

/// IP como entero de 32 bits → texto punteado.
String _ip(int v) =>
    '${v ~/ 16777216 % 256}.${v ~/ 65536 % 256}.${v ~/ 256 % 256}.${v % 256}';

/// Los tres bloques RFC 1918 como rangos de enteros [desde, hasta].
const _privados = <(int, int)>[
  (167772160, 184549375), // 10.0.0.0 – 10.255.255.255
  (2886729728, 2887778303), // 172.16.0.0 – 172.31.255.255
  (3232235520, 3232301055), // 192.168.0.0 – 192.168.255.255
];

void main() {
  property('privada ⇔ está dentro de un bloque RFC 1918', () {
    forAll(integer(min: 0, max: 4294967295), (v) {
      final c = clasificarIpv4(_ip(v))!;
      final enBloque = _privados.any((r) => v >= r.$1 && v <= r.$2);
      expect(c.tipo == TipoIpv4.privada, enBloque);
    });
  });

  property('la clase solo depende del primer octeto', () {
    forAll(
      combine2(integer(min: 0, max: 255), integer(min: 0, max: 16777215)),
      (input) {
        final (primero, resto) = input;
        final base = clasificarIpv4(_ip(primero * 16777216))!.clase;
        final otra = clasificarIpv4(_ip(primero * 16777216 + resto))!.clase;
        expect(otra, base);
      },
    );
  });

  property('la clase crece con el primer octeto (A ≤ B ≤ C ≤ D ≤ E)', () {
    forAll(integer(min: 0, max: 254), (o) {
      final a = clasificarIpv4('$o.1.1.1')!.clase.index;
      final b = clasificarIpv4('${o + 1}.1.1.1')!.clase.index;
      expect(b >= a, isTrue);
    });
  });
}
