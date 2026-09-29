import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:nettia_core/nettia_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fragmento.dart';

/// Un fragmento recuperado con su puntaje de relevancia (mayor = mejor).
class ResultadoBusqueda {
  const ResultadoBusqueda(this.fragmento, this.puntaje, this.cobertura);

  final Fragmento fragmento;

  /// Puntaje BM25 invertido (positivo; mayor es más relevante).
  final double puntaje;

  /// Fracción de los términos de la consulta que aparecen en el fragmento.
  final double cobertura;
}

/// Palabras vacías que no aportan a la búsqueda (español e inglés).
const Set<String> _vacias = <String>{
  'a', 'al', 'algo', 'con', 'como', 'cual', 'cuales', 'cuando', 'cuanto',
  'de', 'del', 'el', 'en', 'es', 'esta', 'este', 'esto', 'la', 'las', 'lo',
  'los', 'me', 'mi', 'para', 'por', 'que', 'se', 'si', 'su', 'sus', 'un',
  'una', 'unos', 'unas', 'y', 'o', 'u', 'ni', 'hay', 'son', 'ser', 'hacer',
  'puedo', 'quiero', 'necesito', 'dime', 'explica', 'explicame', 'sobre',
  'comando', 'comandos', 'muestra', 'mostrar', 'ver', 'funciona', 'diferencia',
  'diferencias', 'existe', 'pasa', 'usa', 'usar', 'dos', 'tres', 'solo', 'sola',
  'the', 'an', 'is', 'are', 'of', 'to', 'in', 'and', 'or', 'for', 'how',
  'what', 'do', 'does', 'i', 'my', 'on', 'it', 'with',
};

/// Sinónimos es↔en de uso frecuente en redes. Cada grupo se trata como un solo
/// concepto: buscar cualquiera de sus términos busca todos.
const List<List<String>> _sinonimos = <List<String>>[
  <String>['subred', 'subredes', 'subnet', 'subnets', 'subnetting'],
  <String>['troncal', 'trunk'],
  <String>['enrutamiento', 'ruteo', 'routing'],
  <String>['enrutador', 'router'],
  <String>['conmutador', 'switch'],
  <String>['abreviar', 'comprimir', 'abreviacion', 'shorten', 'compress'],
  <String>['direccion', 'direcciones', 'address', 'addresses'],
  <String>['mascara', 'mask', 'netmask'],
  <String>['vecino', 'vecinos', 'neighbor', 'neighbors', 'adyacencia'],
  <String>['autoconfiguracion', 'slaac'],
  <String>['diagnostico', 'troubleshooting', 'depurar', 'verificar'],
  <String>['interfaz', 'interfaces', 'interface'],
  <String>['crear', 'crea', 'creo', 'creacion', 'create'],
];

/// Raíz ligera de una palabra: quita el plural más común (español e inglés) y
/// recorta las palabras largas a 6 letras, para que "abrevia", "abreviar" y
/// "abreviada" (o "vlans" y "vlan") coincidan. Se usa como prefijo en FTS5, así
/// que recortar solo amplía la coincidencia. Solo palabras alfabéticas.
String _stem(String w) {
  if (!RegExp(r'^[a-z]+$').hasMatch(w)) return w;
  var r = w;
  if (r.length > 5 && r.endsWith('es')) {
    r = r.substring(0, r.length - 2);
  } else if (r.length > 4 && r.endsWith('s')) {
    r = r.substring(0, r.length - 1);
  }
  // Terminación verbal (infinitivo o 1.ª/3.ª persona): "asigno" y "asignar".
  if (r.length >= 6) {
    if (r.endsWith('ar') || r.endsWith('er') || r.endsWith('ir')) {
      r = r.substring(0, r.length - 2);
    } else if (r.endsWith('o') || r.endsWith('a')) {
      r = r.substring(0, r.length - 1);
    }
  }
  return r.length > 6 ? r.substring(0, 6) : r;
}

/// Grupos de sinónimos ya con [_stem] aplicado, para comparar por raíz.
final List<List<String>> _grupos = _sinonimos
    .map((g) => g.map(_stem).toSet().toList())
    .toList();

List<String> _grupoDe(String t) =>
    _grupos.firstWhere((g) => g.contains(t), orElse: () => <String>[t]);

/// `true` si alguna palabra de [texto] empieza por [prefijo] (no basta con que
/// aparezca dentro de otra: "isp" no debe coincidir con "dispositivo").
bool _empiezaPalabra(String texto, String prefijo) =>
    RegExp('(^|[^a-z0-9])${RegExp.escape(prefijo)}').hasMatch(texto);

String _sinAcentos(String s) {
  const de = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const a = 'aaaaaeeeeiiiiooooouuuunc';
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    final i = de.indexOf(c);
    b.write(i >= 0 ? a[i] : c);
  }
  return b.toString();
}

/// Términos significativos de un texto: minúsculas, sin acentos, sin vacías.
/// Conserva `::` como término propio para preguntas sobre abreviar IPv6.
List<String> _terminos(String texto) {
  final t = _sinAcentos(texto);
  final out = <String>[];
  if (t.contains('::')) out.add('doblecolon');
  for (final m in RegExp(r'[a-z0-9]+').allMatches(t)) {
    final w = m.group(0)!;
    if (w.length < 2 && !RegExp(r'^\d$').hasMatch(w)) continue;
    if (_vacias.contains(w)) continue;
    out.add(_stem(w));
  }
  return out;
}

/// Base de conocimiento offline: los fragmentos publicados en un índice
/// SQLite FTS5 **en memoria** con ranking BM25.
///
/// El índice se reconstruye al iniciar desde `assets/corpus.json` (generado por
/// `tool/build_corpus.dart` a partir de `corpus/publicado/`).
class BaseConocimiento {
  BaseConocimiento._(this._fragmentos, this._db);

