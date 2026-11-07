import 'dart:async';

import 'package:ai_core/ai_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_ai/src/screens/aviso.dart';
import 'package:nettia_ai/src/screens/comentarios_card.dart';
import 'package:nettia_ai/src/screens/guia_api_key_card.dart';
import 'package:nettia_ai/src/screens/motor_ia_card.dart';
import 'package:nettia_ai/src/screens/perfil_card.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'soporte/instantanea.dart';

/// Detalle de Ajustes (4.º ciclo del gate, 2026-11-06): aspecto fijado con
/// instantáneas y comportamientos finos de las tarjetas.
///
///   Escenario: cada tarjeta conserva su aspecto (textos, tamaños, márgenes)
///   Escenario: los avisos de éxito son verdes y los demás usan el color normal
///   Escenario: la guía muestra los pasos y abre la web de cada proveedor
///   Escenario: si la web no se puede abrir, se avisa con la dirección
///   Escenario: la pantalla se redibuja cuando cambia cualquier servicio
///   Escenario: la tarjeta del motor sigue a la clave guardada y suelta el servicio al cerrarse
///   Escenario: la prueba de conexión se rinde a los 20 segundos
class _Plataforma extends UrlLauncherPlatform {
  _Plataforma({this.abre = true});

  final bool abre;
  final List<String> abiertas = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    abiertas.add(url);
    return abre;
  }
}

class _ServicioColgado implements core.ChatCompletionService {
  @override
  Future<List<core.ModeloDisponible>> listarModelos({required String apiKey, String? baseUrl}) =>
      Completer<List<core.ModeloDisponible>>().future;

  @override
  core.AiProviderType get providerType => core.AiProviderType.openRouter;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FabricaColgada extends core.AiProviderFactory {
  @override
  core.ChatCompletionService getService(core.AiProviderType type) => _ServicioColgado();
}

final _settings = AiSettingsService.instance;

Widget _app(Widget hijo) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: hijo)));

