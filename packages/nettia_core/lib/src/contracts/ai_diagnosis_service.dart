import 'dart:async';

/// Contrato abstracto para el servicio de diagnóstico/asistente de IA por streaming.
/// Utilizado por el asistente NETIA y módulos de diagnóstico.
abstract interface class AiDiagnosisService {
  /// Emite una respuesta de diagnóstico/generación token por token.
  ///
  /// [consultaUsuario] es la pregunta o prompt del usuario.
  /// [datosPlaca] e [infoManual] son bloques de contexto opcionales.
  /// [categoria] indica el área o módulo (ej. "NETIA", "Redes").
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'General',
  });

  /// Cancela el stream de generación en curso, si hay uno activo.
  void cancelarStream();
}