  final Map<String, Fragmento> _fragmentos;
  final Database _db;

  static BaseConocimiento? _instancia;

  /// Base cargada del asset del paquete, una sola vez por ejecución.
  static Future<BaseConocimiento> instancia() async {
    final existente = _instancia;
    if (existente != null) return existente;
    final json = await rootBundle.loadString(
      'packages/nettia_knowledge/assets/corpus.json',
    );
    return _instancia = BaseConocimiento.desdeJson(json);
  }

  /// Solo para pruebas: reemplaza la instancia compartida.
  static void reemplazarInstancia(BaseConocimiento? base) => _instancia = base;

  factory BaseConocimiento.desdeJson(String json) {
    final lista = (jsonDecode(json) as List<dynamic>)
        .map((e) => Fragmento.fromJson(e as Map<String, dynamic>))
        .toList();
    return BaseConocimiento.desdeFragmentos(lista);
  }

  /// Construye el índice. Falla si algún fragmento no cumple las puertas de
  /// publicación: nada sin revisar entra a la base.
  factory BaseConocimiento.desdeFragmentos(List<Fragmento> fragmentos) {
    final problemas = <String>[
      for (final f in fragmentos) ...f.validarParaPublicar(),
    ];
    if (problemas.isNotEmpty) {
      throw StateError(
          'Corpus inválido:\n${problemas.map((e) => '- $e').join('\n')}');
    }
    final db = sqlite3.openInMemory();
    db.execute('''
      CREATE VIRTUAL TABLE fragmentos USING fts5(
        titulo, palabras_clave, contenido,
        id UNINDEXED, audiencia UNINDEXED, idioma UNINDEXED,
        tokenize = 'unicode61 remove_diacritics 2'
      );
    ''');
    final ins = db.prepare(
        'INSERT INTO fragmentos (titulo, palabras_clave, contenido, id, audiencia, idioma) '
        'VALUES (?, ?, ?, ?, ?, ?)');
    try {
      for (final f in fragmentos) {
        ins.execute(<Object?>[
          f.titulo,
          '${f.palabrasClave.join(' ')} ${f.tema} ${f.subtema} ${f.protocolo}',
          f.contenido,
          f.id,
          f.audiencia.join(' '),
          f.idioma,
        ]);
      }
    } finally {
      ins.close();
    }
    return BaseConocimiento._(
      <String, Fragmento>{for (final f in fragmentos) f.id: f},
      db,
    );
  }

  int get cantidad => _fragmentos.length;
  Iterable<Fragmento> get todos => _fragmentos.values;

  /// Expresión FTS5 con OR entre conceptos; cada término lleva prefijo (`*`)
  /// para tolerar plurales y conjugaciones, y se expande con sinónimos.
  String _expresion(List<String> terminos) {
    final partes = <String>[];
    for (final t in terminos) {
      final grupo = _grupoDe(t);
      final alt = grupo
          .map((w) => w.length >= 4 ? '"$w"*' : '"$w"')
          .join(' OR ');
      partes.add(grupo.length > 1 ? '($alt)' : alt);
    }
    return partes.join(' OR ');
  }

  /// Busca los [k] fragmentos más relevantes para [consulta].
  ///
  /// El perfil **estudiante** no recibe fragmentos que sean solo para
  /// profesionales (mismo criterio de ocultamiento que en el menú). Se descartan
  /// resultados con [coberturaMinima] menor a la indicada: es preferible "no
  /// está en mi base" a una respuesta que no viene al caso.
  List<ResultadoBusqueda> buscar(
    String consulta, {
    UserProfile? perfil,
    String? idioma,
    int k = 4,
    double coberturaMinima = 0.6,
  }) {
    final terminos = _terminos(consulta).toSet().toList();
    if (terminos.isEmpty) return const <ResultadoBusqueda>[];
    // Los compuestos con guion ("link-local", "router-on-a-stick") también se
    // buscan como frase: coinciden mejor que sus palabras sueltas.
    final frases = RegExp(r'[a-z0-9]+(?:-[a-z0-9]+)+')
        .allMatches(_sinAcentos(consulta))
        .map((m) => m.group(0)!.replaceAll('-', ' '))
        .toSet();

    final filas = _db.select(
      '''
      SELECT id, bm25(fragmentos, 12.0, 6.0, 1.0) AS rank
      FROM fragmentos
      WHERE fragmentos MATCH ?
      ORDER BY rank
      LIMIT 30
      ''',
      <Object?>[
        [
          _expresion(terminos),
          for (final f in frases) '"$f"',
        ].join(' OR '),
      ],
    );

    final salida = <ResultadoBusqueda>[];
    for (final fila in filas) {
      final f = _fragmentos[fila['id'] as String]!;
      if (perfil == UserProfile.estudiante &&
          !f.audiencia.contains('estudiante')) {
        continue;
      }
      if (idioma != null && f.idioma != idioma) continue;
      final texto = _sinAcentos(
          '${f.titulo} ${f.palabrasClave.join(' ')} ${f.tema} ${f.protocolo} ${f.contenido}');
      final presentes = terminos.where((t) {
        return _grupoDe(t).any((g) => _empiezaPalabra(texto, g)) ||
            (t == 'doblecolon' && f.contenido.contains('::'));
      }).length;
      final cobertura = presentes / terminos.length;
      if (cobertura < coberturaMinima) continue;
      salida.add(ResultadoBusqueda(f, -(fila['rank'] as num).toDouble(), cobertura));
      if (salida.length == k) break;
    }
    return salida;
  }

  void cerrar() => _db.close();
}
