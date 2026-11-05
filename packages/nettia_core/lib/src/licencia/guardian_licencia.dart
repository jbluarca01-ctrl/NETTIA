import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'datos_telefono.dart';
import 'licencia.dart';

/// En qué punto está la licencia de este teléfono.
enum EstadoLicencia {
  /// Todavía no se revisó (solo antes del primer [GuardianLicencia.revisar]).
  sinRevisar,

  /// Hay licencia válida para este teléfono.
  activa,

  /// No hay licencia válida: solo se muestra la activación.
  sinActivar,

  /// No se pudieron leer los datos del teléfono.
  noActivable,

  /// El APK no está firmado por Jairo.
  bloqueada,
}

/// Guarda y revisa la licencia (SPEC-005 RF8–RF14). La app la revisa al
/// arrancar y al cambiar de módulo; quien escucha cambia de pantalla.
class GuardianLicencia extends ChangeNotifier {
  GuardianLicencia({
    required this.fuente,
    required this.clavePublica,
    this.huellaExigida,
  });

  /// La que usa la app. `main` la reemplaza con la configuración de venta;
  /// la de fábrica no acepta ninguna licencia (clave vacía).
  static GuardianLicencia instance = GuardianLicencia(
    fuente: const FuenteTelefonoAndroid(),
    clavePublica: const [],
  );

  /// Clave de `shared_preferences` donde vive el texto de la licencia.
  static const String claveGuardada = 'licencia_v1';

  final FuenteTelefono fuente;
  final List<int> clavePublica;

  /// Huella del certificado de venta; `null` = no se exige (debug).
  final String? huellaExigida;

  EstadoLicencia _estado = EstadoLicencia.sinRevisar;
  String? _androidId;
  String? _codigo;
  String? _nombre;

  EstadoLicencia get estado => _estado;

  /// Código del teléfono para mostrar (`null` si no se pudo leer).
  String? get codigo => _codigo;

  /// Nombre del comprador, solo con la licencia activa.
  String? get nombre => _estado == EstadoLicencia.activa ? _nombre : null;

  /// Vuelve a leer el teléfono y la licencia guardada (RF7, RF11, RF13).
  Future<void> revisar() async {
    final datos = await fuente.leer();
    if (datos == null) return _poner(EstadoLicencia.noActivable);
    final prefs = await SharedPreferences.getInstance();
    final exigida = huellaExigida;
    if (exigida != null && _huella(datos.huellaApk) != _huella(exigida)) {
      await prefs.remove(claveGuardada);
      return _poner(EstadoLicencia.bloqueada);
    }
    _androidId = datos.androidId;
    _codigo = codigoTelefono(datos.androidId);
    final texto = prefs.getString(claveGuardada);
    if (texto != null && await _aceptar(texto)) return;
    await prefs.remove(claveGuardada);
    _poner(EstadoLicencia.sinActivar);
  }

  /// Activa con el [texto] pegado. `false` si no vale para este teléfono.
  Future<bool> activar(String texto) async {
    if (_estado != EstadoLicencia.sinActivar) return false;
    if (!await _aceptar(texto)) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(claveGuardada, texto);
    return true;
  }

  Future<bool> _aceptar(String texto) async {
    final r = await verificarLicencia(
      texto,
      androidId: _androidId!,
      clavePublica: clavePublica,
    );
    if (r is! LicenciaValida) return false;
    _nombre = r.nombre;
    _poner(EstadoLicencia.activa);
    return true;
  }

  void _poner(EstadoLicencia e) {
    _estado = e;
    notifyListeners();
  }

  static String _huella(String h) => h.replaceAll(':', '').toUpperCase();
}
