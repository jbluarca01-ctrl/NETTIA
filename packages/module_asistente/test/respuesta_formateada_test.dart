import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_asistente/src/respuesta_formateada.dart';
import 'package:nettia_core/nettia_core.dart';

Widget _envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

void main() {
  group('RespuestaFormateada — tablas Markdown', () {
    testWidgets(
      'una tabla Markdown (GFM) se renderiza como tabla real, no como '
      'texto con barras verticales crudas',
      (tester) async {
        const texto = '''
| Bloque | Máscara (CIDR) | Hosts |
| --- | --- | --- |
| 1 | /25 | 126 |
| 2 | /26 | 62 |
''';
        await tester.pumpWidget(_envolver(const RespuestaFormateada(texto: texto)));
        await tester.pumpAndSettle();

        expect(find.byType(Table), findsOneWidget);
        expect(find.textContaining('| Bloque |'), findsNothing);
        expect(find.text('Bloque'), findsOneWidget);
        expect(find.text('126'), findsOneWidget);
      },
    );

    testWidgets('los bloques de código siguen usando el editor propio (no Markdown)', (
      tester,
    ) async {
      const texto = 'Antes\n```cisco\nvlan 10\n```\nDespués';
      await tester.pumpWidget(_envolver(const RespuestaFormateada(texto: texto)));
      await tester.pumpAndSettle();

      expect(find.byType(EditorCodeBlock), findsOneWidget);
      expect(find.text('Antes'), findsOneWidget);
      expect(find.text('Después'), findsOneWidget);
    });

    testWidgets('negrita y código en línea se siguen viendo bien fuera de tablas', (
      tester,
    ) async {
      const texto = 'Usa **enable secret** y el comando `show ip route`.';
      await tester.pumpWidget(_envolver(const RespuestaFormateada(texto: texto)));
      await tester.pumpAndSettle();

      expect(find.textContaining('enable secret'), findsOneWidget);
      expect(find.textContaining('show ip route'), findsOneWidget);
    });
  });
}
