import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/src/licencia_config.dart';

void main() {
  test('en debug se usa la clave de prueba y no se exige huella', () {
    expect(clavePublicaActiva, clavePublicaPrueba);
    expect(clavePublicaPrueba.length, 32);
    expect(huellaExigidaActiva, isNull);
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
