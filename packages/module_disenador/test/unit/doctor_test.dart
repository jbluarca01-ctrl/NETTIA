// Casos de borde del doctor (SPEC-004) que no se ven en los escenarios.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/doctor_rutas.dart';
import 'package:module_disenador/src/logic/entrada_doctor.dart';
import 'package:module_disenador/src/logic/tabla_rutas.dart';
import 'package:module_disenador/src/vista_doctor.dart';
import 'package:module_disenador/src/vistas_resultado.dart';

const _h = Hallazgo(Gravedad.aviso, 'x', []);

void main() {
  group('ResultadoDoctor.sinDiferencias', () {
    test('sin hallazgos y sin camino', () {
      expect(const ResultadoDoctor([('R1', [])], null).sinDiferencias, isTrue);
    });
    test('sin hallazgos y camino vacío', () {
      expect(const ResultadoDoctor([('R1', [])], []).sinDiferencias, isTrue);
    });
    test('un bloque con hallazgos', () {
      expect(
        const ResultadoDoctor([('R1', [_h])], []).sinDiferencias,
        isFalse,
      );
    });
    test('el camino con hallazgos', () {
      expect(const ResultadoDoctor([('R1', [])], [_h]).sinDiferencias, isFalse);
    });
  });

  group('leerTabla', () {
    test('tras "variably subnetted" una red sin /p no se cuenta', () {
      final t = leerTabla(
        '     10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks\n'
        'S       10.1.0.0 [1/0] via 10.0.0.2',
      );
      expect(t, isEmpty);
    });
  });

  group('VistaDoctor', () {
    testWidgets('instrucción, etiqueta del cuadro y márgenes', (t) async {
      final texto = TextEditingController();
      addTearDown(texto.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VistaDoctor(
              texto,
              null,
              ModoRutas.estatica,
              onModo: (_) {},
              onRevisar: () {},
            ),
          ),
        ),
      );
      expect(
        find.text(
          'Pega una o varias running-config o show ip route de los equipos, una tras otra.',
        ),
        findsOneWidget,
      );
      expect(find.text('running-config o show ip route'), findsOneWidget);
      final lista = t.widget<ListView>(find.byType(ListView));
      expect(lista.padding, const EdgeInsets.all(12));
    });
  });

  testWidgets('campoPegado: de 6 a 14 líneas', (t) async {
    final texto = TextEditingController();
    addTearDown(texto.dispose);
    await t.pumpWidget(
      MaterialApp(home: Scaffold(body: campoPegado(texto, 'e'))),
    );
    final campo = t.widget<TextField>(find.byType(TextField));
    expect(campo.minLines, 6);
    expect(campo.maxLines, 14);
  });
}
