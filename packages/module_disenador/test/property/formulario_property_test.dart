import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/formulario.dart';

void main() {
  property('leerRedBase devuelve lo escrito a cada lado de la barra', () {
    forAll(
      combine2(
        list(integer(min: 0, max: 255), minLength: 4, maxLength: 4),
        integer(min: 0, max: 32),
      ),
      (entrada) {
        final (octetos, cidr) = entrada;
        final red = octetos.join('.');
        expect(leerRedBase('$red/$cidr'), (red, cidr));
      },
    );
  });

  property('leerEntero lee cualquier entero escrito con espacios', () {
    forAll(integer(min: -1000, max: 1000), (n) {
      expect(leerEntero(' $n ', 'campo'), n);
    });
  });
}
