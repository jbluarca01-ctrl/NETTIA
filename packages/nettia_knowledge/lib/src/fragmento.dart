/// Modelo de un fragmento del corpus, su lectura desde Markdown con
/// encabezado de metadatos y la validación que decide si puede publicarse.
///
/// Dart puro (sin Flutter): lo usa también el script de build del corpus.
library;

/// Una fuente citable de un fragmento.
class FuenteFragmento {
  const FuenteFragmento(this.titulo, this.ubicacion, this.url);

  final String titulo;

  /// Sección o capítulo dentro de la fuente (p. ej. "§2.2").
  final String ubicacion;
  final String url;

  Map<String, String> toJson() =>
      <String, String>{'titulo': titulo, 'ubicacion': ubicacion, 'url': url};

  factory FuenteFragmento.fromJson(Map<String, dynamic> j) => FuenteFragmento(
        j['titulo'] as String,
        j['ubicacion'] as String,
        j['url'] as String,
      );

  @override
  String toString() => ubicacion.isEmpty ? titulo : '$titulo, $ubicacion';
}

const Set<String> _niveles = <String>{'basico', 'intermedio', 'avanzado'};
const Set<String> _plataformas = <String>{
  'generico',
  'ios',
  'ios-xe',
  'packet-tracer',
};
const Set<String> _audiencias = <String>{'estudiante', 'profesional'};
const Set<String> _idiomas = <String>{'es', 'en'};
const Set<String> _verificaciones = <String>{
  'fuentes-cruzadas',
  'probado-en-equipo',
  'sin-verificar',
};

/// Un fragmento de conocimiento (una idea, un procedimiento o una tabla).
class Fragmento {
  const Fragmento({
    required this.id,
    required this.tema,
    required this.subtema,
    required this.titulo,
    required this.nivel,
    required this.plataforma,
    required this.version,
    required this.protocolo,
    required this.audiencia,
    required this.idioma,
    required this.estado,
    required this.verificacion,
    required this.comandosProbados,
    required this.fechaRevision,
    required this.revisadoPor,
    required this.fuentes,
    required this.palabrasClave,
    required this.contenido,
  });

  final String id;
  final String tema;
  final String subtema;
  final String titulo;
  final String nivel;
  final String plataforma;
  final String version;
  final String protocolo;
  final Set<String> audiencia;
  final String idioma;
  final String estado;

  /// `fuentes-cruzadas`: hecho contrastado en al menos dos fuentes;
  /// `probado-en-equipo`: además ejecutado en un equipo o simulador;
  /// `sin-verificar`: nunca publicable.
  final String verificacion;

  /// `true` solo si los comandos se ejecutaron en un equipo o simulador.
  final bool comandosProbados;
  final String fechaRevision;
  final String revisadoPor;
  final List<FuenteFragmento> fuentes;
  final List<String> palabrasClave;

  /// Cuerpo en Markdown.
  final String contenido;

  /// El cuerpo trae bloques de código (comandos de CLI).
  bool get tieneComandos => contenido.contains('```');

