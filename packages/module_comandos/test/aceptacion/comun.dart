// Adaptador gherkart → flutter_test, reutilizado por cada feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:gherkart/gherkart_io.dart';

void _test(
  String name, {
  List<String>? tags,
  bool skip = false,
  Future<void> Function(void context)? callback,
}) {
  test(name, () => callback!(null), tags: tags, skip: skip);
}

TestAdapter<void> _adaptador() => TestAdapter<void>(
      testFunction: _test,
      group: group,
      setUpAll: setUpAll,
      tearDownAll: tearDownAll,
      fail: (message) => fail(message),
    );

/// Corre los escenarios de [feature] con los [pasos] dados.
Future<void> correrFeature(String feature, StepRegistry<void> pasos) =>
    runBddTests<void>(
      rootPaths: ['features/$feature'],
      registry: pasos,
      source: FileSystemSource(),
      adapter: _adaptador(),
      structure: TestStructure.flat,
      output: const BddOutput.steps(),
    );

/// Contenido de un doc string de Gherkin sin la sangría común del archivo
/// .feature (gherkart la conserva) y sin líneas vacías en los extremos.
String docString(String? contenido) {
  final lineas = (contenido ?? '').replaceAll('\r', '').split('\n');
  final sangria = lineas
      .where((l) => l.trim().isNotEmpty)
      .map((l) => l.length - l.trimLeft().length)
      .fold<int?>(null, (m, s) => m == null || s < m ? s : m);
  return lineas
      .map((l) => l.length < (sangria ?? 0) ? '' : l.substring(sangria ?? 0))
      .join('\n')
      .trim();
}
