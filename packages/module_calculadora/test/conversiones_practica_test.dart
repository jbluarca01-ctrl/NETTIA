import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/src/logic/conversiones.dart';
import 'package:module_calculadora/src/logic/practica.dart';
import 'package:module_calculadora/src/practica_tab.dart';
import 'package:nettia_core/nettia_core.dart';

void main() {
  group('máscara, wildcard y prefijo', () {
    test('desde prefijo, máscara y wildcard llegan a lo mismo', () {
      for (final e in <String>['/26', '26', '255.255.255.192', '0.0.0.63']) {
        final c = convertirMascara(e);
        expect(c.prefijo, 26, reason: e);
        expect(c.mascara, '255.255.255.192');
        expect(c.wildcard, '0.0.0.63');
        expect(c.hosts, 62);
      }
    });

    test('casos extremos y errores', () {
      expect(convertirMascara('/30').hosts, 2);
      expect(convertirMascara('/31').hosts, 0);
      expect(convertirMascara('/0').mascara, '0.0.0.0');
      expect(wildcardDePrefijo(24), '0.0.0.255');
      for (final malo in <String>['255.0.255.0', '/33', 'abc', '', '300.1.1.1']) {
        expect(() => convertirMascara(malo), throwsA(isA<ConversionException>()),
            reason: malo);
      }
    });
  });

  group('bases numéricas', () {
    test('decimal, binario y hexadecimal', () {
      final d = convertirNumero('192', 10);
      expect(d.binario, '11000000');
      expect(d.hexadecimal, 'C0');
      expect(convertirNumero('11000000', 2).decimal, 192);
      expect(convertirNumero('0xFF', 16).decimal, 255);
      expect(convertirNumero('300', 10).binario, '00000001 00101100');
    });

    test('validaciones', () {
      expect(() => convertirNumero('12', 2), throwsA(isA<ConversionException>()));
      expect(() => convertirNumero('zz', 16), throwsA(isA<ConversionException>()));
      expect(() => convertirNumero('', 10), throwsA(isA<ConversionException>()));
      expect(() => convertirNumero('4294967296', 10),
          throwsA(isA<ConversionException>()));
    });
  });

  group('sumarización', () {
    test('cuatro /24 contiguas → /22 exacta', () {
      final r = sumarizarRedes(<String>[
        '192.168.0.0/24',
        '192.168.1.0/24',
        '192.168.2.0/24',
        '192.168.3.0/24',
      ]);
      expect(r.red, '192.168.0.0');
      expect(r.prefijo, 22);
      expect(r.mascara, '255.255.252.0');
      expect(r.exacta, isTrue);
    });

    test('tres /24 → /22 pero no exacta (sobra una /24)', () {
      final r = sumarizarRedes(<String>[
        '192.168.0.0/24',
        '192.168.1.0/24',
        '192.168.2.0/24',
      ]);
      expect(r.prefijo, 22);
      expect(r.exacta, isFalse);
      expect(r.direccionesSobrantes, 256);
    });

    test('redes no contiguas necesitan un resumen más grande', () {
      final r = sumarizarRedes(<String>['10.0.0.0/24', '10.0.200.0/24']);
      expect(r.red, '10.0.0.0');
      expect(r.prefijo, 16);
      expect(r.exacta, isFalse);
    });

    test('detecta solapes y valida entradas', () {
      expect(sumarizarRedes(<String>['10.0.0.0/23', '10.0.1.0/24']).exacta, isFalse);
      expect(() => sumarizarRedes(<String>['10.0.0.0/24']),
          throwsA(isA<ConversionException>()));
      expect(() => sumarizarRedes(<String>['10.0.0.5/24', '10.0.1.0/24']),
          throwsA(isA<ConversionException>()));
      expect(() => sumarizarRedes(<String>['hola', '10.0.1.0/24']),
          throwsA(isA<ConversionException>()));
    });
  });

  group('práctica', () {
    test('con las respuestas correctas todo se marca acierto (100 ejercicios)', () {
      for (final tipo in TipoEjercicio.values) {
        for (var seed = 0; seed < 20; seed++) {
          final e = generarEjercicio(tipo, Random(seed));
          expect(e.campos, isNotEmpty);
          expect(e.pasos, isNotEmpty);
          final r = corregir(e, e.campos.map((c) => c.correcta).toList());
          expect(r.every((x) => x.acierto), isTrue, reason: '${tipo.name} seed $seed');
        }
      }
    });

    test('respuestas vacías o erróneas no cuentan', () {
      final e = generarEjercicio(TipoEjercicio.dividirSubredes, Random(3));
      expect(corregir(e, <String>['', '', '', '', '']).any((x) => x.acierto), isFalse);
      expect(corregir(e, <String>['x']).any((x) => x.acierto), isFalse);
    });

    test('el prefijo se acepta con o sin barra y con espacios', () {
      final e = generarEjercicio(TipoEjercicio.dividirSubredes, Random(5));
      final n = e.campos.first.correcta.replaceAll('/', '');
      expect(corregir(e, <String>[n]).first.acierto, isTrue);
      expect(corregir(e, <String>[' /$n ']).first.acierto, isTrue);
    });

    test('la misma semilla da el mismo ejercicio', () {
      final a = generarEjercicio(TipoEjercicio.vlsm, Random(9));
      final b = generarEjercicio(TipoEjercicio.vlsm, Random(9));
      expect(a.enunciado, b.enunciado);
    });

    test('el ejercicio de 16 subredes coincide con el de la calculadora', () {
      for (var seed = 0; seed < 300; seed++) {
        final e = generarEjercicio(TipoEjercicio.dividirSubredes, Random(seed));
        if (e.enunciado.contains('en 16 subredes') && e.enunciado.contains('/24')) {
          expect(e.campos[0].correcta, '/28');
          expect(e.campos[1].correcta, '255.255.255.240');
          expect(e.campos[2].correcta, '14');
          return;
        }
      }
      fail('no apareció el caso de 16 subredes en 300 semillas');
    });
  });

  testWidgets('la pestaña Práctica corrige y muestra el procedimiento', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: NetworkTheme.darkTheme,
      home: Scaffold(body: PracticaTab(rnd: Random(1))),
    ));
    await tester.pumpAndSettle();

    final esperado = generarEjercicio(TipoEjercicio.dividirSubredes, Random(1));
    expect(find.textContaining(esperado.enunciado), findsOneWidget);

    final campos = find.byType(TextField);
    expect(campos, findsNWidgets(esperado.campos.length));
    for (var i = 0; i < esperado.campos.length; i++) {
      await tester.enterText(campos.at(i), esperado.campos[i].correcta);
    }
    await tester.tap(find.text('Corregir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('¡Todo correcto!'), findsOneWidget);
    expect(find.textContaining('Cómo se calcula'), findsOneWidget);
  });

  testWidgets('un error se marca y muestra la respuesta correcta', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: NetworkTheme.darkTheme,
      home: Scaffold(body: PracticaTab(rnd: Random(1))),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '/1');
    await tester.tap(find.text('Corregir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Correcto: '), findsWidgets);
    expect(find.textContaining('Revisa las marcadas'), findsOneWidget);
  });
}