  /// Devuelve la lista de problemas que impiden **publicar** el fragmento
  /// (vacía si cumple todas las puertas de calidad).
  List<String> validarParaPublicar() {
    final p = <String>[];
    void exige(bool ok, String msg) {
      if (!ok) p.add('$id: $msg');
    }

    exige(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(id),
        'id inválido (minúsculas, dígitos y guiones)');
    exige(tema.isNotEmpty, 'falta tema');
    exige(subtema.isNotEmpty, 'falta subtema');
    exige(titulo.isNotEmpty, 'falta titulo');
    exige(_niveles.contains(nivel), 'nivel inválido "$nivel"');
    exige(_plataformas.contains(plataforma), 'plataforma inválida "$plataforma"');
    exige(protocolo.isNotEmpty, 'falta protocolo');
    exige(audiencia.isNotEmpty && audiencia.every(_audiencias.contains),
        'audiencia inválida');
    exige(_idiomas.contains(idioma), 'idioma inválido "$idioma"');
    exige(estado == 'publicado', 'estado debe ser "publicado" (es "$estado")');
    exige(_verificaciones.contains(verificacion) &&
            verificacion != 'sin-verificar',
        'verificacion no permite publicar ("$verificacion")');
    exige(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fechaRevision),
        'fecha_revision debe ser AAAA-MM-DD');
    exige(revisadoPor.isNotEmpty, 'falta revisado_por');
    exige(palabrasClave.isNotEmpty, 'faltan palabras_clave');
    exige(contenido.trim().length >= 40, 'contenido demasiado corto');
    exige(fuentes.isNotEmpty, 'falta al menos una fuente');
    if (verificacion == 'fuentes-cruzadas') {
      exige(fuentes.length >= 2,
          'fuentes-cruzadas exige al menos 2 fuentes (tiene ${fuentes.length})');
    }
    for (final f in fuentes) {
      exige(f.titulo.isNotEmpty && f.url.startsWith('http'),
          'fuente inválida "${f.titulo}"');
    }
    if (comandosProbados) {
      exige(verificacion == 'probado-en-equipo',
          'comandos_probados=si exige verificacion=probado-en-equipo');
    }
    return p;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'tema': tema,
        'subtema': subtema,
        'titulo': titulo,
        'nivel': nivel,
        'plataforma': plataforma,
        'version': version,
        'protocolo': protocolo,
        'audiencia': (audiencia.toList()..sort()),
        'idioma': idioma,
        'estado': estado,
        'verificacion': verificacion,
        'comandos_probados': comandosProbados,
        'fecha_revision': fechaRevision,
        'revisado_por': revisadoPor,
        'fuentes': fuentes.map((f) => f.toJson()).toList(),
        'palabras_clave': palabrasClave,
        'contenido': contenido,
      };

  factory Fragmento.fromJson(Map<String, dynamic> j) => Fragmento(
        id: j['id'] as String,
        tema: j['tema'] as String,
        subtema: j['subtema'] as String,
        titulo: j['titulo'] as String,
        nivel: j['nivel'] as String,
        plataforma: j['plataforma'] as String,
        version: j['version'] as String,
        protocolo: j['protocolo'] as String,
        audiencia: (j['audiencia'] as List<dynamic>).cast<String>().toSet(),
        idioma: j['idioma'] as String,
        estado: j['estado'] as String,
        verificacion: j['verificacion'] as String,
        comandosProbados: j['comandos_probados'] as bool,
        fechaRevision: j['fecha_revision'] as String,
        revisadoPor: j['revisado_por'] as String,
        fuentes: (j['fuentes'] as List<dynamic>)
            .map((e) => FuenteFragmento.fromJson(e as Map<String, dynamic>))
            .toList(),
        palabrasClave: (j['palabras_clave'] as List<dynamic>).cast<String>(),
        contenido: j['contenido'] as String,
      );
}

/// Error al leer un fragmento en Markdown.
class FragmentoFormatException implements Exception {
  const FragmentoFormatException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

List<String> _lista(String v) => v
    .split(',')
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// Lee un fragmento escrito como Markdown con encabezado de metadatos:
///
/// ```text
/// ---
/// id: ipv6-formato
/// tema: ipv6
/// ...
/// fuente: RFC 4291 | §2.2 | https://www.rfc-editor.org/rfc/rfc4291
/// ---
/// Cuerpo en Markdown.
/// ```
///
/// `fuente` puede repetirse. No valida el contenido: para eso está
/// [Fragmento.validarParaPublicar].
Fragmento parseFragmentoMarkdown(String texto, {String origen = 'fragmento'}) {
  final lineas = texto.replaceAll('\r\n', '\n').split('\n');
  if (lineas.isEmpty || lineas.first.trim() != '---') {
    throw FragmentoFormatException('$origen: debe empezar con "---"');
  }
  final fin = lineas.indexWhere((l) => l.trim() == '---', 1);
  if (fin < 0) {
    throw FragmentoFormatException('$origen: falta el "---" de cierre');
  }
  final meta = <String, String>{};
  final fuentes = <FuenteFragmento>[];
  for (var i = 1; i < fin; i++) {
    final l = lineas[i];
    if (l.trim().isEmpty || l.trim().startsWith('#')) continue;
    final c = l.indexOf(':');
    if (c < 1) {
      throw FragmentoFormatException('$origen: línea inválida "$l"');
    }
    final clave = l.substring(0, c).trim();
    final valor = l.substring(c + 1).trim();
    if (clave == 'fuente') {
      final partes = valor.split('|').map((e) => e.trim()).toList();
      if (partes.length != 3) {
        throw FragmentoFormatException(
            '$origen: fuente debe ser "título | ubicación | url" ("$valor")');
      }
      fuentes.add(FuenteFragmento(partes[0], partes[1], partes[2]));
    } else {
      meta[clave] = valor;
    }
  }
  String m(String k) => meta[k] ?? '';
  return Fragmento(
    id: m('id'),
    tema: m('tema'),
    subtema: m('subtema'),
    titulo: m('titulo'),
    nivel: m('nivel'),
    plataforma: m('plataforma'),
    version: m('version'),
    protocolo: m('protocolo'),
    audiencia: _lista(m('audiencia')).toSet(),
    idioma: m('idioma'),
    estado: m('estado'),
    verificacion: m('verificacion'),
    comandosProbados: m('comandos_probados') == 'si',
    fechaRevision: m('fecha_revision'),
    revisadoPor: m('revisado_por'),
    fuentes: fuentes,
    palabrasClave: _lista(m('palabras_clave')),
    contenido: lineas.sublist(fin + 1).join('\n').trim(),
  );
}
