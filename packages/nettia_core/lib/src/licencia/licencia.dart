import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Formato de licencia de Nettia (SPEC-005). Es un contrato con el
/// licenciador de Jairo: cambiarlo invalida todas las licencias vendidas.
const String _prefijo = 'NT1.';
const String _sal = 'NETTIA-TEL-1|';
const String _encabezado = 'NETTIA-LIC-1|';
String get _crockford => '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const int _largoFirma = 64;
const int _maxNombre = 60;

/// Por qué se rechazó una licencia. La pantalla muestra el mismo mensaje
/// en los dos casos; el motivo existe para los tests.
enum MotivoRechazo { formato, firma }

/// Resultado de revisar una licencia pegada.
sealed class ResultadoLicencia {
  const ResultadoLicencia();
}

/// La licencia firma este teléfono y [nombre].
final class LicenciaValida extends ResultadoLicencia {
  const LicenciaValida(this.nombre);
  final String nombre;

  @override
  bool operator ==(Object other) =>
      other is LicenciaValida && other.nombre == nombre;

  @override
  int get hashCode => nombre.hashCode;

  @override
  String toString() => 'LicenciaValida($nombre)';
}

/// La licencia no sirve en este teléfono.
final class LicenciaInvalida extends ResultadoLicencia {
  const LicenciaInvalida(this.motivo);
  final MotivoRechazo motivo;

  @override
  bool operator ==(Object other) =>
      other is LicenciaInvalida && other.motivo == motivo;

  @override
  int get hashCode => motivo.hashCode;

  @override
  String toString() => 'LicenciaInvalida(${motivo.name})';
}

/// Código del teléfono: SHA-256 de la sal + [androidId], primeros 50 bits en
/// Base32 Crockford, como `XXXXX-XXXXX`.
String codigoTelefono(String androidId) {
  final h = Sha256().toSync().hashSync(utf8.encode('$_sal$androidId')).bytes;
  var bits = 0;
  for (var i = 0; i < 7; i++) {
    bits = (bits << 8) | h[i];
  }
  bits >>= 6;
  final s = StringBuffer();
  for (var i = 9; i >= 0; i--) {
    s.write(_crockford[(bits >> (5 * i)) & 31]);
    if (i == 5) s.write('-');
  }
  return s.toString();
}

/// Bytes que firma el licenciador para [codigo] (con o sin guion) y [nombre].
List<int> mensajeLicencia(String codigo, String nombre) {
  final limpio = codigo.replaceAll('-', '').toUpperCase();
  return utf8.encode('$_encabezado$limpio|$nombre');
}

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

/// Texto de licencia que se pega en Nettia.
String armarLicencia(String nombre, List<int> firma) =>
    '$_prefijo${_b64(utf8.encode(nombre))}.${_b64(firma)}';

/// Base64url sin relleno → bytes. Lanza [FormatException] si es inválido.
List<int> decodificarBase64Url(String texto) =>
    base64Url.decode(base64Url.normalize(texto));

/// Revisa [texto] (tal como se pegó) contra este teléfono y la clave pública.
Future<ResultadoLicencia> verificarLicencia(
  String texto, {
  required String androidId,
  required List<int> clavePublica,
}) async {
  final partes = _partes(texto);
  if (partes == null) return const LicenciaInvalida(MotivoRechazo.formato);
  final (nombre, firma) = partes;
  final ok = await _firmaValida(
    mensajeLicencia(codigoTelefono(androidId), nombre),
    firma,
    clavePublica,
  );
  return ok
      ? LicenciaValida(nombre)
      : const LicenciaInvalida(MotivoRechazo.firma);
}

/// Separa nombre y firma, o `null` si el formato no es el de la licencia.
(String, List<int>)? _partes(String texto) {
  final limpio = texto.replaceAll(RegExp('[\\s"\']'), '');
  final p = limpio.split('.');
  if (p.length != 3 || '${p[0]}.' != _prefijo) return null;
  try {
    return _decodificar(p[1], p[2]);
  } on FormatException {
    return null;
  }
}

/// Nombre y firma decodificados si tienen el largo de la licencia.
(String, List<int>)? _decodificar(String nombre64, String firma64) {
  final nombre = utf8.decode(decodificarBase64Url(nombre64));
  final firma = decodificarBase64Url(firma64);
  final nombreOk = nombre.isNotEmpty && nombre.length <= _maxNombre;
  return nombreOk && firma.length == _largoFirma ? (nombre, firma) : null;
}

Future<bool> _firmaValida(
  List<int> mensaje,
  List<int> firma,
  List<int> clavePublica,
) async {
  final clave = SimplePublicKey(clavePublica, type: KeyPairType.ed25519);
  try {
    return await Ed25519().verify(
      mensaje,
      signature: Signature(firma, publicKey: clave),
    );
  } on Object {
    return false;
  }
}
