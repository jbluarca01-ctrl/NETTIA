import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia/src/screens/nettia_splash_screen.dart';

Widget _crearApp(WidgetBuilder next) {
  return MaterialApp(home: NettiaSplashScreen(next: next));
}

void main() {
  group('NettiaSplashScreen', () {
    testWidgets(
      'al arrancar solo se ve el cursor parpadeante, sin ninguna letra',
      (tester) async {
        await tester.pumpWidget(_crearApp((_) => const SizedBox()));
        await tester.pump();

        expect(find.textContaining('N'), findsNothing);
        expect(find.text('_'), findsOneWidget);
      },
    );

    testWidgets('aparece la "N" y luego hace una pausa larga antes de seguir', (
      tester,
    ) async {
      await tester.pumpWidget(_crearApp((_) => const SizedBox()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('N'), findsOneWidget);

      // Pausa larga ("pensando"): a mitad de camino todavía no siguió.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('N'), findsOneWidget);
      expect(find.text('Nettia'), findsNothing);
    });

    testWidgets('termina de escribir "Nettia" completo tras la pausa larga', (
      tester,
    ) async {
      await tester.pumpWidget(_crearApp((_) => const SizedBox()));
      await tester.pump();
      // 400ms (N) + 650ms (pausa) + 4×70ms (resto de letras, rápido).
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 650));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 70));
      }

      expect(find.text('Nettia'), findsOneWidget);
    });

    testWidgets(
      'navega a la siguiente pantalla solo despues de la pausa final',
      (tester) async {
        await tester.pumpWidget(
          _crearApp((_) => const Scaffold(body: Text('SIGUIENTE'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 650));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 70));
        }

        // "Nettia" ya completo, pero todavia no navego (falta la pausa final).
        expect(find.text('SIGUIENTE'), findsNothing);

        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.text('SIGUIENTE'), findsOneWidget);
      },
    );
  });
}
