import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:nettia_core/nettia_core.dart';

const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
final _clave = List<int>.filled(32, 9);

void main() {
  property('todo código de teléfono es XXXXX-XXXXX en Crockford', () {
    forAll(string(minLength: 1, maxLength: 40), (id) {
      final c = codigoTelefono(id);
      expect(c.length, 11);
      expect(c[5], '-');
      for (final ch in c.replaceAll('-', '').split('')) {
        expect(_crockford.contains(ch), isTrue);
      }
      expect(codigoTelefono(id), c);
    });
  });

  property('el nombre viaja intacto en la licencia armada', () {
    forAll(string(minLength: 1, maxLength: 60), (nombre) {
      // Surrogates sueltos no son texto válido: el licenciador no los genera.
      if (utf8.decode(utf8.encode(nombre)) != nombre) return;
      final partes = armarLicencia(nombre, List.filled(64, 3)).split('.');
      expect(partes.length, 3);
      expect(utf8.decode(decodificarBase64Url(partes[1])), nombre);
      expect(decodificarBase64Url(partes[2]), List.filled(64, 3));
    });
  });

  property('ningún texto arbitrario se acepta ni hace lanzar', () {
    forAll(string(maxLength: 200), (texto) async {
      final r = await verificarLicencia(
        texto,
        androidId: 'x',
        clavePublica: _clave,
      );
      expect(r, isA<LicenciaInvalida>());
    });
  });
}
