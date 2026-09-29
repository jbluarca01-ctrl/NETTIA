/// Doctor de consola: diagnostica mensajes de IOS y de una PC pegados por el
/// usuario (sin red, por reglas).
library;

/// Un problema detectado, con su causa y los pasos o comandos que lo corrigen.
class Diagnostico {
  const Diagnostico(this.titulo, this.causa, this.solucion);
  final String titulo;
  final String causa;
  final List<String> solucion;
}

List<Diagnostico> diagnosticarConsola(String salida) =>
    throw UnimplementedError();
