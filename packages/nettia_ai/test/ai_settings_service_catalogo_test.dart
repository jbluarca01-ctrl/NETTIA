import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AiSettingsService.instance.load();
  });

  group('AiSettingsService.getCatalogo/setCatalogo', () {
    test('sin catálogo cargado todavía, la lista está vacía', () {
      expect(
        AiSettingsService.instance.getCatalogo(AiProviderType.openRouter),
        isEmpty,
      );
    });

    test(
      'el catálogo cargado para un proveedor se mantiene disponible '
      '(no se pierde al "salir y volver a entrar" a la pantalla)',
      () {
        AiSettingsService.instance.setCatalogo(
          AiProviderType.openRouter,
          const ['modelo-a', 'modelo-b'],
        );

        // Simula releer el catálogo como si la pantalla de configuración se
        // hubiera cerrado y vuelto a abrir: sigue ahí sin repetir la
        // consulta al proveedor.
        expect(
          AiSettingsService.instance.getCatalogo(AiProviderType.openRouter),
          ['modelo-a', 'modelo-b'],
        );
      },
    );

    test('el catálogo es independiente por proveedor', () {
      AiSettingsService.instance
          .setCatalogo(AiProviderType.openRouter, const ['or-1']);
      AiSettingsService.instance
          .setCatalogo(AiProviderType.gemini, const ['gem-1', 'gem-2']);

      expect(
        AiSettingsService.instance.getCatalogo(AiProviderType.openRouter),
        ['or-1'],
      );
      expect(
        AiSettingsService.instance.getCatalogo(AiProviderType.gemini),
        ['gem-1', 'gem-2'],
      );
    });
  });
}
