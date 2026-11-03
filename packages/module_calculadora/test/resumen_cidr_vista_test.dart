import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/module_calculadora.dart';
import 'package:nettia_core/nettia_core.dart';

Future<void> _abrirConversion(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: NetworkTheme.darkTheme,
    home: const Scaffold(body: CalculadoraScreen()),
  ));
  await tester.tap(find.widgetWithText(Tab, 'Conversión'));
  await tester.pumpAndSettle();
}

Finder _salto() => find.widgetWithText(TextField, 'Siguiente salto (opcional)');

int _sizedBoxes(double alto) => find
    .byWidgetPredicate((w) => w is SizedBox && w.height == alto)
    .evaluate()
    .length;

void main() {
  testWidgets('las 5 preguntas: título y líneas con su estilo y separación',
      (tester) async {
    await _abrirConversion(tester);

    final titulo = tester.widget<Text>(find.text('Antes de anunciar, las 5 preguntas:'));
    expect(titulo.style!.fontSize, 13);
    expect(titulo.style!.fontWeight, FontWeight.w700);

    const primera =
        '1. Mismo salto: compruebe que todas van al mismo router (siguiente salto).';
    expect(tester.widget<Text>(find.text(primera)).style!.fontSize, 12.5);
    final relleno = tester.widget<Padding>(
      find.ancestor(of: find.text(primera), matching: find.byType(Padding)).first,
    );
    expect(relleno.padding, const EdgeInsets.only(top: 4));
    // Uno en "Decimal, binario y hexadecimal" y otro antes de las preguntas.
    expect(_sizedBoxes(10), 2);
  });

  testWidgets('el campo del siguiente salto sugiere 10.0.0.2', (tester) async {
    await _abrirConversion(tester);
    expect(tester.widget<TextField>(_salto()).decoration!.hintText, '10.0.0.2');
  });

  testWidgets('al cerrar la pantalla se libera el campo del siguiente salto',
      (tester) async {
    await _abrirConversion(tester);
    final controlador = tester.widget<TextField>(_salto()).controller!;
    await tester.pumpWidget(const SizedBox());
    expect(() => controlador.addListener(() {}), throwsFlutterError);
  });
}
