import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_asistente/module_asistente.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIa implements AiDiagnosisService, ConFuentesLocales {
  @override
  void cancelarStream() {}

  @override
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'General',
  }) async* {
    yield 'Respuesta de prueba con comandos.';
  }

  @override
  List<FuenteLocalUsada> get fuentesUltimaRespuesta => const [
        FuenteLocalUsada(
          id: 'router-on-a-stick',
          titulo: 'Router-on-a-stick',
          verificacion: 'fuentes-cruzadas',
          tieneComandos: true,
          comandosProbados: false,
        ),
      ];

  @override
  String sanitizarParaReporte(String texto) => texto;
}

Future<void> _preguntar(WidgetTester tester, AiDiagnosisService ia) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: NetworkTheme.darkTheme,
    home: Scaffold(body: AsistenteScreen(aiService: ia)),
  ));
  await tester.enterText(find.byType(TextField), 'como hago router on a stick');
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.tap(find.byIcon(NettiaIcons.enviar));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FeedbackService.instance.load();
  });

  testWidgets('la respuesta con fuentes locales muestra la insignia y los botones',
      (tester) async {
    await _preguntar(tester, _FakeIa());
    expect(find.textContaining('comandos NO probados en equipo'), findsOneWidget);
    expect(find.text('Me funcionó'), findsOneWidget);
    expect(find.text('No funcionó'), findsOneWidget);
    expect(find.text('Lo probé en Packet Tracer y funciona'), findsOneWidget);
  });

  testWidgets('votar guarda el comentario y agradece', (tester) async {
    await _preguntar(tester, _FakeIa());
    await tester.tap(find.text('Lo probé en Packet Tracer y funciona'));
    await tester.pump();
    await tester.pump();
    final e = FeedbackService.instance.entradas.single;
    expect(e.fragmentoId, 'router-on-a-stick');
    expect(e.veredicto, VeredictoFragmento.probadoEnPt);
    expect(find.textContaining('Gracias, guardado'), findsOneWidget);
  });

  testWidgets('"No funcionó" pide una nota opcional', (tester) async {
    await _preguntar(tester, _FakeIa());
    await tester.tap(find.text('No funcionó'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué falló?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'da error en g0/0');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(FeedbackService.instance.entradas.single.nota, 'da error en g0/0');
  });

  testWidgets('un servicio sin base local no muestra insignia', (tester) async {
    await _preguntar(tester, _SinFuentes());
    expect(find.text('Me funcionó'), findsNothing);
  });
}

class _SinFuentes implements AiDiagnosisService {
  @override
  void cancelarStream() {}

  @override
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'General',
  }) async* {
    yield 'Hola';
  }
}
