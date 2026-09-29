import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/src/widgets/fila_vlsm.dart';

void main() {
  group('quitarFilaVlsm', () {
    testWidgets(
        'quita la fila, notifica el cambio y libera sus controladores tras '
        'el cuadro', (tester) async {
      // addPostFrameCallback solo se dispara si hay un árbol montado.
      await tester.pumpWidget(const SizedBox());
      final filas = filasVlsmDeEjemplo();
      final quitada = filas[0];
      var notificado = false;

      quitarFilaVlsm(filas, 0, () => notificado = true);

      expect(notificado, isTrue);
      expect(filas, hasLength(2));
      expect(filas.first.nombre.text, 'LAN 2');

      WidgetsBinding.instance.scheduleFrame();
      await tester.pump(); // flushea el postFrameCallback
      // Ya fue dispuesta por quitarFilaVlsm: un segundo dispose() debe
      // fallar, porque TextEditingController no admite doble dispose.
      expect(() => quitada.dispose(), throwsA(anything));
    });
  });

  group('requerimientosDesde', () {
    test('usa "Red N" cuando el nombre está vacío', () {
      final filas = <FilaVlsm>[FilaVlsm('', '10')];
      final reqs = requerimientosDesde(filas);
      expect(reqs.single.nombre, 'Red 1');
      expect(reqs.single.hosts, 10);
    });

    test('ignora filas sin un número de hosts válido', () {
      final filas = <FilaVlsm>[FilaVlsm('Vacía', ''), FilaVlsm('Ok', '5')];
      final reqs = requerimientosDesde(filas);
      expect(reqs, hasLength(1));
      expect(reqs.single.nombre, 'Ok');
    });
  });
}
