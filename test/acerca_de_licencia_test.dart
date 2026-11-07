import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/src/widgets/acerca_de_dialogo.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'licencia_prueba.dart';
import 'soporte/instantanea.dart';

/// "Acerca de Nettia" con la licencia activa (SPEC-005 RF12): el nombre del
/// comprador va separado del texto de la app.
///
///   Escenario: con licencia, muestra "Licenciada a" con su separación
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('con licencia, muestra "Licenciada a" con su separación', (tester) async {
    SharedPreferences.setMockInitialValues(usarTelefonoDePrueba());
    await tester.runAsync(() => GuardianLicencia.instance.revisar());
    expect(GuardianLicencia.instance.nombre, 'Prueba Nettia');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AcercaDeDialogo())),
    );
    expect(find.text('Licenciada a: Prueba Nettia'), findsOneWidget);
    final columna = find.ancestor(
      of: find.text('Licenciada a: Prueba Nettia'),
      matching: find.byType(Column),
    ).first;
    final hijos = tester.widget<Column>(columna).children;
    final separador = hijos[hijos.length - 2] as SizedBox;
    expect(separador.height, 8);
    expect(instantanea(tester, columna), contains('SizedBox(height: 8.0)'));
  });
}
