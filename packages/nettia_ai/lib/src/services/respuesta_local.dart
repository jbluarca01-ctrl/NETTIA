import 'package:nettia_knowledge/nettia_knowledge.dart';

/// Aviso que acompaña a los fragmentos con comandos que nadie ha ejecutado en
/// un equipo o simulador.
const String avisoComandosNoProbados =
    'Los comandos se verificaron contra documentación oficial, pero **no se '
    'han probado en un equipo ni en Packet Tracer**. Compruébalos antes de '
    'usarlos en producción.';

String _fuentesEnLinea(Fragmento f) =>
    f.fuentes.map((s) => '[${s.titulo}${s.ubicacion.isEmpty ? '' : ', ${s.ubicacion}'}](${s.url})').join(' · ');

/// Texto que se añade a la consulta cuando hay fragmentos locales (modo
/// online): el LLM debe apoyarse en ellos y citarlos. El prompt del sistema
/// (regla 4) ya manda seguir estas instrucciones.
String contextoRag(List<ResultadoBusqueda> resultados) {
  if (resultados.isEmpty) {
    return '[SIN_MANUALES_LOCALES: la base local de Nettia no tiene fragmentos '
        'para esta consulta. Responde con tu conocimiento general, aclara que '
        'no proviene de la base local y NO inventes comandos ni valores: si no '
        'estás seguro de algo, dilo.]';
  }
  final b = StringBuffer(
    '[FUENTES_LOCALES_RAG: Usa estos fragmentos de la base local de Nettia como '
    'fuente principal. Cita el id del fragmento y su fuente al final. Si no '
    'alcanzan para responder, dilo en vez de inventar. Si un comando aparece '
    'marcado como no probado, adviértelo.\n',
  );
  for (final r in resultados) {
    final f = r.fragmento;
    b.writeln('\n--- Fragmento [${f.id}] ${f.titulo}');
    b.writeln('Fuentes: ${f.fuentes.join('; ')}');
    if (f.tieneComandos && !f.comandosProbados) {
      b.writeln('Nota: comandos verificados en documentación, NO probados en equipo.');
    }
    b.writeln(f.contenido);
  }
  b.write(']');
  return b.toString();
}

/// Respuesta sin conexión: el fragmento más relevante completo, con su fuente,
/// más los títulos de los otros resultados. Es **extractiva**: no se genera ni
/// se inventa texto.
String respuestaExtractiva(List<ResultadoBusqueda> resultados) {
  final principal = resultados.first.fragmento;
  final b = StringBuffer()
    ..writeln('**${principal.titulo}**')
    ..writeln('_Respuesta de la base local de Nettia (sin conexión)._')
    ..writeln()
    ..writeln(principal.contenido)
    ..writeln()
    ..writeln('📚 **Fuente:** ${_fuentesEnLinea(principal)}');
  if (principal.tieneComandos && !principal.comandosProbados) {
    b
      ..writeln()
      ..writeln('⚠️ $avisoComandosNoProbados');
  }
  final otros = resultados.skip(1).toList();
  if (otros.isNotEmpty) {
    b
      ..writeln()
      ..writeln('**También puede interesarte:**');
    for (final r in otros) {
      b.writeln('- ${r.fragmento.titulo}');
    }
  }
  return b.toString();
}
