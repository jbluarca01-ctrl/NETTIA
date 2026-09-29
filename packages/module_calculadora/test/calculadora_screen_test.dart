import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/module_calculadora.dart';
import 'package:nettia_core/nettia_core.dart';

/// `find.text` no ve el contenido de `SelectableText`; este cubre ambos.
Finder _t(String texto) => find.byWidgetPredicate((w) =>
    (w is Text && w.data == texto) ||
    (w is SelectableText && w.data == texto));

/// Encuentra un `TextField` por el texto exacto de su controlador (a
/// diferencia de `widgetWithText`, no se confunde con un `hintText` igual).
Finder _campo(String texto) => find.byWidgetPredicate(
    (w) => w is TextField && w.controller?.text == texto);

Future<void> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: NetworkTheme.darkTheme,
    home: const Scaffold(body: CalculadoraScreen()),
  ));
  await tester.pump();
}

Future<void> _pestana(WidgetTester tester, String nombre) async {
  await tester.tap(find.widgetWithText(Tab, nombre));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la pestaña Red conserva el cálculo original', (tester) async {
    await _abrir(tester);
    expect(_t('Cálculo de Red, Máscara y Gateway'), findsOneWidget);
    expect(_t('192.168.1.0'), findsWidgets);
  });

  testWidgets(
      'Red: alternar la IP a binario y volver a decimal restaura el valor '
      'decimal (no se queda en binario)', (tester) async {
    await _abrir(tester);
    expect(_campo('192.168.1.1'), findsOneWidget);

    await tester.tap(_t('Bin'));
    await tester.pump();
    expect(_campo('11000000.10101000.00000001.00000001'), findsOneWidget);

    await tester.tap(_t('Dec'));
    await tester.pump();
    expect(_campo('192.168.1.1'), findsOneWidget);
  });

  testWidgets(
      'Red: al volver a modo CIDR tras escribir una máscara manual, se usa '
      'esa máscara y no la del CIDR seleccionado antes', (tester) async {
    await _abrir(tester);

    // Selecciona /28 en el dropdown CIDR (el valor inicial es /24).
    await tester.tap(find.text('/24'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/28').last);
    await tester.pumpAndSettle();
    expect(_t('255.255.255.240 (/28)'), findsOneWidget);

    // Cambia a "Máscara dec." y escribe la máscara de /12.
    await tester.tap(_t('Máscara dec.'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, '255.255.255.240'), '255.240.0.0');
    await tester.pump();
    expect(_t('255.240.0.0 (/12)'), findsOneWidget);

    // Vuelve a "CIDR": debe seguir reflejando /12, no el /28 elegido antes.
    await tester.tap(_t('CIDR'));
    await tester.pump();
    expect(_t('255.240.0.0 (/12)'), findsOneWidget);
    expect(_t('255.255.255.240 (/28)'), findsNothing);
  });

  testWidgets('Dividir: 192.168.1.0/24 en 16 subredes muestra las 16 filas',
      (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');

    expect(_t('192.168.1.0/24'), findsOneWidget); // Red original
    expect(_t('/28 (255.255.255.240)'), findsOneWidget);
    expect(_t('192.168.1.0/28'), findsOneWidget);
    expect(_t('192.168.1.16/28'), findsOneWidget);
    expect(_t('192.168.1.240/28'), findsOneWidget);
    expect(_t('192.168.1.255'), findsOneWidget);
  });

  testWidgets('Dividir por hosts: 50 hosts en /24 → /26', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    expect(_t('Cantidad de subredes'), findsOneWidget);
    await tester.tap(_t('Hosts por subred'));
    await tester.pump();
    expect(_t('Hosts útiles que necesita cada subred'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '16'), '50');
    await tester.pump();

    expect(_t('/26 (255.255.255.192)'), findsOneWidget);
    expect(_t('192.168.1.192/26'), findsOneWidget);
  });

  testWidgets('Dividir: una entrada imposible muestra el error', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.enterText(find.widgetWithText(TextField, '16'), '1000');
    await tester.pump();
    expect(find.textContaining('No se puede'), findsOneWidget);
  });

  testWidgets(
      'Dividir: modo "Tamaños personalizados" da un prefijo distinto por subred '
      '(con las filas de ejemplo, igual que VLSM)', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();

    expect(_t('192.168.1.0/25'), findsOneWidget); // LAN 1 (100)
    expect(_t('192.168.1.128/26'), findsOneWidget); // LAN 2 (50)
    expect(_t('192.168.1.192/27'), findsOneWidget); // LAN 3 (25)
  });

  testWidgets(
      'Dividir: en "Tamaños personalizados" se pueden agregar y quitar filas '
      'sin romper el cálculo', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Agregar red'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Quitar'), findsNWidgets(4));
    expect(_campo('LAN 4'), findsOneWidget); // nombre de la fila nueva

    // Quita la fila recién agregada (la última, sin hosts): las 3 originales
    // se mantienen intactas.
    await tester.tap(find.byTooltip('Quitar').last);
    await tester.pump();
    await tester.pump();
    expect(_t('192.168.1.192/27'), findsOneWidget); // LAN 3 sigue igual
    expect(find.byTooltip('Quitar'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Dividir: cambiar entre los 3 modos no deja residuos ni rompe el cálculo',
      (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');

    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();
    await tester.tap(_t('Nº de subredes'));
    await tester.pump();

    expect(_t('/28 (255.255.255.240)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Dividir: vaciar "Cantidad de subredes" muestra el mensaje de campo '
      'vacío en vez de romper', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.enterText(find.widgetWithText(TextField, '16'), '');
    await tester.pump();
    expect(_t('Escribe en cuántas subredes quieres dividir.'), findsOneWidget);
  });

  testWidgets(
      'Dividir: en "Tamaños personalizados", hosts que no caben muestran el '
      'error de VLSM', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, '100'), '999999');
    await tester.pump();
    expect(find.textContaining('No caben'), findsOneWidget);
  });

  testWidgets(
      'Dividir: escribir otra red y otro prefijo recalcula (no queda fijo)',
      (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');

    await tester.enterText(_campo('192.168.1.0'), '10.0.0.0');
    await tester.pump();
    expect(_t('10.0.0.0/28'), findsOneWidget);

    await tester.tap(find.text('/24'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/26').last);
    await tester.pumpAndSettle();
    expect(_t('/30 (255.255.255.252)'), findsOneWidget);
  });

  testWidgets(
      'Dividir: en "Tamaños personalizados" se puede editar el nombre de '
      'una fila', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'LAN 1'), 'Ventas');
    await tester.pump();
    expect(_t('Ventas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Dividir: el campo "Hosts" de una fila personalizada solo acepta '
      'dígitos', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '100'), '1a2b3');
    await tester.pump();
    expect(_campo('123'), findsOneWidget);
  });

  testWidgets(
      'Dividir: el título de "Redes y hosts..." usa el tamaño de letra '
      'esperado', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();

    final titulo = tester
        .widget<Text>(_t('Redes y hosts que necesita cada una:'));
    expect(titulo.style?.fontSize, 13);
  });

  testWidgets(
      'Dividir: el modo elegido se conserva al cambiar de pestaña y volver '
      '(keep-alive)', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Dividir');
    await tester.tap(_t('Tamaños personalizados'));
    await tester.pump();
    expect(_t('192.168.1.0/25'), findsOneWidget); // confirma el modo activo

    // Salta a una pestaña lejos (fuera del rango que TabBarView precarga)
    // y vuelve: sin keep-alive, el estado se reiniciaría.
    await _pestana(tester, 'Práctica');
    await _pestana(tester, 'Dividir');

    expect(_t('192.168.1.0/25'), findsOneWidget);
  });

  testWidgets('VLSM: asigna de mayor a menor con las filas de ejemplo',
      (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'VLSM');

    expect(_t('192.168.1.0/25'), findsOneWidget); // LAN 1 (100)
    expect(_t('192.168.1.128/26'), findsOneWidget); // LAN 2 (50)
    expect(_t('192.168.1.192/27'), findsOneWidget); // LAN 3 (25)

    // Quitar una red recalcula sin errores.
    await tester.tap(find.byTooltip('Quitar').last);
    await tester.pump();
    await tester.pump();
    expect(_t('192.168.1.192/27'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'VLSM: las filas se conservan al cambiar de pestaña y volver '
      '(keep-alive)', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'VLSM');
    await tester.tap(find.byTooltip('Quitar').last);
    await tester.pump();
    await tester.pump();
    expect(_t('192.168.1.192/27'), findsNothing); // LAN 3 quitada

    // Salta a una pestaña lejos y vuelve: sin keep-alive, el estado se
    // reiniciaría a las 3 filas de ejemplo.
    await _pestana(tester, 'Práctica');
    await _pestana(tester, 'VLSM');

    expect(_t('192.168.1.192/27'), findsNothing);
    expect(find.byTooltip('Quitar'), findsNWidgets(2));
  });

  testWidgets(
      'VLSM: escribir otra red y otro prefijo recalcula (no queda fijo)',
      (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'VLSM');

    await tester.enterText(_campo('192.168.1.0'), '10.0.0.0');
    await tester.pump();
    expect(_t('10.0.0.0/25'), findsOneWidget); // LAN 1 (100) en la nueva red

    await tester.tap(find.text('/24'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/22').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('VLSM: hosts que no caben muestran el mensaje de error',
      (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'VLSM');
    await tester.enterText(find.widgetWithText(TextField, '100'), '999999');
    await tester.pump();
    expect(find.textContaining('No caben'), findsOneWidget);
  });

  testWidgets('IPv6: abrevia, tipo, EUI-64 y subneteo', (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'IPv6');

    expect(_t('2001:db8::ff00:42:8329'), findsOneWidget);
    expect(_t('Documentación'), findsOneWidget);
    expect(_t('2001:db8:acad:1:21a:2bff:fe3c:4d5e'), findsOneWidget);
    expect(_t('65536'), findsOneWidget);
    expect(_t('2.  2001:db8:acad:1::/64'), findsOneWidget);
  });

  testWidgets('Conversión: máscara, número y sumarización con los datos de ejemplo',
      (tester) async {
    await _abrir(tester);
    await _pestana(tester, 'Conversión');

    expect(_t('255.255.255.192'), findsOneWidget); // /26
    expect(_t('0.0.0.63'), findsOneWidget);
    expect(_t('C0'), findsOneWidget); // 192 en hex
    expect(_t('192.168.0.0/22'), findsOneWidget); // 4 x /24 contiguas
    expect(_t('Sí'), findsOneWidget);
  });

  testWidgets('en un teléfono angosto (360 px) ninguna pestaña desborda',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: NetworkTheme.darkTheme,
      home: const Scaffold(body: CalculadoraScreen()),
    ));
    await tester.pump();
    for (final nombre in <String>['Red', 'Dividir', 'VLSM', 'IPv6', 'Conversión', 'Práctica']) {
      await _pestana(tester, nombre);
      expect(tester.takeException(), isNull, reason: 'pestaña $nombre');
    }
  });
}
