import 'package:flutter_test/flutter_test.dart';
import 'package:module_comandos/src/logic/doctor_consola.dart';

const String _invalida = "% Invalid input detected at '^' marker.";

String _causa(String salida) => diagnosticarConsola(salida).single.causa;

List<String> _solucion(String salida) =>
    diagnosticarConsola(salida).single.solucion;

void main() {
  group('entrada inválida sin contexto suficiente', () {
    const generica =
        'IOS no entiende una parte del comando (la marca ^ señala dónde).';

    test('la marca en la primera línea da el diagnóstico genérico', () {
      expect(_causa(_invalida), generica);
      expect(_solucion(_invalida), [
        'Escribe ? en ese punto para ver las opciones válidas.',
      ]);
    });

    test('con una sola línea antes de la marca da el genérico', () {
      expect(_causa('       ^\n$_invalida'), generica);
    });

    test('sin prompt en el comando da el genérico', () {
      expect(_causa('swithcport\n ^\n$_invalida'), generica);
    });

    test('sin ^ en la línea anterior da el genérico', () {
      expect(_causa('Router>enable\n\n$_invalida'), generica);
    });

    test('con ^ justo después del final del comando da el genérico', () {
      expect(_causa('Router>ab\n         ^\n$_invalida'), generica);
    });
  });

  group('entrada inválida con prompt', () {
    test('el ^ en la última letra toma esa letra', () {
      expect(
        _causa('Router>ab\n        ^\n$_invalida'),
        'IOS no entiende "b" en el modo usuario (Router>).',
      );
    });

    test('usa las dos líneas justo antes de la marca, no las primeras', () {
      expect(
        _causa('Router>\nRouter>enabel\n       ^\n$_invalida'),
        'IOS no entiende "enabel" en el modo usuario (Router>).',
      );
    });

    test('el ^ en la columna 0 toma la línea desde el inicio', () {
      expect(
        _causa('Router>x\n^\n$_invalida'),
        'IOS no entiende "Router>x" en el modo usuario (Router>).',
      );
    });

    test('modo privilegiado sugiere configure terminal', () {
      const salida = 'Router#confgure\n       ^\n$_invalida';
      expect(
        _causa(salida),
        'IOS no entiende "confgure" en el modo privilegiado (Router#).',
      );
      expect(
        _solucion(salida).last,
        'Si es un comando de configuración, entra con configure terminal.',
      );
    });

    test('modo de subconfiguración sugiere salir con exit', () {
      const salida =
          'Switch(config-if)#hostname X\n'
          '                  ^\n$_invalida';
      expect(
        _causa(salida),
        'IOS no entiende "hostname" en el modo de subconfiguración '
        '(Switch(config-if)#).',
      );
      expect(_solucion(salida).last, 'Si es un comando global, sal con exit.');
    });
  });

  group('orden y repetición', () {
    test('un mensaje repetido se diagnostica una sola vez', () {
      expect(
        diagnosticarConsola('Request timed out.\nRequest timed out.'),
        hasLength(1),
      );
    });

    test('el mismo tipo en interfaces distintas son dos diagnósticos', () {
      final d = diagnosticarConsola(
        '%LINK-3-UPDOWN: Interface Fa0/1, changed state to down\n'
        '%LINK-3-UPDOWN: Interface Fa0/2, changed state to down',
      );
      expect(d.map((x) => x.titulo), ['Enlace caído', 'Enlace caído']);
      expect(d.last.causa, startsWith('Fa0/2 '));
    });

    test('texto vacío no tiene diagnósticos', () {
      expect(diagnosticarConsola(''), isEmpty);
    });
  });
}
