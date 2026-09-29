import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/main.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _avanzar(WidgetTester tester, {int ms = 2200}) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('primer arranque: solo la selección de perfil, antes del splash',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();

    await tester.pumpWidget(const NettiaApp());
    await tester.pump();

    expect(find.text('¿Cómo vas a usar Nettia?'), findsOneWidget);
    expect(find.text('Nettia'), findsNothing); // ni splash ni menú
    expect(find.byTooltip('Menú'), findsNothing);

    await tester.tap(find.text('Estudiante'));
    await tester.pump();
    // Transición hacia el splash: el nombre se escribe letra a letra (pausa
    // inicial + pausa larga "pensando" tras la "N" + el resto rápido), por
    // eso hay que esperar más que antes para verlo ya completo.
    await _avanzar(tester, ms: 1600);
    // Recién ahora corre el splash y luego entra al shell.
    expect(find.text('¿Cómo vas a usar Nettia?'), findsNothing);
    expect(find.text('Nettia'), findsOneWidget); // splash, nombre ya completo
    await _avanzar(tester);
    expect(find.byTooltip('Menú'), findsOneWidget);
    expect(UserProfileService.instance.profile, UserProfile.estudiante);
  });

  testWidgets('con perfil guardado no se muestra la selección', (tester) async {
    SharedPreferences.setMockInitialValues({'nettia_user_profile': 'profesional'});
    await UserProfileService.instance.load();

    await tester.pumpWidget(const NettiaApp());
    await tester.pump();
    expect(find.text('¿Cómo vas a usar Nettia?'), findsNothing);

    await _avanzar(tester);
    expect(find.byTooltip('Menú'), findsOneWidget);
  });
}
