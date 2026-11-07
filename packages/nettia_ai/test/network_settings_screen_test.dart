import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Plataforma falsa con la conducta de Android 11+ sin `<queries>`:
/// `canLaunch` responde false aunque el navegador sí pueda abrir la URL.
class _PlataformaAndroid11 extends UrlLauncherPlatform {
  _PlataformaAndroid11({required this.abre, this.falla = false});

  final bool abre;
  final bool falla;
  final List<String> abiertas = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (falla) throw Exception('sin actividad que maneje la URL');
    if (abre) abiertas.add(url);
    return abre;
  }
}

Widget _crearApp() {
  return const MaterialApp(
    home: Scaffold(body: NetworkSettingsScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AiSettingsService.instance.load();
    await UserProfileService.instance.load();
    await AiSettingsService.instance.setActiveProvider(AiProviderType.openRouter);
  });

  group('Guía "Cómo obtener tu API Key"', () {
    testWidgets(
      'muestra el paso a paso y el botón para abrir la web del proveedor activo',
      (tester) async {
        await tester.pumpWidget(_crearApp());
        await tester.pump();
        await tester.pump();

        expect(
          find.textContaining('Cómo obtener tu API Key de'),
          findsOneWidget,
        );
        expect(find.textContaining('openrouter.ai/keys'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Abrir OpenRouter'),
          findsOneWidget,
        );
      },
    );

    testWidgets('cambia de guía al cambiar de proveedor', (tester) async {
      await tester.pumpWidget(_crearApp());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Google Gemini'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('aistudio.google.com/apikey'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Abrir Google Gemini'),
        findsOneWidget,
      );
    });
  });

  group('Botón "Abrir proveedor" (Android 11+)', () {
    late UrlLauncherPlatform original;
    setUp(() => original = UrlLauncherPlatform.instance);
    tearDown(() => UrlLauncherPlatform.instance = original);

    Future<void> tocarAbrir(WidgetTester tester) async {
      await tester.pumpWidget(_crearApp());
      await tester.pump();
      await tester.pump();
      final boton = find.widgetWithText(OutlinedButton, 'Abrir OpenRouter');
      tester.widget<OutlinedButton>(boton).onPressed!();
      await tester.pump();
      await tester.pump();
    }

    testWidgets('abre la web aunque canLaunch responda false', (tester) async {
      final plataforma = _PlataformaAndroid11(abre: true);
      UrlLauncherPlatform.instance = plataforma;

      await tocarAbrir(tester);

      expect(plataforma.abiertas, ['https://openrouter.ai/keys']);
      expect(find.textContaining('No se pudo abrir'), findsNothing);
    });

    testWidgets('avisa si el sistema no puede abrir la web', (tester) async {
      UrlLauncherPlatform.instance = _PlataformaAndroid11(abre: false);

      await tocarAbrir(tester);

      expect(
        find.textContaining('No se pudo abrir https://openrouter.ai/keys'),
        findsOneWidget,
      );
    });

    testWidgets('avisa si abrir la web lanza una excepción', (tester) async {
      UrlLauncherPlatform.instance =
          _PlataformaAndroid11(abre: true, falla: true);

      await tocarAbrir(tester);

      expect(
        find.textContaining('No se pudo abrir https://openrouter.ai/keys'),
        findsOneWidget,
      );
    });
  });
}
