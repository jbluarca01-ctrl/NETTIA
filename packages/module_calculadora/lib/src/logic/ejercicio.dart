/// Modelo de un ejercicio de práctica (tipos, campos, resultado) y su
/// corrección campo por campo (sin Flutter).
library;

/// Tipos de ejercicio disponibles.
enum TipoEjercicio {
  dividirSubredes('Dividir en subredes'),
  hostsPorPrefijo('Hosts, máscara y wildcard'),
  vlsm('VLSM'),
  redDeIp('Red y broadcast de una IP'),
  clasificar('Clase y tipo de una IP'),
  asignable('¿Se puede asignar?'),
  ipv6Abreviar('IPv6: abreviar'),
  ipv6Eui64('IPv6: EUI-64');

  const TipoEjercicio(this.titulo);
  final String titulo;
}

/// Una pregunta con su respuesta correcta.
class CampoRespuesta {
  const CampoRespuesta(
    this.etiqueta,
    this.correcta, {
    this.ayuda = '',
    this.alternativas = const <String>[],
  });

  final String etiqueta;
  final String correcta;

  /// Otras respuestas que también se aceptan (p. ej. "reservada" para la
  /// clase E, además de "experimental").
  final List<String> alternativas;

  /// Formato esperado (p. ej. "/28" o "192.168.1.16").
  final String ayuda;
}

class Ejercicio {
  const Ejercicio({
    required this.tipo,
    required this.enunciado,
    required this.campos,
    required this.pasos,
  });

  final TipoEjercicio tipo;
  final String enunciado;
  final List<CampoRespuesta> campos;

  /// Procedimiento resuelto, para mostrar después de corregir.
  final List<String> pasos;
}

/// Resultado de corregir un campo.
class ResultadoCampo {
  const ResultadoCampo(this.campo, this.respuesta, this.acierto);
  final CampoRespuesta campo;
  final String respuesta;
  final bool acierto;
}

const _sinTilde = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};

/// Sin espacios, en minúsculas y sin tildes ("Pública" = "publica").
String _norm(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAllMapped(RegExp('[áéíóú]'), (m) => _sinTilde[m[0]]!);

/// Compara ignorando espacios, mayúsculas y la barra inicial de un prefijo
/// ("/28" y "28" cuentan igual).
bool _iguales(String correcta, String dada) {
  var a = _norm(correcta);
  var b = _norm(dada);
  if (a.startsWith('/') && !b.startsWith('/')) b = '/$b';
  if (b.isEmpty) return false;
  return a == b;
}

/// [dada] coincide con la respuesta correcta de [c] o con una alternativa.
bool _acierta(CampoRespuesta c, String dada) =>
    [c.correcta, ...c.alternativas].any((v) => _iguales(v, dada));

/// Corrige [respuestas] (una por campo, en orden).
List<ResultadoCampo> corregir(Ejercicio e, List<String> respuestas) => [
      for (var i = 0; i < e.campos.length; i++)
        ResultadoCampo(
          e.campos[i],
          i < respuestas.length ? respuestas[i] : '',
          _acierta(e.campos[i], i < respuestas.length ? respuestas[i] : ''),
        ),
    ];
