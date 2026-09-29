import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Módulos de la app que el perfil puede mostrar u ocultar.
enum NettiaModulo {
  calculadora(soloProfesional: false),
  comandos(soloProfesional: false),
  asistente(soloProfesional: false),
  guia(soloProfesional: false),
  disenador(soloProfesional: false);

  const NettiaModulo({required this.soloProfesional});

  /// `true` si el módulo es una función profesional (equipos reales o
  /// contexto de producción) que el perfil estudiante no puede usar.
  /// Hoy ninguno lo es; se marcan aquí cuando existan módulos profesionales.
  /// El perfil estudiante ni lo ve en el menú ni construye su pantalla.
  final bool soloProfesional;
}

/// Perfil de uso de Nettia, elegido en el primer arranque.
enum UserProfile {
  estudiante(
    'Estudiante',
    'Explicaciones paso a paso, pistas antes de la solución, laboratorios y '
        'Packet Tracer.',
  ),
  profesional(
    'Profesional',
    'Respuestas directas con comando, verificación y riesgos; herramientas '
        'de producción.',
  );

  const UserProfile(this.etiqueta, this.descripcion);

  final String etiqueta;
  final String descripcion;

  /// Una función marcada como solo profesional queda **oculta** para el
  /// estudiante (no aparece en el menú y su código no se construye), así que
  /// tampoco puede seleccionarla. Sirve para módulos y también para submenús
  /// (pestañas, secciones): quien las arme pregunta aquí antes de mostrarlas.
  bool permite({required bool soloProfesional}) =>
      this == UserProfile.profesional || !soloProfesional;

  bool puedeUsar(NettiaModulo modulo) =>
      permite(soloProfesional: modulo.soloProfesional);

  static UserProfile? fromName(String? name) {
    for (final p in UserProfile.values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// Perfil guardado del usuario. Llamar `await UserProfileService.instance.load()`
/// antes de `runApp`; sin perfil ([profile] nulo) la app pregunta primero.
class UserProfileService extends ChangeNotifier {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  static const String _kProfile = 'nettia_user_profile';

  UserProfile? _profile;
  SharedPreferences? _prefs;

  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;

  Future<void> load() async {
    try {
      final prefs = _prefs = await SharedPreferences.getInstance();
      _profile = UserProfile.fromName(prefs.getString(_kProfile));
    } catch (e) {
      debugPrint('Nettia: no se pudo cargar el perfil de usuario: $e');
      _profile = null;
    }
    notifyListeners();
  }

  Future<void> setProfile(UserProfile profile) async {
    if (_profile == profile) return;
    _profile = profile;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kProfile, profile.name);
  }
}
