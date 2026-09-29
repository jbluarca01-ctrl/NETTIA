import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_asistente/module_asistente.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAiService implements AiDiagnosisService {
  final StreamController<String> _controller = StreamController<String>();

  @override
  void cancelarStream() {}

  @override
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'General',
  }) {
    Future.microtask(() {
      _controller.add(
        'Hola, para configurar una VLAN usa:\n```cisco\nvlan 10\n```',
      );
      _controller.close();
    });
    return _controller.stream;
  }
}

/// Servicio controlado a mano: cada llamada abre un stream nuevo que solo
/// emite lo que el test le mande explícitamente con [emitir]/[cerrar].
class _FakeAiServiceControlable implements AiDiagnosisService {
  StreamController<String>? _controller;

  @override
  void cancelarStream() {}

  @override
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'General',
  }) {
    _controller = StreamController<String>();
    return _controller!.stream;
  }

  void emitir(String token) => _controller?.add(token);
  void cerrar() => _controller?.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HistorialConversacionesService.instance.load();
  });

  group('Historial de conversaciones', () {
    testWidgets(
      'al terminar una respuesta, la conversación queda guardada sola en el '
      'historial (sin que el usuario haga nada)',
      (tester) async {
        final aiService = _FakeAiService();
        await tester.pumpWidget(
          MaterialApp(
            theme: NetworkTheme.darkTheme,
            home: Scaffold(body: AsistenteScreen(aiService: aiService)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '¿Cómo creo una VLAN?');
        await tester.tap(find.byIcon(NettiaIcons.enviar));
        await tester.pumpAndSettle();

        final guardadas = HistorialConversacionesService.instance.conversaciones;
        expect(guardadas, hasLength(1));
        expect(guardadas.single.titulo, '¿Cómo creo una VLAN?');
        expect(guardadas.single.mensajes, hasLength(2));
      },
    );

    testWidgets(
      'el botón de historial abre la lista y reabrir una conversación la '
      'recarga completa en el chat',
      (tester) async {
        await HistorialConversacionesService.instance.guardar(
          Conversacion(
            id: 'vieja',
            fecha: DateTime(2026, 1, 1),
            titulo: '¿Qué es un trunk?',
            mensajes: const [
              MensajeGuardado(texto: '¿Qué es un trunk?', esUsuario: true),
              MensajeGuardado(texto: 'Es un enlace que lleva varias VLAN.', esUsuario: false),
            ],
          ),
        );

        final aiService = _FakeAiService();
        await tester.pumpWidget(
          MaterialApp(
            theme: NetworkTheme.darkTheme,
            home: Scaffold(body: AsistenteScreen(aiService: aiService)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();

        expect(find.text('¿Qué es un trunk?'), findsWidgets);
        await tester.tap(find.text('¿Qué es un trunk?').first);
        await tester.pumpAndSettle();

        expect(find.text('Es un enlace que lleva varias VLAN.'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'si el usuario sube el scroll mientras responde, no lo regresa al fondo '
    'con cada token nuevo (antes le impedía leer desde el principio)',
    (WidgetTester tester) async {
      final aiService = _FakeAiServiceControlable();

      await tester.pumpWidget(
        MaterialApp(
          theme: NetworkTheme.darkTheme,
          home: Scaffold(body: AsistenteScreen(aiService: aiService)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '¿Cómo creo una VLAN?');
      await tester.tap(find.byIcon(NettiaIcons.enviar));
      await tester.pump();

      // Una respuesta larga (muchas líneas) para que la lista tenga de
      // verdad contenido fuera de la pantalla y se pueda desplazar.
      final lineas = List<String>.generate(60, (i) => 'Línea $i de la explicación.');
      aiService.emitir(lineas.join('\n'));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final listFinder = find.byType(ListView);
      ScrollController controlador() =>
          tester.widget<ListView>(listFinder).controller!;

      expect(controlador().offset, controlador().position.maxScrollExtent);

      // El usuario arrastra hacia arriba para leer desde el principio.
      await tester.drag(listFinder, const Offset(0, 300));
      await tester.pump();
      final offsetTrasSubir = controlador().offset;
      expect(offsetTrasSubir, lessThan(controlador().position.maxScrollExtent));

      // Llega otro token mientras el usuario sigue leyendo arriba.
      aiService.emitir('\nMás texto que sigue llegando...');
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // No debió regresar al fondo: el usuario sigue viendo lo mismo.
      expect(controlador().offset, offsetTrasSubir);

      aiService.cerrar();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    },
  );

  testWidgets('muestra el banner de aviso de IA y mensaje de bienvenida', (
    WidgetTester tester,
  ) async {
    final aiService = _FakeAiService();

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: Scaffold(body: AsistenteScreen(aiService: aiService)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Respuestas generadas por IA'), findsOneWidget);
    expect(find.text('Hola, soy NETIA'), findsOneWidget);
  });

  testWidgets('envía pregunta y renderiza respuesta con bloque de código', (
    WidgetTester tester,
  ) async {
    final aiService = _FakeAiService();

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: Scaffold(body: AsistenteScreen(aiService: aiService)),
      ),
    );
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    expect(input, findsOneWidget);

    await tester.enterText(input, '¿Cómo creo una VLAN?');
    await tester.tap(find.byIcon(NettiaIcons.enviar));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo creo una VLAN?'), findsOneWidget);
    expect(find.textContaining('vlan 10'), findsOneWidget);
  });
}
