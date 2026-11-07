import 'package:ai_core/ai_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_ai/src/screens/motor_ia_card.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de `ai_core` falso: devuelve el catálogo o lanza lo indicado.
class _ServicioFalso implements core.ChatCompletionService {
  _ServicioFalso(this.respuesta);

  final Future<List<core.ModeloDisponible>> Function() respuesta;
  String? claveRecibida;

  @override
  Future<List<core.ModeloDisponible>> listarModelos({required String apiKey, String? baseUrl}) {
    claveRecibida = apiKey;
    return respuesta();
  }

  @override
  core.AiProviderType get providerType => core.AiProviderType.openRouter;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FabricaFalsa extends core.AiProviderFactory {
  _FabricaFalsa(this.servicio);

  final _ServicioFalso servicio;
  core.AiProviderType? pedido;

  @override
  core.ChatCompletionService getService(core.AiProviderType type) {
    pedido = type;
    return servicio;
  }
}

core.ModeloDisponible _modelo(String id, core.FuncionIa funcion) => core.ModeloDisponible(
      proveedor: core.AiProviderType.openRouter,
      modelId: id,
      nombreVisible: id,
      funcion: funcion,
      actualizadoEn: DateTime(2026),
    );

final _settings = AiSettingsService.instance;

Widget _crearApp({core.AiProviderFactory? fabrica, ThemeData? tema}) {
  return MaterialApp(
    theme: tema,
    home: Scaffold(body: SingleChildScrollView(child: MotorIaCard(fabrica: fabrica))),
  );
}

Future<void> _montar(WidgetTester tester, {core.AiProviderFactory? fabrica, ThemeData? tema}) async {
  await tester.pumpWidget(_crearApp(fabrica: fabrica, tema: tema));
  await tester.pump();
}

TextStyle? _estilo(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto)).style;

