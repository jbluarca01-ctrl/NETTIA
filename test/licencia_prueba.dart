// Licencia de prueba para los tests que arrancan NettiaApp (SPEC-005).
import 'package:nettia/src/licencia_config.dart';
import 'package:nettia_core/nettia_core.dart';

/// ANDROID_ID del teléfono de prueba (código 706SD-81FDE).
const androidIdPrueba = '9774d56d682e549c';

/// Licencia firmada con Node para [androidIdPrueba] con la clave de prueba
/// (semilla 0..31) a nombre de "Prueba Nettia".
const licenciaPrueba =
    'NT1.UHJ1ZWJhIE5ldHRpYQ.YlXp0XxUDUBC3--h9okVn9lQVnwudIZkEuILCgP4tB7c_'
    'LmlUAm-elHHBnFTNJc7XZ6itcLKDdcc_MM_wrJJAA';

/// Teléfono falso: entrega los datos dados, o ninguno.
class TelefonoFalso {
  TelefonoFalso(this.datos);
  final DatosTelefono? datos;

  Future<DatosTelefono?> call() async => datos;
}

/// Deja la app con el teléfono de prueba y la clave de debug. Devuelve la
/// entrada de preferencias con la licencia guardada.
Map<String, Object> usarTelefonoDePrueba({
  String androidId = androidIdPrueba,
  String huellaApk = 'AA:BB',
  String? huellaExigida,
  bool conDatos = true,
}) {
  GuardianLicencia.instance = GuardianLicencia(
    fuente: TelefonoFalso(
      conDatos
          ? DatosTelefono(androidId: androidId, huellaApk: huellaApk)
          : null,
    ).call,
    clavePublica: clavePublicaActiva,
    huellaExigida: huellaExigida,
  );
  return {GuardianLicencia.claveGuardada: licenciaPrueba};
}
