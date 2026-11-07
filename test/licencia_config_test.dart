import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/src/licencia_config.dart';

void main() {
  test('en debug se usa la clave de prueba y no se exige huella', () {
    expect(clavePublicaActiva, clavePublicaPrueba);
    expect(clavePublicaPrueba.length, 32);
    expect(huellaExigidaActiva, isNull);
  });

  // Fijan los valores de venta: un byte o una letra cambiados por error
  // dejarían a todos los compradores sin poder activar (2026-11-06).
  String hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  test('la clave pública de venta es la de la mini-app de Jairo', () {
    expect(
      hex(clavePublicaVenta),
      'c4902b2755db1258c162f16a9c54eed5b78f87246fe1bf9ce095c66b0a557a69',
    );
  });

  test('la huella de venta es la de la keystore de Jairo', () {
    expect(
      huellaVenta,
      'FC:0D:B7:0C:63:F1:C4:2A:30:B6:AF:61:36:03:BF:39:3F:8C:52:23:75:A2:78:F1:23:2F:F4:A9:45:17:C9:71',
    );
  });

  test('el contacto de compra es el WhatsApp de Jairo', () {
    expect(contactoCompra, 'Escríbeme por WhatsApp al +503 7683 5548');
  });

  test('la clave de prueba es la de la semilla 0..31 (conocida)', () {
    expect(
      hex(clavePublicaPrueba),
      '03a107bff3ce10be1d70dd18e74bc09967e4d6309ba50d5f1ddc8664125531b8',
    );
  });

  test('la clave y la huella de venta se validan por forma', () {
    expect(ventaLista(clave: const [], huella: 'AA'), isFalse);
    expect(ventaLista(clave: List.filled(32, 1), huella: ''), isFalse);
    expect(ventaLista(clave: List.filled(31, 1), huella: 'AA'), isFalse);
    expect(ventaLista(clave: List.filled(32, 1), huella: 'AA'), isTrue);
  });

  test('MainActivity responde "datos" por el canal nettia/licencia', () {
    final kt =
        File(
          'android/app/src/main/kotlin/com/nettia/com/MainActivity.kt',
        ).readAsStringSync();
    expect(kt, contains('"nettia/licencia"'));
    expect(kt, contains('"datos"'));
    expect(kt, contains('Settings.Secure.ANDROID_ID'));
    expect(kt, contains('GET_SIGNING_CERTIFICATES'));
    expect(kt, contains('"SHA-256"'));
  });
}