Future<void> _pantallaGrande(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await _settings.load();
    for (final p in AiProviderType.values) {
      await _settings.setApiKey(p, '');
      await _settings.setSelectedModel(p, '');
      _settings.setCatalogo(p, const []);
    }
    await _settings.setActiveProvider(AiProviderType.openRouter);
    await UserProfileService.instance.load();
    await UserProfileService.instance.setProfile(UserProfile.estudiante);
    await FeedbackService.instance.load();
    await FeedbackService.instance.borrarTodo();
    AppearanceController.instance.setMode(AppearanceMode.light);
  });

  group('aspecto (instantáneas)', () {
    testWidgets('tarjeta de perfil', (tester) async {
      await tester.pumpWidget(_app(const PerfilCard(isDark: false)));
      expectInstantanea(instantanea(tester, find.byType(PerfilCard)), 'perfil_card');
    });

    testWidgets('tarjeta de comentarios', (tester) async {
      await tester.pumpWidget(_app(const ComentariosCard()));
      expectInstantanea(instantanea(tester, find.byType(ComentariosCard)), 'comentarios_card');
    });

    testWidgets('guía de API Key', (tester) async {
      await tester.pumpWidget(_app(const GuiaApiKeyCard(AiProviderType.openRouter)));
      expectInstantanea(instantanea(tester, find.byType(GuiaApiKeyCard)), 'guia_api_key_card');
    });

    testWidgets('tarjeta del motor con clave, catálogo y modelo', (tester) async {
      await _pantallaGrande(tester);
      await _settings.setApiKey(AiProviderType.openRouter, 'k-1');
      _settings.setCatalogo(AiProviderType.openRouter, ['a/uno', 'b/dos']);
      await _settings.setSelectedModel(AiProviderType.openRouter, 'b/dos');
      await tester.pumpWidget(_app(const MotorIaCard()));
      expectInstantanea(instantanea(tester, find.byType(MotorIaCard)), 'motor_ia_card');
    });

    testWidgets('tarjeta del motor en modo offline', (tester) async {
      await _pantallaGrande(tester);
      await _settings.setActiveProvider(AiProviderType.offline);
      await tester.pumpWidget(_app(const MotorIaCard()));
      expectInstantanea(instantanea(tester, find.byType(MotorIaCard)), 'motor_ia_card_offline');
    });

    testWidgets('tarjeta del motor mientras prueba la conexión', (tester) async {
      await _pantallaGrande(tester);
      await _settings.setApiKey(AiProviderType.openRouter, 'k-1');
      await tester.pumpWidget(_app(MotorIaCard(fabrica: _FabricaColgada())));
      await tester.tap(find.text('Probar conexión y cargar modelos'));
      await tester.pump();
      final boton = find.ancestor(
        of: find.text('Probar conexión y cargar modelos'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expectInstantanea(instantanea(tester, boton), 'motor_ia_card_probando');
      final rueda = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(rueda.strokeWidth, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 21));
    });

    testWidgets('pantalla completa de Ajustes', (tester) async {
      await _pantallaGrande(tester);
      await tester.pumpWidget(const MaterialApp(home: NetworkSettingsScreen()));
      await tester.pump();
      expectInstantanea(instantanea(tester, find.byType(ListView)), 'network_settings_screen');
      final apariencia = tester.widget<SegmentedButton<AppearanceMode>>(
        find.byType(SegmentedButton<AppearanceMode>),
      );
      expect(apariencia.showSelectedIcon, isFalse);
    });
  });

  group('avisos', () {
    Future<SnackBar> avisarYLeer(WidgetTester tester, String mensaje) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (c) => TextButton(onPressed: () => avisar(c, mensaje), child: const Text('x')))),
      ));
      await tester.tap(find.text('x'));
      await tester.pump();
      return tester.widget<SnackBar>(find.byType(SnackBar));
    }

    testWidgets('los avisos de éxito (✅) son verdes y duran 3 segundos', (tester) async {
      final s = await avisarYLeer(tester, '✅ listo');
      expect(s.backgroundColor, NetworkTheme.ledGreen.withValues(alpha: 0.95));
      expect(s.duration, const Duration(seconds: 3));
      expect(s.behavior, SnackBarBehavior.floating);
    });

    testWidgets('los demás avisos usan el color normal', (tester) async {
      final s = await avisarYLeer(tester, '⚠️ ojo');
      expect(s.backgroundColor, isNull);
      expect(s.duration, const Duration(seconds: 3));
    });
  });

  group('guía de API Key', () {
    const esperadas = {
      AiProviderType.nvidiaNim: (
        'https://build.nvidia.com',
        'Crea una cuenta en build.nvidia.com, entra a cualquier modelo NIM y genera una API Key desde el botón "Get API Key".',
      ),
      AiProviderType.openAi: (
        'https://platform.openai.com/api-keys',
        'En platform.openai.com/api-keys, pulsa "Create new secret key" y cópiala (solo se muestra una vez).',
      ),
      AiProviderType.gemini: (
        'https://aistudio.google.com/apikey',
        'En aistudio.google.com/apikey, pulsa "Create API key" con tu cuenta de Google.',
      ),
      AiProviderType.anthropic: (
        'https://console.anthropic.com',
        'En console.anthropic.com, ve a "API Keys" → "Create Key".',
      ),
      AiProviderType.openRouter: (
        'https://openrouter.ai/keys',
        'En openrouter.ai/keys, pulsa "Create Key" tras iniciar sesión.',
      ),
    };

    for (final MapEntry(key: tipo, value: (url, pasos)) in esperadas.entries) {
      testWidgets('${tipo.displayName}: muestra los pasos y abre su web', (tester) async {
        final plataforma = _Plataforma();
        UrlLauncherPlatform.instance = plataforma;
        await tester.pumpWidget(_app(GuiaApiKeyCard(tipo)));
        expect(find.text('Cómo obtener tu API Key de ${tipo.displayName}'), findsOneWidget);
        expect(find.text(pasos), findsOneWidget);
        await tester.tap(find.text('Abrir ${tipo.displayName}'));
        await tester.pump();
        expect(plataforma.abiertas, [url]);
      });
    }

    testWidgets('el modo offline no tiene guía', (tester) async {
      await tester.pumpWidget(_app(const GuiaApiKeyCard(AiProviderType.offline)));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('si la web no se puede abrir, avisa con la dirección', (tester) async {
      UrlLauncherPlatform.instance = _Plataforma(abre: false);
      await tester.pumpWidget(_app(const GuiaApiKeyCard(AiProviderType.gemini)));
      await tester.tap(find.text('Abrir Google Gemini'));
      await tester.pump();
      expect(find.text('⚠️ No se pudo abrir https://aistudio.google.com/apikey'), findsOneWidget);
    });
  });

  group('perfil y comentarios', () {
    testWidgets('cada perfil lleva su propio ícono', (tester) async {
      await tester.pumpWidget(_app(const PerfilCard(isDark: false)));
      Finder icono(String perfil, IconData i) => find.descendant(
            of: find.ancestor(of: find.text(perfil), matching: find.byWidgetPredicate((w) => w.runtimeType.toString().contains('Segment'))).first,
            matching: find.byIcon(i),
          );
      expect(icono('Estudiante', NettiaIcons.estudiante), findsOneWidget);
      expect(icono('Profesional', NettiaIcons.profesional), findsOneWidget);
    });

    testWidgets('si la tarjeta se cierra mientras copia, no avisa ni falla', (tester) async {
      final soltar = Completer<void>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
        if (llamada.method == 'Clipboard.setData') await soltar.future;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await FeedbackService.instance.registrar(EntradaFeedback(
        fecha: DateTime(2026, 11, 6),
        fragmentoId: 'f1',
        veredicto: VeredictoFragmento.values.first,
      ));
      await tester.pumpWidget(_app(const ComentariosCard()));
      await tester.tap(find.text('Copiar reporte'));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('otra'))));
      soltar.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Reporte copiado'), findsNothing);
    });
  });

  group('pantalla de Ajustes', () {
    Future<void> montar(WidgetTester tester) async {
      await _pantallaGrande(tester);
      await tester.pumpWidget(const MaterialApp(home: NetworkSettingsScreen()));
      await tester.pump();
    }

    testWidgets('muestra las secciones y las explicaciones de cada interruptor', (tester) async {
      await montar(tester);
      for (final t in [
        'Perfil de uso',
        'Apariencia',
        'Motor de Inteligencia Artificial (NETIA)',
        'Preferencias de Red & Ejecución',
        'Comentarios sobre las respuestas',
        'Claro',
        'Oscuro',
        'Automático',
        'Ignora la conexión a internet y utiliza siempre las heurísticas locales',
        'Enmascara contraseñas, comunidades SNMP, claves e IPs públicas de lo que escribas o pegues antes de mandarlo al proveedor en la nube',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('se redibuja cuando cambia la IA, la apariencia, el perfil o los comentarios', (tester) async {
      await montar(tester);
      SwitchListTile interruptor(String t) => tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, t));

      final antes = _settings.offlinePreferred;
      await _settings.setOfflinePreferred(!antes);
      await tester.pump();
      expect(interruptor('Forzar modo Offline para NETIA').value, !antes);

      AppearanceController.instance.setMode(AppearanceMode.auto);
      await tester.pump();
      expect(
        tester.widget<SegmentedButton<AppearanceMode>>(find.byType(SegmentedButton<AppearanceMode>)).selected,
        {AppearanceMode.auto},
      );

      await UserProfileService.instance.setProfile(UserProfile.profesional);
      await tester.pump();
      expect(find.text(UserProfile.profesional.descripcion), findsOneWidget);

      await FeedbackService.instance.registrar(EntradaFeedback(
        fecha: DateTime(2026, 11, 6),
        fragmentoId: 'f1',
        veredicto: VeredictoFragmento.values.first,
      ));
      await tester.pump();
      expect(find.textContaining('Guardados en este teléfono: 1.'), findsOneWidget);
    });
  });

  group('tarjeta del motor', () {
    testWidgets('un aviso que no cambia la clave no mueve el cursor del campo', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'abcdef');
      await tester.pumpWidget(_app(const MotorIaCard()));
      final campo = tester.widget<TextField>(find.byType(TextField));
      campo.controller!.selection = const TextSelection.collapsed(offset: 2);
      await _settings.setSanitizeBeforeSend(!_settings.sanitizeBeforeSend);
      await tester.pump();
      expect(campo.controller!.selection, const TextSelection.collapsed(offset: 2));
    });

    testWidgets('al cerrarse deja de escuchar los cambios de la clave', (tester) async {
      await tester.pumpWidget(_app(const MotorIaCard()));
      await tester.pumpWidget(const SizedBox());
      await _settings.setApiKey(AiProviderType.openRouter, 'otra-clave');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('el ojo cambia de ícono al mostrar la clave', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k');
      await tester.pumpWidget(_app(const MotorIaCard()));
      expect(find.byIcon(NettiaIcons.mostrar), findsOneWidget);
      expect(find.byIcon(NettiaIcons.ocultar), findsNothing);
      await tester.tap(find.byIcon(NettiaIcons.mostrar));
      await tester.pump();
      expect(find.byIcon(NettiaIcons.ocultar), findsOneWidget);
      expect(find.byIcon(NettiaIcons.mostrar), findsNothing);
    });

    testWidgets('al cambiar de proveedor, el selector muestra el modelo de ese proveedor', (tester) async {
      _settings.setCatalogo(AiProviderType.openRouter, ['or/a']);
      await _settings.setSelectedModel(AiProviderType.openRouter, 'or/a');
      _settings.setCatalogo(AiProviderType.gemini, ['ge/b']);
      await _settings.setSelectedModel(AiProviderType.gemini, 'ge/b');
      await tester.pumpWidget(_app(const MotorIaCard()));
      expect(find.text('or/a'), findsOneWidget);
      await tester.tap(find.text('Google Gemini'));
      await tester.pump();
      expect(find.text('ge/b'), findsOneWidget);
      expect(find.text('or/a'), findsNothing);
    });

    testWidgets('el aviso offline explica que no se usa internet', (tester) async {
      await _settings.setActiveProvider(AiProviderType.offline);
      await tester.pumpWidget(_app(const MotorIaCard()));
      expect(
        find.text('Modo Offline activo: el asistente NETIA responderá consultas sobre VLANs, Router-on-a-stick, subredes y protocolos industriales sin consumir datos ni requerir API Keys.'),
        findsOneWidget,
      );
    });

    testWidgets('la prueba de conexión se rinde a los 20 segundos', (tester) async {
      await _pantallaGrande(tester);
      await _settings.setApiKey(AiProviderType.openRouter, 'k');
      await tester.pumpWidget(_app(MotorIaCard(fabrica: _FabricaColgada())));
      await tester.tap(find.text('Probar conexión y cargar modelos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 19900));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('⚠️ No se pudo conectar con OpenRouter: TimeoutException'), findsOneWidget);
    });
  });
}
