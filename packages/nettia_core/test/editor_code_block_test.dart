import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

void main() {
  testWidgets('muestra un número de línea por cada línea del código', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        // Sin `const`: los constructores `const` se evalúan en tiempo de
        // compilación y nunca aparecen "cubiertos" para el instrumentador de
        // línea; esta construcción en tiempo de ejecución es la que le da a
        // EditorCodeBlock su única cobertura real de línea de constructor.
        home: Scaffold(
          body: EditorCodeBlock(code: 'interface fa0/1\n switchport mode trunk\n exit'),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('usa la etiqueta de lenguaje dada, o "cisco-ios" por defecto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: EditorCodeBlock(code: 'show ip int brief')),
      ),
    );
    expect(find.text('cisco-ios'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: EditorCodeBlock(code: 'x', lenguaje: 'texto')),
      ),
    );
    expect(find.text('texto'), findsOneWidget);
  });

  testWidgets('el botón de copiar copia el código completo al portapapeles', (tester) async {
    const codigo = 'interface fa0/1\n no shutdown';
    final llamadas = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      llamadas.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: EditorCodeBlock(code: codigo)),
      ),
    );

    await tester.tap(find.byIcon(NettiaIcons.copiar));
    await tester.pump();

    final copiado = llamadas.singleWhere((c) => c.method == 'Clipboard.setData');
    expect((copiado.arguments as Map)['text'], codigo);
    expect(find.text('Comando copiado'), findsOneWidget);
  });

  testWidgets('el aviso de copiado dura 1200 ms', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: EditorCodeBlock(code: 'x')),
      ),
    );
    await tester.tap(find.byIcon(NettiaIcons.copiar));
    await tester.pump();

    expect(tester.widget<SnackBar>(find.byType(SnackBar)).duration, const Duration(milliseconds: 1200));
  });

  testWidgets('copiar sin ScaffoldMessenger arriba no lanza', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.pumpWidget(
      WidgetsApp(
        color: Colors.black,
        pageRouteBuilder: <T>(settings, builder) =>
            PageRouteBuilder<T>(settings: settings, pageBuilder: (c, _, _) => builder(c)),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Theme(
          data: NetworkTheme.darkTheme,
          child: Material(child: EditorCodeBlock(code: 'x')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(NettiaIcons.copiar));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tamaños y colores del editor: barra 5 % blanca, código y números en 12.5', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: EditorCodeBlock(code: 'exit')),
      ),
    );

    expect(
      find.byWidgetPredicate((w) => w is ColoredBox && w.color == Colors.white.withValues(alpha: 0.05)),
      findsOneWidget,
    );
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!.style!.fontSize, 12.5);
    expect(tester.widget<Text>(find.text('1')).style!.fontSize, 12.5);
  });

  testWidgets('el texto seleccionable conserva el contenido exacto, sin líneas vacías extra', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: EditorCodeBlock(code: 'show vlan brief\n')),
      ),
    );

    final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
    final texto = selectable.textSpan!.toPlainText();
    expect(texto, 'show vlan brief');
  });
}
