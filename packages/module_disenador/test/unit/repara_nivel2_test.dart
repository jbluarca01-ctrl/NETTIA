import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/repara.dart';
import 'package:module_disenador/src/repara_nivel2.dart';
import 'package:module_disenador/src/repara_tab.dart';

Future<void> _nivel2(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final plan = planificarRed('192.168.10.0', 24, const [Segmento('VENTAS', 50), Segmento('TI', 20)], const OpcionesPlan());
  final ejercicio = armarEjercicio(plan, TipoFalla.subinterfazApagada, plan.segmentos[1], Random(0));
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: RepararTab(crear: () => ejercicio))));
  await tester.tap(find.text('Nuevo ejercicio'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nivel 2: escribir la corrección'));
  await tester.pumpAndSettle();
}

bool _elegido(WidgetTester tester, String texto) => tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, texto)).selected;

void main() {
  testWidgets('el chip del nivel elegido queda marcado y el otro no', (tester) async {
    await _nivel2(tester);
    expect(_elegido(tester, 'Nivel 2: escribir la corrección'), isTrue);
    expect(_elegido(tester, 'Nivel 1: elegir la causa'), isFalse);
  });

  testWidgets('el primer equipo empieza elegido y al tocar otro cambia', (tester) async {
    await _nivel2(tester);
    expect(_elegido(tester, 'SW1'), isTrue);
    expect(_elegido(tester, 'R1'), isFalse);
    await tester.tap(find.widgetWithText(ChoiceChip, 'R1'));
    await tester.pumpAndSettle();
    expect(_elegido(tester, 'R1'), isTrue);
    expect(_elegido(tester, 'SW1'), isFalse);
  });

  testWidgets('separaciones de 8 entre chips y de 12 entre bloques', (tester) async {
    await _nivel2(tester);
    for (final w in tester.widgetList<Wrap>(find.byType(Wrap))) {
      expect(w.spacing, 8);
    }
    final niveles = tester.widget<Wrap>(find.ancestor(of: find.text('Nivel 1: elegir la causa'), matching: find.byType(Wrap)));
    expect(niveles.runSpacing, 8);
    final columna = tester.widget<Column>(
      find.descendant(of: find.byType(ReparaNivel2), matching: find.byType(Column)).first,
    );
    final huecos = columna.children.whereType<SizedBox>();
    expect(huecos, isNotEmpty);
    for (final s in huecos) {
      expect(s.height, 12);
    }
  });

  testWidgets('el cuadro de comandos tiene 4 líneas y la pista "interface …"', (tester) async {
    await _nivel2(tester);
    final campo = tester.widget<TextField>(find.byKey(const ValueKey('repara_comandos')));
    expect(campo.minLines, 4);
    expect(campo.decoration!.hintText, 'interface …');
  });

  testWidgets('aplicar sin escribir nada no informa comandos no reconocidos', (tester) async {
    await _nivel2(tester);
    await tester.tap(find.text('Aplicar y auditar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No reconocido'), findsNothing);
    expect(find.text('Todavía hay problemas:'), findsOneWidget);
  });
}
