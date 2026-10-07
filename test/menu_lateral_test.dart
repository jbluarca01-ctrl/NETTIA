import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/src/widgets/acerca_de_dialogo.dart';
import 'package:nettia/src/widgets/drawer_cabecera.dart';
import 'package:nettia/src/widgets/network_drawer.dart';
import 'package:nettia_core/nettia_core.dart';

const _marco = Key('menu-lateral');

Future<void> _montar(
  WidgetTester tester,
  Widget hijo, {
  ThemeData? tema,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: tema ?? NetworkTheme.darkTheme,
      home: Scaffold(body: RepaintBoundary(key: _marco, child: hijo)),
    ),
  );
  // El cambio de tema entre montajes se anima.
  await tester.pumpAndSettle();
}

NetworkDrawer _menu({int noLeidos = 0}) => NetworkDrawer(
  profile: UserProfile.profesional,
  current: NettiaModulo.calculadora,
  onSelectModule: (_) {},
  onOpenSettings: () {},
  netiaUnreadCount: noLeidos,
);

void main() {
  group('iaSinConexion', () {
    test(
      'en línea solo con proveedor remoto, sin preferir offline y con clave',
      () {
        expect(
          iaSinConexion(
            proveedor: 'gemini',
            offlinePreferido: false,
            clave: 'k',
          ),
          isFalse,
        );
      },
    );

    test('el proveedor local deja la IA sin conexión', () {
      expect(
        iaSinConexion(
          proveedor: 'offline',
          offlinePreferido: false,
          clave: 'k',
        ),
        isTrue,
      );
    });

    test('preferir offline deja la IA sin conexión', () {
      expect(
        iaSinConexion(proveedor: 'gemini', offlinePreferido: true, clave: 'k'),
        isTrue,
      );
    });

    test('sin clave la IA queda sin conexión', () {
      expect(
        iaSinConexion(proveedor: 'gemini', offlinePreferido: false, clave: ''),
        isTrue,
      );
    });
  });

  group('DrawerCabecera', () {
    testWidgets('en línea: texto y punto verdes', (tester) async {
      await _montar(tester, const DrawerCabecera(offline: false));
      final texto = tester.widget<Text>(find.text('AI EN LÍNEA'));
      expect(texto.style!.color, NetworkTheme.ledGreen);
      expect(find.text('MODO OFFLINE'), findsNothing);
    });

    testWidgets('offline: texto y punto ámbar', (tester) async {
      await _montar(tester, const DrawerCabecera(offline: true));
      final texto = tester.widget<Text>(find.text('MODO OFFLINE'));
      expect(texto.style!.color, NetworkTheme.amberAlert);
      expect(find.text('AI EN LÍNEA'), findsNothing);
    });

    testWidgets('el logo usa el color del texto del tema', (tester) async {
      await _montar(tester, const DrawerCabecera(offline: false));
      final tema = NetworkTheme.darkTheme;
      final logo = tester.widget<NettiaLogo>(find.byType(NettiaLogo));
      // Mismo color que antes se tomaba de textTheme.bodyLarge.
      expect(logo.color, tema.textTheme.bodyLarge!.color);
      expect(logo.color, tema.colorScheme.onSurface);
      expect(logo.size, 28);
      final titulo = tester.widget<Text>(find.text('Nettia'));
      expect(titulo.style!.fontWeight, FontWeight.w800);
      final enContexto = Theme.of(tester.element(find.text('Nettia')));
      expect(titulo.style!.fontSize, enContexto.textTheme.titleLarge!.fontSize);
    });
  });

  group('AcercaDeDialogo', () {
    testWidgets('el logo usa los colores del tema y el título es Nettia', (
      tester,
    ) async {
      await _montar(tester, const AcercaDeDialogo());
      final tema = NetworkTheme.darkTheme;
      final logo = tester.widget<NettiaLogo>(find.byType(NettiaLogo));
      // Mismo color que antes se tomaba de textTheme.bodyLarge.
      expect(logo.color, tema.textTheme.bodyLarge!.color);
      expect(logo.color, tema.colorScheme.onSurface);
      expect(logo.accent, tema.colorScheme.primary);
      expect(logo.accent2, tema.colorScheme.tertiary);
      expect(logo.size, 22);
      expect(find.text('Nettia'), findsOneWidget);
    });
  });

  group('NetworkDrawer', () {
    testWidgets('oscuro coincide con la referencia', (tester) async {
      await _montar(tester, _menu(noLeidos: 3));
      await expectLater(
        find.byKey(_marco),
        matchesGoldenFile('golden/goldens/menu_lateral_oscuro.png'),
      );
    });

    testWidgets('claro coincide con la referencia', (tester) async {
      await _montar(tester, _menu(), tema: NetworkTheme.lightTheme);
      await expectLater(
        find.byKey(_marco),
        matchesGoldenFile('golden/goldens/menu_lateral_claro.png'),
      );
    });

    testWidgets('el diálogo Acerca de coincide con la referencia', (
      tester,
    ) async {
      final andamio = GlobalKey<ScaffoldState>();
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NetworkTheme.darkTheme,
          home: Scaffold(key: andamio, drawer: _menu()),
        ),
      );
      andamio.currentState!.openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Acerca de Nettia'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AlertDialog),
        matchesGoldenFile('golden/goldens/acerca_de_oscuro.png'),
      );
    });

    testWidgets('la insignia muestra los no leídos del asistente', (
      tester,
    ) async {
      await _montar(tester, _menu(noLeidos: 3));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('sin no leídos no hay insignia', (tester) async {
      await _montar(tester, _menu());
      expect(find.text('0'), findsNothing);
    });

    testWidgets('el fondo y el pie siguen el brillo del tema', (tester) async {
      await _montar(tester, _menu());
      expect(
        tester.widget<Drawer>(find.byType(Drawer)).backgroundColor,
        NetworkTheme.darkSurface,
      );
      expect(
        tester.widget<Text>(find.text('v1.0.0')).style!.color,
        NetworkTheme.darkTextMuted,
      );

      await _montar(tester, _menu(), tema: NetworkTheme.lightTheme);
      expect(
        tester.widget<Drawer>(find.byType(Drawer)).backgroundColor,
        NetworkTheme.lightBase,
      );
      expect(
        tester.widget<Text>(find.text('v1.0.0')).style!.color,
        NetworkTheme.lightTextSecondary,
      );
    });
  });
}
