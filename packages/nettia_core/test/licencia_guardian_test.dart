import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vector cruzado: clave pública de la semilla 0..31 y licencia firmada con
/// Node (`crypto.sign`, Ed25519) para el ANDROID_ID de prueba. Si Nettia la
/// acepta, el formato coincide con una implementación independiente.
const _clave = [
  3, 161, 7, 191, 243, 206, 16, 190, 29, 112, 221, 24, 231, 75, 192, 153, //
  103, 228, 214, 48, 155, 165, 13, 95, 29, 220, 134, 100, 18, 85, 49, 184,
];
const _id = '9774d56d682e549c';
const _licNode =
    'NT1.UHJ1ZWJhIE5ldHRpYQ.YlXp0XxUDUBC3--h9okVn9lQVnwudIZkEuILCgP4tB7c_'
    'LmlUAm-elHHBnFTNJc7XZ6itcLKDdcc_MM_wrJJAA';

class _Fuente {
  _Fuente(this.datos);
  DatosTelefono? datos;
  Future<DatosTelefono?> call() async => datos;
}

GuardianLicencia _guardian({
  DatosTelefono? datos = const DatosTelefono(
    androidId: _id,
    huellaApk: 'aa:bb',
  ),
  String? huella,
}) => GuardianLicencia(
  fuente: _Fuente(datos).call,
  clavePublica: _clave,
  huellaExigida: huella,
);

Future<String?> _guardada() async => (await SharedPreferences.getInstance())
    .getString(GuardianLicencia.claveGuardada);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuardianLicencia.revisar', () {
    test('empieza sin revisar, sin código ni nombre', () {
      final g = _guardian();
      expect(g.estado, EstadoLicencia.sinRevisar);
      expect(g.codigo, isNull);
      expect(g.nombre, isNull);
    });

    test('la de fábrica no acepta nada (clave vacía)', () {
      expect(GuardianLicencia.instance.clavePublica, isEmpty);
      expect(GuardianLicencia.instance.huellaExigida, isNull);
    });

    test('licencia de Node guardada → activa con nombre y código', () async {
      SharedPreferences.setMockInitialValues({'licencia_v1': _licNode});
      final g = _guardian();
      var avisos = 0;
      g.addListener(() => avisos++);
      await g.revisar();
      expect(g.estado, EstadoLicencia.activa);
      expect(g.nombre, 'Prueba Nettia');
      expect(g.codigo, '706SD-81FDE');
      expect(avisos, 1);
    });

    test('sin licencia → sinActivar con código', () async {
      SharedPreferences.setMockInitialValues({});
      final g = _guardian();
      await g.revisar();
      expect(g.estado, EstadoLicencia.sinActivar);
      expect(g.codigo, '706SD-81FDE');
      expect(g.nombre, isNull);
    });

    test('licencia de otro teléfono → se borra y sinActivar', () async {
      SharedPreferences.setMockInitialValues({'licencia_v1': _licNode});
      final g = _guardian(
        datos: const DatosTelefono(androidId: 'otro', huellaApk: 'aa'),
      );
      await g.revisar();
      expect(g.estado, EstadoLicencia.sinActivar);
      expect(await _guardada(), isNull);
    });

    test('sin datos del teléfono → noActivable y no borra', () async {
      SharedPreferences.setMockInitialValues({'licencia_v1': _licNode});
      final g = _guardian(datos: null);
      await g.revisar();
      expect(g.estado, EstadoLicencia.noActivable);
      expect(g.codigo, isNull);
      expect(await _guardada(), _licNode);
    });

    test('huella distinta → bloqueada, borra y sin nombre', () async {
      SharedPreferences.setMockInitialValues({'licencia_v1': _licNode});
      final g = _guardian(huella: 'CC:DD');
      await g.revisar();
      expect(g.estado, EstadoLicencia.bloqueada);
      expect(g.nombre, isNull);
      expect(await _guardada(), isNull);
    });

    test(
      'huella igual sin importar dos puntos ni mayúsculas → activa',
      () async {
        SharedPreferences.setMockInitialValues({'licencia_v1': _licNode});
        final g = _guardian(huella: 'AABB');
        await g.revisar();
        expect(g.estado, EstadoLicencia.activa);
      },
    );

    test('activa que deja de valer en otra revisión → sinActivar', () async {
      SharedPreferences.setMockInitialValues({'licencia_v1': _licNode});
      final fuente = _Fuente(
        const DatosTelefono(androidId: _id, huellaApk: 'a'),
      );
      final g = GuardianLicencia(fuente: fuente.call, clavePublica: _clave);
      await g.revisar();
      expect(g.estado, EstadoLicencia.activa);
      fuente.datos = const DatosTelefono(androidId: 'otro', huellaApk: 'a');
      await g.revisar();
      expect(g.estado, EstadoLicencia.sinActivar);
      expect(g.nombre, isNull);
    });
  });

  group('GuardianLicencia.activar', () {
    test('válida → true, activa y guardada', () async {
      SharedPreferences.setMockInitialValues({});
      final g = _guardian();
      await g.revisar();
      expect(await g.activar(' $_licNode\n'), isTrue);
      expect(g.estado, EstadoLicencia.activa);
      expect(g.nombre, 'Prueba Nettia');
      expect(await _guardada(), ' $_licNode\n');
    });

    test('inválida → false y nada guardado', () async {
      SharedPreferences.setMockInitialValues({});
      final g = _guardian();
      await g.revisar();
      expect(await g.activar('hola'), isFalse);
      expect(g.estado, EstadoLicencia.sinActivar);
      expect(await _guardada(), isNull);
    });

    test('fuera de sinActivar no activa (bloqueada, sin revisar)', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await _guardian().activar(_licNode), isFalse);
      final g = _guardian(huella: 'CC');
      await g.revisar();
      expect(await g.activar(_licNode), isFalse);
      expect(g.estado, EstadoLicencia.bloqueada);
      expect(await _guardada(), isNull);
    });
  });

  group('leerTelefonoAndroid', () {
    const canal = MethodChannel('nettia/licencia');
    final mensajero =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    void responder(Object? Function(MethodCall) f) =>
        mensajero.setMockMethodCallHandler(canal, (c) async => f(c));

    tearDown(() => mensajero.setMockMethodCallHandler(canal, null));

    test('pide "datos" y arma DatosTelefono', () async {
      String? metodo;
      responder((c) {
        metodo = c.method;
        return {'androidId': _id, 'huella': 'AA:BB'};
      });
      final d = await leerTelefonoAndroid();
      expect(metodo, 'datos');
      expect(d!.androidId, _id);
      expect(d.huellaApk, 'AA:BB');
    });

    final vacios = <String, Object?>{
      'mapa nulo': null,
      'sin androidId': {'huella': 'AA'},
      'androidId vacío': {'androidId': '', 'huella': 'AA'},
      'sin huella': {'androidId': _id},
      'huella vacía': {'androidId': _id, 'huella': ''},
    };
    for (final c in vacios.entries) {
      test('${c.key} → null', () async {
        responder((_) => c.value);
        expect(await leerTelefonoAndroid(), isNull);
      });
    }

    test('PlatformException → null', () async {
      responder((_) => throw PlatformException(code: 'x'));
      expect(await leerTelefonoAndroid(), isNull);
    });

    test('sin implementación nativa → null', () async {
      expect(await leerTelefonoAndroid(), isNull);
    });
  });
}
