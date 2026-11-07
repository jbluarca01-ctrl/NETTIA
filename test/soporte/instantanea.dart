import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widgets cuyo aspecto se fija en las instantáneas: textos y sus estilos,
/// íconos, espacios, márgenes, contenedores y decoraciones de campos.
const _tipos = {
  'Text',
  'Icon',
  'SizedBox',
  'Padding',
  'Wrap',
  'Container',
  'InputDecorator',
  'CustomPaint',
  'Stack',
};

/// Descripción en texto de los widgets de [_tipos] bajo [raiz], con sus
/// propiedades visibles (tamaño de letra, color, espacios, márgenes...).
/// La sangría sigue el anidamiento.
String instantanea(WidgetTester tester, Finder raiz) {
  final b = StringBuffer();
  void visitar(Element e, int nivel) {
    final w = e.widget;
    var hijo = nivel;
    if (_tipos.contains(w.runtimeType.toString())) {
      final props = w
          .toDiagnosticsNode()
          .getProperties()
          .where((p) => !p.isFiltered(DiagnosticLevel.info))
          .map((p) => '${p.name ?? ''}: ${p.toDescription()}')
          .join(', ');
      b.writeln('${'  ' * nivel}${w.runtimeType}($props)');
      hijo++;
    }
    e.visitChildren((c) => visitar(c, hijo));
  }

  visitar(tester.element(raiz), 0);
  return b.toString();
}

/// Compara [actual] con `test/instantaneas/<nombre>.txt`. Con la variable de
/// entorno `NETTIA_ACTUALIZAR_INSTANTANEAS=1` reescribe el archivo (revisar
/// el diff en git antes de commitear: es la aprobación humana del aspecto).
void expectInstantanea(String actual, String nombre) {
  final archivo = File('test/instantaneas/$nombre.txt');
  if (Platform.environment['NETTIA_ACTUALIZAR_INSTANTANEAS'] == '1') {
    archivo
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(actual);
  }
  expect(
    archivo.existsSync(),
    isTrue,
    reason: 'falta la instantánea $nombre; generarla con NETTIA_ACTUALIZAR_INSTANTANEAS=1',
  );
  expect(actual, archivo.readAsStringSync().replaceAll('\r\n', '\n'));
}
