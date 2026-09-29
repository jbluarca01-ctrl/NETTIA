import 'package:flutter_test/flutter_test.dart';
import 'package:module_comandos/src/doctor_tab.dart';

void main() {
  test('diagnosticar guarda el resultado y avisa a los oyentes', () {
    final c = DoctorConsolaControlador();
    addTearDown(c.dispose);
    var avisos = 0;
    c.addListener(() => avisos++);
    expect(c.diagnosticos, isNull);
    c.texto.text = 'Request timed out.';
    c.diagnosticar();
    expect(c.diagnosticos!.single.titulo, 'Ping sin respuesta');
    expect(avisos, 1);
  });

  test('al liberarlo se liberan el texto y los oyentes', () {
    final c = DoctorConsolaControlador()..dispose();
    expect(() => c.texto.addListener(() {}), throwsFlutterError);
    expect(() => c.addListener(() {}), throwsFlutterError);
  });
}
