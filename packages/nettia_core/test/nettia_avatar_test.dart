import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

void main() {
  group('pulsoAvatar', () {
    test('en el centro del pulso vale 1', () {
      expect(pulsoAvatar(0.25, 0.25, 0.22), 1.0);
    });

    test('fuera del ancho del pulso vale 0', () {
      expect(pulsoAvatar(0.9, 0.25, 0.22), 0.0);
    });

    test('decae linealmente entre el centro y el borde del ancho', () {
      expect(pulsoAvatar(0.25 + 0.11, 0.25, 0.22), closeTo(0.5, 1e-9));
    });

    test('el ciclo es circular: cerca de 0 y cerca de 1 están cerca entre sí', () {
      // centro=0, ancho=0.1: x=0.95 está a distancia 0.05 dando la vuelta.
      expect(pulsoAvatar(0.95, 0.0, 0.1), closeTo(0.5, 1e-9));
    });
  });

  testWidgets('con pensando=true empieza a animar en bucle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NettiaAvatar(pensando: true))),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NettiaAvatar), findsOneWidget);
  });

  testWidgets('al pasar de pensando=false a true, empieza a animar (rama de didUpdateWidget)', (tester) async {
    var pensando = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: Column(children: [
              NettiaAvatar(pensando: pensando),
              TextButton(
                onPressed: () => setState(() => pensando = true),
                child: const Text('empezar'),
              ),
            ]),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('empezar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NettiaAvatar), findsOneWidget);
  });

  testWidgets('al pasar de pensando=true a false, la animación se detiene', (tester) async {
    var pensando = true;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: Column(children: [
              NettiaAvatar(pensando: pensando),
              TextButton(
                onPressed: () => setState(() => pensando = false),
                child: const Text('detener'),
              ),
            ]),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('detener'));
    await tester.pump();

    // Tras dejar de pensar, la animación termina su regreso a 0 y se asienta.
    await tester.pumpAndSettle();
    expect(find.byType(NettiaAvatar), findsOneWidget);
  });

  testWidgets('si se desmonta mientras vuelve a 0 tras dejar de pensar, no lanza', (tester) async {
    var pensando = true;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: Column(children: [
              NettiaAvatar(pensando: pensando),
              TextButton(
                onPressed: () => setState(() => pensando = false),
                child: const Text('detener'),
              ),
            ]),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('detener'));
    await tester.pump();
    // A mitad del animateTo(300ms) hacia 0, antes de que el `.then()` corra.
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    // El pump final deja correr el `.then()` con el widget ya desmontado.
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  group('coloresDeAvatarCambiaron', () {
    const base = (
      fondo: Colors.black,
      borde: Colors.grey,
      linea: Colors.white,
      acento: Colors.blue,
      acento2: Colors.teal,
    );

    bool conCambio({
      Color? fondo,
      Color? borde,
      Color? linea,
      Color? acento,
      Color? acento2,
    }) =>
        coloresDeAvatarCambiaron(
          fondoAntes: base.fondo,
          fondoAhora: fondo ?? base.fondo,
          bordeAntes: base.borde,
          bordeAhora: borde ?? base.borde,
          lineaAntes: base.linea,
          lineaAhora: linea ?? base.linea,
          acentoAntes: base.acento,
          acentoAhora: acento ?? base.acento,
          acento2Antes: base.acento2,
          acento2Ahora: acento2 ?? base.acento2,
        );

    test('sin ningún cambio, no hay que repintar', () {
      expect(conCambio(), isFalse);
    });

    test('cada color por separado dispara el repintado', () {
      expect(conCambio(fondo: Colors.red), isTrue);
      expect(conCambio(borde: Colors.red), isTrue);
      expect(conCambio(linea: Colors.red), isTrue);
      expect(conCambio(acento: Colors.red), isTrue);
      expect(conCambio(acento2: Colors.red), isTrue);
    });
  });

  test('el tamaño por defecto es 28', () {
    const avatar = NettiaAvatar();
    expect(avatar.size, 28);
    expect(avatar.pensando, isFalse);
  });
}
