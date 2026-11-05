import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

const _id = '9774d56d682e549c';
final _semilla = List<int>.generate(32, (i) => i);

Future<List<int>> _clave() async =>
    (await (await Ed25519().newKeyPairFromSeed(_semilla)).extractPublicKey())
        .bytes;

Future<String> _licencia(String nombre, {String id = _id}) async {
  final par = await Ed25519().newKeyPairFromSeed(_semilla);
  final firma = await Ed25519().sign(
    mensajeLicencia(codigoTelefono(id), nombre),
    keyPair: par,
  );
  return armarLicencia(nombre, firma.bytes);
}

String _b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');

Future<ResultadoLicencia> _revisar(String texto) async =>
    verificarLicencia(texto, androidId: _id, clavePublica: await _clave());

void main() {
  group('codigoTelefono', () {
    test('da 10 caracteres Crockford en grupos de 5 (oráculo: Node)', () {
      expect(codigoTelefono(_id), '706SD-81FDE');
    });

    test('distintos ANDROID_ID dan distinto código', () {
      expect(codigoTelefono('0123456789abcdef'), isNot(codigoTelefono(_id)));
    });
  });

  group('mensajeLicencia', () {
    test('es NETTIA-LIC-1|código sin guion|nombre en UTF-8', () {
      expect(
        utf8.decode(mensajeLicencia('706SD-81FDE', 'Ana Pérez')),
        'NETTIA-LIC-1|706SD81FDE|Ana Pérez',
      );
    });

    test('acepta el código sin guion y en minúsculas', () {
      expect(
        mensajeLicencia('706sd81fde', 'A'),
        mensajeLicencia('706SD-81FDE', 'A'),
      );
    });
  });

  group('armarLicencia', () {
    test('NT1.<nombre b64url>.<firma b64url> sin relleno', () {
      final t = armarLicencia('Ana', List<int>.filled(64, 1));
      expect(t, 'NT1.${_b64(utf8.encode('Ana'))}.${_b64(List.filled(64, 1))}');
      expect(t.contains('='), isFalse);
    });
  });

  group('decodificarBase64Url', () {
    test('decodifica sin relleno', () {
      expect(decodificarBase64Url(_b64([1, 2, 3, 4])), [1, 2, 3, 4]);
    });
  });

  group('verificarLicencia', () {
    test('válida devuelve el nombre', () async {
      expect(
        await _revisar(await _licencia('Ana Pérez')),
        const LicenciaValida('Ana Pérez'),
      );
    });

    test('quita espacios, tabs, saltos y comillas simples o dobles', () async {
      final l = await _licencia('Ana');
      expect(
        await _revisar("'\t${l.substring(0, 9)}\r\n ${l.substring(9)}'"),
        const LicenciaValida('Ana'),
      );
      expect(await _revisar('"$l"'), const LicenciaValida('Ana'));
    });

    test('nombre de 60 caracteres se acepta', () async {
      final n = 'x' * 60;
      expect(await _revisar(await _licencia(n)), LicenciaValida(n));
    });

    const formato = LicenciaInvalida(MotivoRechazo.formato);
    final firma64 = _b64(List<int>.filled(64, 7));
    final nombreB64 = _b64(utf8.encode('Ana'));

    final casosFormato = <String, String>{
      'texto cualquiera': 'hola profe',
      'vacío': '',
      'prefijo distinto': 'NT2.$nombreB64.$firma64',
      'dos partes': 'NT1.$nombreB64',
      'cuatro partes': 'NT1.$nombreB64.$firma64.x',
      'base64 inválido en nombre': 'NT1.%%%.$firma64',
      'base64 inválido en firma': 'NT1.$nombreB64.%%%',
      'firma de 63 bytes': 'NT1.$nombreB64.${_b64(List.filled(63, 7))}',
      'firma de 65 bytes': 'NT1.$nombreB64.${_b64(List.filled(65, 7))}',
      'nombre vacío': 'NT1..$firma64',
      'nombre de 61': 'NT1.${_b64(utf8.encode('x' * 61))}.$firma64',
      'nombre no UTF-8': 'NT1.${_b64([0xff, 0xfe])}.$firma64',
    };
    for (final c in casosFormato.entries) {
      test('formato: ${c.key}', () async {
        expect(await _revisar(c.value), formato);
      });
    }

    test('firma: otro teléfono', () async {
      expect(
        await _revisar(await _licencia('Ana', id: '0123456789abcdef')),
        const LicenciaInvalida(MotivoRechazo.firma),
      );
    });

    test('firma: 64 bytes que no son firma', () async {
      expect(
        await _revisar('NT1.$nombreB64.$firma64'),
        const LicenciaInvalida(MotivoRechazo.firma),
      );
    });

    test('firma: clave pública de largo inválido no lanza', () async {
      final l = await _licencia('Ana');
      expect(
        await verificarLicencia(l, androidId: _id, clavePublica: [1, 2, 3]),
        const LicenciaInvalida(MotivoRechazo.firma),
      );
    });
  });

  group('igualdad de resultados', () {
    test('LicenciaValida compara por nombre', () {
      expect(const LicenciaValida('a'), const LicenciaValida('a'));
      expect(const LicenciaValida('a'), isNot(const LicenciaValida('b')));
      expect(
        const LicenciaValida('a').hashCode,
        const LicenciaValida('a').hashCode,
      );
      expect(const LicenciaValida('a').toString(), contains('a'));
    });

    test('LicenciaInvalida compara por motivo', () {
      const f = LicenciaInvalida(MotivoRechazo.formato);
      expect(f, const LicenciaInvalida(MotivoRechazo.formato));
      expect(f, isNot(const LicenciaInvalida(MotivoRechazo.firma)));
      expect(
        f.hashCode,
        const LicenciaInvalida(MotivoRechazo.formato).hashCode,
      );
      expect(f.toString(), contains('formato'));
    });
  });
}
