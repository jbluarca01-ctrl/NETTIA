import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_ai/src/screens/comentarios_card.dart';
import 'package:nettia_ai/src/screens/perfil_card.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tarjetas de Ajustes separadas de NetworkSettingsScreen (2026-11-06).
///
///   Escenario: la tarjeta de perfil muestra el perfil actual y su descripción
///   Escenario: cambiar de perfil pide confirmación; Cancelar no cambia nada
///   Escenario: Comentarios sin entradas desactiva copiar y borrar
///   Escenario: Comentarios con entradas copia el reporte y avisa en verde
///   Escenario: Borrar comentarios vacía la lista
///   Escenario: los interruptores de la pantalla guardan su valor
Widget _app(Widget hijo, {ThemeData? tema}) => MaterialApp(
      theme: tema,
      home: Scaffold(body: SingleChildScrollView(child: hijo)),
    );

TextStyle? _estilo(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto)).style;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await UserProfileService.instance.load();
    await UserProfileService.instance.setProfile(UserProfile.estudiante);
    await FeedbackService.instance.load();
    await FeedbackService.instance.borrarTodo();
    await AiSettingsService.instance.load();
  });

  group('Perfil de uso', () {
    testWidgets('muestra el perfil actual y su descripción con el color del tema', (tester) async {
      await tester.pumpWidget(_app(const PerfilCard(isDark: false)));
      final boton = tester.widget<SegmentedButton<UserProfile>>(
        find.byType(SegmentedButton<UserProfile>),
      );
      expect(boton.selected, {UserProfile.estudiante});
      expect(boton.showSelectedIcon, isFalse);
      expect(find.text('Estudiante'), findsOneWidget);
      expect(find.text('Profesional'), findsOneWidget);
      expect(find.byIcon(NettiaIcons.estudiante), findsOneWidget);
      expect(find.byIcon(NettiaIcons.profesional), findsOneWidget);
      final desc = _estilo(tester, UserProfile.estudiante.descripcion)!;
      expect(desc.fontSize, 12.5);
      expect(desc.color, NetworkTheme.lightTextSecondary);

      await tester.pumpWidget(_app(const PerfilCard(isDark: true)));
      expect(
        _estilo(tester, UserProfile.estudiante.descripcion)!.color,
        NetworkTheme.darkTextSecondary,
      );
    });

    testWidgets('cambiar de perfil pide confirmación; Cancelar no cambia nada', (tester) async {
      await tester.pumpWidget(_app(const PerfilCard(isDark: false)));
      await tester.tap(find.text('Profesional'));
      await tester.pumpAndSettle();

      expect(find.text('Cambiar de perfil'), findsOneWidget);
      expect(
        find.text('Pasarás al perfil Profesional. El menú y el tono del '
            'asistente se ajustarán a ese perfil.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Cambiar de perfil'), findsNothing);
      expect(UserProfileService.instance.profile, UserProfile.estudiante);
    });

    testWidgets('Cambiar confirma el nuevo perfil', (tester) async {
      await tester.pumpWidget(_app(const PerfilCard(isDark: false)));
      await tester.tap(find.text('Profesional'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();
      expect(UserProfileService.instance.profile, UserProfile.profesional);
    });

    testWidgets('sin perfil guardado muestra Estudiante', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await UserProfileService.instance.load();
      await tester.pumpWidget(_app(const PerfilCard(isDark: false)));
      expect(find.text(UserProfile.estudiante.descripcion), findsOneWidget);
    });
  });

  group('Comentarios sobre las respuestas', () {
    const sinEntradas =
        'Guardados en este teléfono: 0. Son tus "Me funcionó / No funcionó / Lo probé en Packet Tracer" sobre la base local. Nada se envía solo: si quieres, copia el reporte y mándaselo al autor.';

    testWidgets('sin entradas desactiva copiar y borrar', (tester) async {
      await tester.pumpWidget(_app(const ComentariosCard()));
      expect(find.text(sinEntradas), findsOneWidget);
      expect(_estilo(tester, sinEntradas)!.fontSize, 12.5);
      final copiar = tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text('Copiar reporte'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
      );
      expect(copiar.onPressed, isNull);
      expect(find.byIcon(NettiaIcons.copiar), findsOneWidget);
      final borrar = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Borrar comentarios'));
      expect(borrar.onPressed, isNull);
    });

    Future<void> registrarUna() => FeedbackService.instance.registrar(
          EntradaFeedback(
            fecha: DateTime(2026, 11, 6),
            fragmentoId: 'vlan-01',
            veredicto: VeredictoFragmento.values.first,
          ),
        );

    testWidgets('con entradas copia el reporte y avisa en verde', (tester) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
        if (llamada.method == 'Clipboard.setData') {
          copiado = (llamada.arguments as Map)['text'] as String;
        }
        return null;
      });
      await registrarUna();
      await tester.pumpWidget(_app(const ComentariosCard()));
      expect(find.textContaining('Guardados en este teléfono: 1.'), findsOneWidget);

      await tester.tap(find.text('Copiar reporte'));
      await tester.pump();
      expect(copiado, FeedbackService.instance.reporte());
      expect(find.text('✅ Reporte copiado. Pégalo en un mensaje para el autor.'), findsOneWidget);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('Borrar comentarios vacía la lista', (tester) async {
      await registrarUna();
      await tester.pumpWidget(_app(const ComentariosCard()));
      await tester.tap(find.text('Borrar comentarios'));
      await tester.pump();
      expect(FeedbackService.instance.entradas, isEmpty);
    });
  });

  group('Interruptores de la pantalla', () {
    Future<void> tocar(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(f);
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('apariencia, modo offline y datos sensibles guardan su valor', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NetworkSettingsScreen())));
      await tester.pump();

      await tocar(tester, find.text('Oscuro'));
      expect(AppearanceController.instance.mode, AppearanceMode.dark);

      final offline = AiSettingsService.instance.offlinePreferred;
      await tocar(tester, find.text('Forzar modo Offline para NETIA'));
      expect(AiSettingsService.instance.offlinePreferred, !offline);

      final sanitiza = AiSettingsService.instance.sanitizeBeforeSend;
      await tocar(tester, find.text('Ocultar datos sensibles antes de enviar a la IA'));
      expect(AiSettingsService.instance.sanitizeBeforeSend, !sanitiza);
    });
  });
}
