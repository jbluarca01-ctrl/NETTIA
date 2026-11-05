import 'package:flutter/services.dart';

/// Lo que la licencia necesita saber del teléfono (SPEC-005 RF6).
class DatosTelefono {
  const DatosTelefono({required this.androidId, required this.huellaApk});

  /// `Settings.Secure.ANDROID_ID`: único por teléfono y firma de la app.
  final String androidId;

  /// SHA-256 del certificado con que se firmó el APK, `AA:BB:…`.
  final String huellaApk;
}

/// De dónde salen los datos del teléfono. `null` si no se pudieron leer.
abstract interface class FuenteTelefono {
  Future<DatosTelefono?> leer();
}

/// Lee los datos por el canal `nettia/licencia` (MainActivity.kt).
class FuenteTelefonoAndroid implements FuenteTelefono {
  const FuenteTelefonoAndroid([
    this._canal = const MethodChannel('nettia/licencia'),
  ]);

  final MethodChannel _canal;

  @override
  Future<DatosTelefono?> leer() async {
    try {
      final m = await _canal.invokeMapMethod<String, String>('datos');
      final id = m?['androidId'] ?? '';
      final huella = m?['huella'] ?? '';
      if (id.isEmpty || huella.isEmpty) return null;
      return DatosTelefono(androidId: id, huellaApk: huella);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
