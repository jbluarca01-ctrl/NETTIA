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
