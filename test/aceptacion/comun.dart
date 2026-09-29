// Adaptador gherkart → flutter_test, reutilizado por cada feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:gherkart/gherkart_io.dart';

/// Tester del escenario en curso: cada escenario corre como `testWidgets`
/// para que los pasos puedan construir la app. Los pasos que leen archivos
/// deben usar E/S síncrona (la asíncrona no avanza dentro de testWidgets).
late WidgetTester probador;

void _test(
  String name, {
  List<String>? tags,
  bool skip = false,
  Future<void> Function(void context)? callback,
}) {
  testWidgets(
    name,
    (tester) async {
      probador = tester;
      await callback!(null);
    },
    tags: tags,
    skip: skip,
  );
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
