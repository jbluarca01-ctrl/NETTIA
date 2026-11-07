import 'package:flutter/services.dart';

/// Lo que la licencia necesita saber del teléfono (SPEC-005 RF6).
class DatosTelefono {
  const DatosTelefono({required this.androidId, required this.huellaApk});

  /// `Settings.Secure.ANDROID_ID`: único por teléfono y firma de la app.
  final String androidId;

  /// SHA-256 del certificado con que se firmó el APK, `AA:BB:…`.
  final String huellaApk;
}

/// De dónde salen los datos del teléfono; `null` si no se pudieron leer.
typedef FuenteTelefono = Future<DatosTelefono?> Function();

/// Lee los datos por el canal `nettia/licencia` (MainActivity.kt).
Future<DatosTelefono?> leerTelefonoAndroid([
  MethodChannel canal = const MethodChannel('nettia/licencia'),
]) async {
  try {
    return _datos(await canal.invokeMapMethod<String, String>('datos'));
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

/// Los datos del mapa del canal, o `null` si falta alguno.
DatosTelefono? _datos(Map<String, String>? m) {
  final id = m?['androidId'] ?? '';
  final huella = m?['huella'] ?? '';
  if (id.isEmpty || huella.isEmpty) return null;
  return DatosTelefono(androidId: id, huellaApk: huella);
}
