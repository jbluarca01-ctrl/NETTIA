import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:module_calculadora/src/logic/conversiones.dart';
import 'package:module_calculadora/src/logic/resumen_cidr.dart';

/// Red alineada dentro de 10.0.0.0/16 a partir del tercer octeto y el prefijo.
String _red((int, int) par) {
  final (octeto, prefijo) = par;
  final v = ipDesdeTexto('10.0.$octeto.0')!;
  var tam = 1;
  for (var i = 0; i < 32 - prefijo; i++) {
    tam *= 2;
  }
  return '${ipATexto(v - v % tam)}/$prefijo';
}

void main() {
  property('el resumen cubre todas las redes y el veredicto cuadra', () {
    forAll(
      list(
        combine2(integer(min: 0, max: 255), integer(min: 20, max: 26)),
        minLength: 2,
        maxLength: 6,
      ),
      (pares) {
        final redes = pares.map(_red).toList();
        final r = revisarResumen(redes);
        final ini = ipDesdeTexto(r.resumen.red)!;
        var tam = 1;
        for (var i = 0; i < 32 - r.resumen.prefijo; i++) {
          tam *= 2;
        }
        // Direcciones distintas que cubren las redes juntas.
        final cubiertas = <int>{};
        for (final red in redes) {
          final (a, b) = rangoDeRed(red);
          expect(a, greaterThanOrEqualTo(ini));
          expect(b, lessThanOrEqualTo(ini + tam - 1));
          for (var x = a; x <= b; x += 64) {
            cubiertas.add(x ~/ 64);
          }
        }
        final exacto = cubiertas.length * 64 == tam;
        expect(r.veredicto == Veredicto.valido, exacto);
        expect(r.veredicto == Veredicto.noValido, r.faltantes.isNotEmpty);
        expect(r.veredicto == Veredicto.valido,
            r.faltantes.isEmpty && r.sobrantes.isEmpty);
      },
    );
  });
}
