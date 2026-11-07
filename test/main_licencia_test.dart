import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/main.dart' as app;
import 'package:nettia/src/licencia_config.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('main usa el teléfono real y la configuración de esta build', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await t.runAsync(app.main);
    await t.pump(); // primer cuadro: la puerta empieza a revisar
    // El canal sin implementación responde por un mensaje real: hay que
    // dejar pasar tiempo de verdad, no solo microtareas.
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump();
    final g = GuardianLicencia.instance;
    expect(g.fuente, same(leerTelefonoAndroid));
    expect(g.clavePublica, clavePublicaActiva);
    expect(g.huellaExigida, huellaExigidaActiva);
    // En el test no hay canal nativo: el teléfono no se puede leer.
    expect(
      find.text(
        'No se pudo leer este teléfono. Cierra Nettia y vuelve a abrirla.',
      ),
      findsOneWidget,
    );
  });
}
