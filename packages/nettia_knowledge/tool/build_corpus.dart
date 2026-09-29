// Genera `assets/corpus.json` a partir de `corpus/publicado/**/*.md`.
//
// Uso (desde `apps/nettia/packages/nettia_knowledge`):
//   dart run tool/build_corpus.dart
//
// Falla (código de salida 1) si algún fragmento publicado incumple las puertas
// de calidad. Lo que está en `corpus/borradores/` NUNCA entra al resultado.
import 'dart:convert';
import 'dart:io';

import 'package:nettia_knowledge/src/fragmento.dart';

const String kCarpetaPublicado = 'corpus/publicado';
const String kSalida = 'assets/corpus.json';

/// Lee, valida y devuelve los fragmentos publicados ordenados por id.
List<Fragmento> leerPublicados(String raiz) {
  final dir = Directory('$raiz/$kCarpetaPublicado');
  if (!dir.existsSync()) return <Fragmento>[];
  final archivos = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final fragmentos = <Fragmento>[];
  final problemas = <String>[];
  final ids = <String>{};
  for (final a in archivos) {
    final nombre = a.uri.pathSegments.last;
    try {
      final f = parseFragmentoMarkdown(a.readAsStringSync(), origen: nombre);
      problemas.addAll(f.validarParaPublicar());
      if ('${f.id}.md' != nombre) {
        problemas.add('${f.id}: el archivo debe llamarse ${f.id}.md ($nombre)');
      }
      if (!ids.add(f.id)) problemas.add('${f.id}: id repetido');
      fragmentos.add(f);
    } on FragmentoFormatException catch (e) {
      problemas.add(e.mensaje);
    }
  }
  if (problemas.isNotEmpty) {
    throw StateError(problemas.map((e) => '- $e').join('\n'));
  }
  fragmentos.sort((a, b) => a.id.compareTo(b.id));
  return fragmentos;
}

/// JSON canónico del corpus (el mismo texto que se escribe en el asset).
String corpusComoJson(List<Fragmento> fragmentos) =>
    '${const JsonEncoder.withIndent('  ').convert(
      fragmentos.map((f) => f.toJson()).toList(),
    )}\n';

void main() {
  try {
    final fragmentos = leerPublicados('.');
    File(kSalida).writeAsStringSync(corpusComoJson(fragmentos));
    stdout.writeln('OK: ${fragmentos.length} fragmentos → $kSalida');
  } on StateError catch (e) {
    stderr.writeln('Corpus inválido:\n${e.message}');
    exit(1);
  }
}
