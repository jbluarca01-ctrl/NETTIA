/// Fragmento de la base local que respaldó una respuesta del asistente. Lo usa
/// la pantalla del chat para mostrar la insignia de verificación y recoger
/// comentarios (¿funcionó?, ¿lo probaste en Packet Tracer?).
class FuenteLocalUsada {
  const FuenteLocalUsada({
    required this.id,
    required this.titulo,
    required this.verificacion,
    required this.tieneComandos,
    required this.comandosProbados,
  });

  final String id;
  final String titulo;

  /// `fuentes-cruzadas` o `probado-en-equipo`.
  final String verificacion;
  final bool tieneComandos;
  final bool comandosProbados;
}

/// Lo implementa el servicio de IA que responde con apoyo de la base local.
abstract interface class ConFuentesLocales {
  /// Fragmentos que respaldaron la última respuesta (vacío si no hubo).
  List<FuenteLocalUsada> get fuentesUltimaRespuesta;

  /// Quita datos sensibles de un texto que se va a guardar en un reporte.
  String sanitizarParaReporte(String texto);
}
