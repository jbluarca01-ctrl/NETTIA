import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
