import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/repara_tab.dart';

void main() {
  testWidgets('la pestaña deja 12 de margen alrededor y entre bloques', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RepararTab())));
    expect(tester.widget<ListView>(find.byType(ListView)).padding, const EdgeInsets.all(12));
    expect(find.byWidgetPredicate((w) => w is SizedBox && w.height == 12 && w.width == null), findsOneWidget);
  });
}
