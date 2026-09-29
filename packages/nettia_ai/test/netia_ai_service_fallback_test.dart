import 'dart:convert';

import 'package:ai_core/ai_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SSE de OpenAI/OpenRouter con un solo chunk de contenido y el centinela final.
String _sseCon(String contenido) =>
    'data: ${jsonEncode({
      'choices': [
        {
          'delta': {'content': contenido},
        },
      ],
    })}\n\ndata: [DONE]\n\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AiSettingsService.instance.load();
    await UserProfileService.instance.load();
    await AiSettingsService.instance.setActiveProvider(AiProviderType.openRouter);
    await AiSettingsService.instance.setApiKey(AiProviderType.openRouter, 'k-de-prueba');
  });

  test(
    'si el modelo elegido responde límite de tasa, reintenta solo con el '
    'siguiente del catálogo y avisa del cambio (sin que el usuario haga nada)',
    () async {
      await AiSettingsService.instance
          .setSelectedModel(AiProviderType.openRouter, 'modelo-saturado');
      AiSettingsService.instance.setCatalogo(
        AiProviderType.openRouter,
        const ['modelo-saturado', 'modelo-bueno'],
      );

      final mockClient = MockClient((http.Request req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (body['model'] == 'modelo-saturado') {
          return http.Response(
            jsonEncode({
              'error': {'message': 'Rate limit exceeded'},
            }),
            429,
          );
        }
        return http.Response(_sseCon('Hola, te ayudo con eso.'), 200);
      });

      final ia = NetiaAiService(
        factory: core.AiProviderFactory(client: mockClient),
      );

      final respuesta = await ia
          .diagnosticarFallaStream(consultaUsuario: 'hola')
          .join();

      expect(respuesta, contains('modelo-saturado'));
      expect(respuesta, contains('modelo-bueno'));
      expect(respuesta, contains('Hola, te ayudo con eso.'));
      expect(
        AiSettingsService.instance.getSelectedModel(AiProviderType.openRouter),
        'modelo-bueno',
      );
    },
  );

  test(
    'si TODOS los modelos del catálogo están saturados, muestra el aviso '
    'normal de límite alcanzado (no inventa una respuesta)',
    () async {
      await AiSettingsService.instance
          .setSelectedModel(AiProviderType.openRouter, 'modelo-a');
      AiSettingsService.instance.setCatalogo(
        AiProviderType.openRouter,
        const ['modelo-a', 'modelo-b'],
      );

      final mockClient = MockClient((http.Request req) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Rate limit exceeded'},
          }),
          429,
        );
      });

      final ia = NetiaAiService(
        factory: core.AiProviderFactory(client: mockClient),
      );

      final respuesta = await ia
          .diagnosticarFallaStream(consultaUsuario: 'hola')
          .join();

      expect(respuesta, contains('Límite de uso alcanzado'));
    },
  );

  test(
    'sin catálogo cargado, un límite de tasa se muestra igual que antes '
    '(no hay a qué modelo cambiar)',
    () async {
      await AiSettingsService.instance
          .setSelectedModel(AiProviderType.openRouter, 'modelo-a');
      // Sin setCatalogo: el catálogo queda vacío.

      final mockClient = MockClient((http.Request req) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Rate limit exceeded'},
          }),
          429,
        );
      });

      final ia = NetiaAiService(
        factory: core.AiProviderFactory(client: mockClient),
      );

      final respuesta = await ia
          .diagnosticarFallaStream(consultaUsuario: 'hola')
          .join();

      expect(respuesta, contains('Límite de uso alcanzado'));
    },
  );
}
