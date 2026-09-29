import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_guia/module_guia.dart';
import 'package:nettia_core/nettia_core.dart';

Widget _crearApp() {
  return MaterialApp(
    theme: NetworkTheme.darkTheme,
    home: const Scaffold(body: GuiaScreen()),
  );
}

void main() {
  testWidgets(
    'GuiaScreen renderiza introduccion y los 5 pasos de configuracion',
    (WidgetTester tester) async {
      await tester.pumpWidget(_crearApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Configura de abajo hacia arriba'),
        findsOneWidget,
      );
      expect(find.text('PASO 1 · FÍSICO'), findsOneWidget);
      expect(
        find.text('Armar la topología y conectar los cables'),
        findsOneWidget,
      );

      expect(find.text('PASO 2 · SWITCH'), findsOneWidget);
      expect(find.text('VLANs, puertos de acceso y trunk'), findsOneWidget);

      expect(find.text('PASO 3 · PCS'), findsOneWidget);
      expect(find.text('IP, máscara y gateway en cada PC'), findsOneWidget);

      expect(find.text('PASO 4 · ROUTER'), findsOneWidget);
      expect(find.text('Interfaz física y subinterfaces'), findsOneWidget);

      expect(find.text('PASO 5 · VERIFICACIÓN'), findsOneWidget);
      expect(find.text('Comunicación entre VLAN y guardado'), findsOneWidget);
    },
  );

  testWidgets('Al tocar un paso se expande mostrando detalle y comprobacion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_crearApp());
    await tester.pumpAndSettle();

    // Inicialmente los detalles no son visibles o estan colapsados
    expect(find.textContaining('show vlan brief'), findsNothing);

    // Tocar el paso 2 (Switch)
    await tester.tap(find.text('PASO 2 · SWITCH'));
    await tester.pumpAndSettle();

    // Ahora el detalle y la comprobacion se muestran
    expect(
      find.textContaining('Pestaña "Switch": Copiar Todo'),
      findsOneWidget,
    );
    expect(find.textContaining('show vlan brief'), findsOneWidget);
  });

  testWidgets('En pantalla estrecha (360px) la guia no desborda', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_crearApp());
    await tester.pumpAndSettle();

    // Expandir el primer paso
    await tester.tap(find.text('PASO 1 · FÍSICO'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
