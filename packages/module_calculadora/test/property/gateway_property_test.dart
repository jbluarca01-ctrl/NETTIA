import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:module_calculadora/src/logic/ipv4_subnetting.dart';

void main() {
  property('el gateway de cada subred es su primer host útil', () {
    forAll(
      combine2(integer(min: 8, max: 28), integer(min: 2, max: 64)),
      (input) {
        final (cidr, cantidad) = input;
        final DivisionIpv4 d;
        try {
          d = dividirEnSubredes('10.0.0.0', cidr, cantidad);
        } on Object {
          return; // combinación imposible: la valida otro test
        }
        for (final s in d.subredes) {
          expect(s.gateway, s.primerHost);
          expect(s.gateway, isNot(s.red));
          expect(s.gateway, isNot(s.broadcast));
        }
      },
    );
  });
}