Future<void> _probar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Probar conexión y cargar modelos'));
  await tester.tap(find.text('Probar conexión y cargar modelos'));
  await tester.pump();
  await tester.pump();
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
  });

  group('selector de proveedor', () {
    testWidgets('muestra un chip por proveedor y marca el activo', (tester) async {
      await _montar(tester);

      expect(find.byType(ChoiceChip), findsNWidgets(AiProviderType.values.length));
      final activo = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'OpenRouter'));
      expect(activo.selected, isTrue);
      expect(activo.selectedColor, colorDeProveedor(AiProviderType.openRouter).withValues(alpha: 0.22));
      final borde = activo.shape! as RoundedRectangleBorder;
      expect(borde.side.color, colorDeProveedor(AiProviderType.openRouter));
      final otro = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Google Gemini'));
      expect(otro.selected, isFalse);
      expect((otro.shape! as RoundedRectangleBorder).side.color, Colors.transparent);
    });

    testWidgets('tocar un chip cambia el proveedor activo', (tester) async {
      await _montar(tester);

      await tester.tap(find.text('Google Gemini'));
      await tester.pump();

      expect(_settings.activeProvider, AiProviderType.gemini);
      expect(find.text('API Key de Google Gemini:'), findsOneWidget);
    });

    testWidgets('el texto de ayuda usa el color secundario del tema', (tester) async {
      const ayuda = 'Selecciona el proveedor para las consultas técnicas y de diagnóstico:';
      await _montar(tester);
      expect(_estilo(tester, ayuda)!.color, NetworkTheme.lightTextSecondary);
      expect(_estilo(tester, ayuda)!.fontSize, 13);

      await _montar(tester, tema: ThemeData(brightness: Brightness.dark));
      await tester.pumpAndSettle();
      expect(_estilo(tester, ayuda)!.color, NetworkTheme.darkTextSecondary);
    });
  });

  group('API Key', () {
    testWidgets('sin clave muestra SIN CLAVE en ámbar', (tester) async {
      await _montar(tester);

      expect(find.text('API Key de OpenRouter:'), findsOneWidget);
      expect(_estilo(tester, 'API Key de OpenRouter:')!.fontSize, 13);
      final estilo = _estilo(tester, 'SIN CLAVE')!;
      expect(estilo.color, NetworkTheme.amberAlert);
      expect(estilo.fontSize, 10);
      final caja = tester.widget<Container>(
        find.ancestor(of: find.text('SIN CLAVE'), matching: find.byType(Container)).first,
      );
      expect((caja.decoration! as BoxDecoration).color, NetworkTheme.amberAlert.withValues(alpha: 0.15));
    });

    testWidgets('con clave muestra CONFIGURADA en verde', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k-123');
      await _montar(tester);

      expect(_estilo(tester, 'CONFIGURADA')!.color, NetworkTheme.ledGreen);
      expect(find.widgetWithText(TextField, 'k-123'), findsOneWidget);
    });

    testWidgets('el ojo alterna entre ocultar y mostrar la clave', (tester) async {
      await _montar(tester);
      TextField campo() => tester.widget<TextField>(find.byType(TextField));
      expect(campo().obscureText, isTrue);
      expect(campo().decoration!.hintText, 'Pega tu clave de OpenRouter...');
      expect(campo().decoration!.isDense, isTrue);

      await tester.tap(find.byTooltip('Mostrar'));
      await tester.pump();
      expect(campo().obscureText, isFalse);

      await tester.tap(find.byTooltip('Ocultar'));
      await tester.pump();
      expect(campo().obscureText, isTrue);
    });

    testWidgets('guardar con el botón guarda la clave y avisa', (tester) async {
      await _montar(tester);

      await tester.enterText(find.byType(TextField), '  k-nueva  ');
      await tester.tap(find.byTooltip('Guardar clave'));
      await tester.pump();

      expect(_settings.getApiKey(AiProviderType.openRouter), 'k-nueva');
      expect(find.text('API Key guardada para OpenRouter'), findsOneWidget);
      final barra = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(barra.backgroundColor, colorDeProveedor(AiProviderType.openRouter));
      expect(barra.behavior, SnackBarBehavior.floating);
    });

    testWidgets('enviar el campo vacío elimina la clave', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k-vieja');
      await _montar(tester);

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(_settings.getApiKey(AiProviderType.openRouter), '');
      expect(find.text('API Key eliminada para OpenRouter'), findsOneWidget);
    });

    testWidgets('el campo se actualiza si la clave cambia por fuera', (tester) async {
      await _montar(tester);

      await _settings.setApiKey(AiProviderType.openRouter, 'k-externa');
      await tester.pump();

      expect(find.widgetWithText(TextField, 'k-externa'), findsOneWidget);
    });
  });

  group('modelo', () {
    testWidgets('sin modelo muestra la pista y no tiene opciones', (tester) async {
      await _montar(tester);

      expect(find.text('Modelo seleccionado:'), findsOneWidget);
      expect(_estilo(tester, 'Modelo seleccionado:')!.fontSize, 13);
      expect(find.text('Pulsa "Probar conexión y cargar modelos"'), findsOneWidget);
      final menu = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
      expect(menu.items, isEmpty);
      expect(menu.isExpanded, isTrue);
    });

    testWidgets('elegir un modelo del catálogo lo guarda', (tester) async {
      await _settings.setSelectedModel(AiProviderType.openRouter, 'b/actual');
      _settings.setCatalogo(AiProviderType.openRouter, ['a/uno', 'b/actual']);
      await _montar(tester);

      final menu = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
      expect(menu.items!.map((i) => i.value), ['b/actual', 'a/uno']);
      expect(menu.value, 'b/actual');

      await tester.tap(find.text('b/actual'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('a/uno').last);
      await tester.pumpAndSettle();

      expect(_settings.getSelectedModel(AiProviderType.openRouter), 'a/uno');
    });
  });

  group('modo offline', () {
    testWidgets('muestra el aviso offline en lugar de la API Key', (tester) async {
      await _settings.setActiveProvider(AiProviderType.offline);
      await _montar(tester);

      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Modo Offline activo'), findsOneWidget);
      final color = colorDeProveedor(AiProviderType.offline);
      final banner = tester.widget<Container>(
        find.ancestor(of: find.byIcon(NettiaIcons.offline), matching: find.byType(Container)).first,
      );
      final deco = banner.decoration! as BoxDecoration;
      expect(deco.color, color.withValues(alpha: 0.10));
      expect(deco.border, Border.all(color: color.withValues(alpha: 0.3)));
      expect(
        tester.widget<Text>(find.textContaining('Modo Offline activo')).style!.fontSize,
        12.5,
      );
    });

    testWidgets('probar conexión en offline confirma la base local', (tester) async {
      await _settings.setActiveProvider(AiProviderType.offline);
      await _montar(tester);

      await _probar(tester);

      expect(find.text('✅ Base de conocimiento local activa y lista.'), findsOneWidget);
    });
  });

  group('probar conexión', () {
    testWidgets('sin clave pide ingresarla', (tester) async {
      await _montar(tester);

      await _probar(tester);

      expect(find.text('⚠️ Ingresa una API Key para probar la conexión.'), findsOneWidget);
    });

    testWidgets('carga solo modelos de chat, sin repetir y ordenados', (tester) async {
      final servicio = _ServicioFalso(() async => [
            _modelo('z/chat', core.FuncionIa.chat),
            _modelo('a/chat', core.FuncionIa.chat),
            _modelo('a/chat', core.FuncionIa.chat),
            _modelo('e/embed', core.FuncionIa.embeddings),
          ]);
      final fabrica = _FabricaFalsa(servicio);
      await _montar(tester, fabrica: fabrica);
      await tester.enterText(find.byType(TextField), ' k-sin-guardar ');

      await _probar(tester);

      expect(fabrica.pedido, core.AiProviderType.openRouter);
      expect(servicio.claveRecibida, 'k-sin-guardar');
      expect(_settings.getApiKey(AiProviderType.openRouter), 'k-sin-guardar');
      expect(_settings.getCatalogo(AiProviderType.openRouter), ['a/chat', 'z/chat']);
      expect(find.text('✅ Conexión correcta: 2 modelos disponibles. Elige uno.'), findsOneWidget);
    });

    testWidgets('avisa si el proveedor no devuelve modelos de chat', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k');
      final fabrica = _FabricaFalsa(_ServicioFalso(() async => [_modelo('e', core.FuncionIa.embeddings)]));
      await _montar(tester, fabrica: fabrica);

      await _probar(tester);

      expect(
        find.text('⚠️ Conexión correcta, pero el proveedor no devolvió modelos de chat.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra el progreso y desactiva el botón mientras prueba', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k');
      final fabrica = _FabricaFalsa(_ServicioFalso(
        () => Future.delayed(const Duration(seconds: 1), () => <core.ModeloDisponible>[]),
      ));
      await _montar(tester, fabrica: fabrica);

      await tester.ensureVisible(find.text('Probar conexión y cargar modelos'));
      await tester.tap(find.text('Probar conexión y cargar modelos'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final boton = tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text('Probar conexión y cargar modelos'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
      );
      expect(boton.onPressed, isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(NettiaIcons.conexion), findsOneWidget);
    });

    testWidgets('si la tarjeta se cierra mientras prueba, no avisa ni falla', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k');
      final fabrica = _FabricaFalsa(_ServicioFalso(
        () => Future.delayed(const Duration(seconds: 1), () => [_modelo('a/x', core.FuncionIa.chat)]),
      ));
      await _montar(tester, fabrica: fabrica);
      await _probar(tester);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('otra pantalla'))));
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Conexión correcta'), findsNothing);
      expect(_settings.getCatalogo(AiProviderType.openRouter), ['a/x']);
    });

    testWidgets('clave rechazada avisa que no es válida', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k');
      final fabrica = _FabricaFalsa(_ServicioFalso(() async => throw core.AiAuthException(
            message: 'no',
            provider: core.AiProviderType.openRouter,
          )));
      await _montar(tester, fabrica: fabrica);

      await _probar(tester);

      expect(find.text('⚠️ La API Key no es válida para OpenRouter.'), findsOneWidget);
    });

    testWidgets('otro error avisa que no se pudo conectar', (tester) async {
      await _settings.setApiKey(AiProviderType.openRouter, 'k');
      final fabrica = _FabricaFalsa(_ServicioFalso(() async => throw Exception('sin red')));
      await _montar(tester, fabrica: fabrica);

      await _probar(tester);

      expect(
        find.text('⚠️ No se pudo conectar con OpenRouter: Exception: sin red'),
        findsOneWidget,
      );
    });
  });
}
