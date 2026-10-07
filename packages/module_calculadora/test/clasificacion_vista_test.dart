import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/src/widgets/clasificacion_vista.dart';

Future<void> _mostrar(WidgetTester tester, String ip) => tester.pumpWidget(
  MaterialApp(home: Scaffold(body: ClasificacionVista(ip))),
);

void main() {
  testWidgets('la explicación va en letra de nota (12)', (tester) async {
    await _mostrar(tester, '10.0.0.1');
    final nota = tester.widget<Text>(find.textContaining('Clase A:'));
    expect(nota.style!.fontSize, 12);
  });

  testWidgets('una IP inválida no muestra nada', (tester) async {
    await _mostrar(tester, '300.0.0.1');
    expect(find.text('Clase:'), findsNothing);
    expect(find.text('Tipo:'), findsNothing);
  });
}
