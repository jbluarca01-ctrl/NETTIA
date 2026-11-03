import 'package:flutter_test/flutter_test.dart';
import 'package:module_calculadora/src/logic/conversiones.dart';
import 'package:module_calculadora/src/logic/resumen_cidr.dart';

const _cuatro = <String>[
  '192.168.0.0/24',
  '192.168.1.0/24',
  '192.168.2.0/24',
  '192.168.3.0/24',
];

const _vlsm = <String>[
  '192.168.10.0/26',
  '192.168.10.64/27',
  '192.168.10.96/28',
  '192.168.10.112/29',
];

void main() {
  group('rangoDeRed e IP en texto', () {
    test('primera y última dirección de una red', () {
      final (ini, fin) = rangoDeRed(' 192.168.10.64/27 ');
      expect(ipATexto(ini), '192.168.10.64');
      expect(ipATexto(fin), '192.168.10.95');
      expect(ipDesdeTexto('10.0.0.1'), 167772161);
      expect(ipDesdeTexto('10.0.0'), isNull);
    });

    test('prefijos extremos /0 y /32', () {
      expect(rangoDeRed('0.0.0.0/0'), (0, 4294967295));
      expect(rangoDeRed('10.0.0.1/32'), (167772161, 167772161));
    });

    test('mensaje de red inválida', () {
      expect(
        () => rangoDeRed(' hola '),
        throwsA(predicate((e) => '$e' == 'Red inválida: "hola" (usa a.b.c.d/n).')),
      );
    });

    test('rechaza lo que no es una red', () {
      for (final malo in <String>[
        'hola',
        '10.0.0.0',
        '10.0.0.0/33',
        '10.0.0.0/-1',
        '10.0.0.0/x',
        '10.0.0.0/24/1',
        '10.0.0/24',
      ]) {
        expect(() => rangoDeRed(malo), throwsA(isA<ConversionException>()),
            reason: malo);
      }
      expect(
        () => rangoDeRed('10.0.0.5/24'),
        throwsA(predicate((e) =>
            '$e' == '"10.0.0.5/24" no es una dirección de red (¿quisiste 10.0.0.0/24?).')),
      );
    });
  });

  group('revisarResumen', () {
    test('cuatro /24 contiguas y alineadas: válido y exacto', () {
      final r = revisarResumen(_cuatro);
      expect(r.resumen.red, '192.168.0.0');
      expect(r.resumen.prefijo, 22);
      expect(r.cubierto, '192.168.0.0 – 192.168.3.255');
      expect(r.faltantes, isEmpty);
      expect(r.sobrantes, isEmpty);
      expect(r.veredicto, Veredicto.valido);
      expect(r.textoVeredicto, 'Válido: cubre exactamente las redes dadas.');
      expect(r.preguntas, <String>[
        '1. Mismo salto: compruebe que todas van al mismo router (siguiente salto).',
        '2. Contiguas: sí, no falta ningún bloque entre ellas.',
        '3. Potencia de dos: sí, suman 1024 direcciones.',
        '4. Alineadas: sí, empiezan en 192.168.0.0, inicio del bloque /22.',
        '5. Rango cubierto: 192.168.0.0 – 192.168.3.255 (1024 direcciones).',
      ]);
    });

    test('las subredes VLSM del parcial: /25 con .120/29 libre', () {
      final r = revisarResumen(_vlsm);
      expect(r.resumen.prefijo, 25);
      expect(r.cubierto, '192.168.10.0 – 192.168.10.127');
      expect(r.veredicto, Veredicto.condicional);
      expect(r.sobrantes, <String>['192.168.10.120/29']);
      expect(
        r.textoVeredicto,
        'Válido solo si estas direcciones también van a ese router o están '
        'libres: 192.168.10.120/29.',
      );
      expect(r.preguntas[2], '3. Potencia de dos: no, suman 120 direcciones.');
    });

    test('falta una red intermedia: no válido', () {
      final r = revisarResumen(<String>['192.168.2.0/24', '192.168.0.0/24']);
      expect(r.veredicto, Veredicto.noValido);
      expect(r.faltantes, <String>['192.168.1.0/24']);
      expect(
        r.textoVeredicto,
        'No válido: falta 192.168.1.0/24 entre las redes; el resumen le '
        'enviaría ese tráfico al mismo salto.',
      );
      expect(r.preguntas[1], '2. Contiguas: no, falta 192.168.1.0/24.');
    });

    test('contiguas sin alinear: sobran bloques a ambos lados', () {
      final r = revisarResumen(<String>['192.168.1.0/24', '192.168.2.0/24']);
      expect(r.resumen.prefijo, 22);
      expect(r.veredicto, Veredicto.condicional);
      expect(r.sobrantes, <String>['192.168.0.0/24', '192.168.3.0/24']);
      expect(
        r.preguntas[3],
        '4. Alineadas: no, empiezan en 192.168.1.0 pero el bloque /22 empieza '
        'en 192.168.0.0.',
      );
    });

    test('huecos y sobrantes que no son un bloque se muestran como rango', () {
      final hueco = revisarResumen(<String>['10.0.0.0/24', '10.0.3.0/24']);
      expect(hueco.faltantes, <String>['10.0.1.0 – 10.0.2.255']);
      final sobra = revisarResumen(
          <String>['192.168.10.0/26', '192.168.10.64/27', '192.168.10.96/29']);
      expect(sobra.sobrantes, <String>['192.168.10.104 – 192.168.10.127']);
    });

    test('varios huecos se listan todos', () {
      final r = revisarResumen(
          <String>['10.0.0.0/24', '10.0.2.0/24', '10.0.4.0/24', '10.0.6.0/24']);
      expect(r.faltantes, <String>['10.0.1.0/24', '10.0.3.0/24', '10.0.5.0/24']);
      expect(r.sobrantes, <String>['10.0.7.0/24']);
      expect(r.veredicto, Veredicto.noValido);
      expect(
        r.textoVeredicto,
        'No válido: falta 10.0.1.0/24, 10.0.3.0/24, 10.0.5.0/24 entre las '
        'redes; el resumen le enviaría ese tráfico al mismo salto.',
      );
      expect(r.preguntas[1],
          '2. Contiguas: no, falta 10.0.1.0/24, 10.0.3.0/24, 10.0.5.0/24.');
    });

    test('varios sobrantes van separados por coma', () {
      final r = revisarResumen(<String>['10.0.1.0/24', '10.0.2.0/24']);
      expect(
        r.textoVeredicto,
        'Válido solo si estas direcciones también van a ese router o están '
        'libres: 10.0.0.0/24, 10.0.3.0/24.',
      );
    });

    test('un hueco de una sola dirección es un /32', () {
      final r = revisarResumen(<String>['10.0.0.0/32', '10.0.0.2/31']);
      expect(r.faltantes, <String>['10.0.0.1/32']);
      expect(r.cubierto, '10.0.0.0 – 10.0.0.3');
    });

    test('mismo inicio: la red grande contiene a la chica', () {
      for (final redes in <List<String>>[
        <String>['10.0.0.0/24', '10.0.0.0/23'],
        <String>['10.0.0.0/23', '10.0.0.0/24'],
      ]) {
        final r = revisarResumen(redes);
        expect(r.veredicto, Veredicto.valido, reason: '$redes');
        expect(r.preguntas.last, 'Aviso: algunas redes se solapan entre sí.');
      }
    });

    test('redes solapadas: avisa, y el veredicto mira lo que cubren juntas', () {
      final r = revisarResumen(<String>['10.0.0.0/23', '10.0.1.0/24']);
      expect(r.veredicto, Veredicto.valido);
      expect(r.preguntas.last, 'Aviso: algunas redes se solapan entre sí.');
      expect(r.preguntas, hasLength(6));
      // Una /32 que es la última dirección de la red anterior también solapa.
      final borde = revisarResumen(<String>['10.0.0.0/31', '10.0.0.1/32']);
      expect(borde.preguntas.last, 'Aviso: algunas redes se solapan entre sí.');
      expect(borde.veredicto, Veredicto.valido);
      expect(borde.resumen.exacta, isFalse);
      expect(borde.resumen.direccionesSobrantes, 0);
      final tocan = revisarResumen(<String>['10.0.0.0/24', '10.0.1.0/24']);
      expect(tocan.preguntas, hasLength(5));
    });

    test('valida las entradas igual que sumarizarRedes', () {
      expect(() => revisarResumen(<String>['10.0.0.0/24']),
          throwsA(isA<ConversionException>()));
      expect(() => revisarResumen(<String>['10.0.0.5/24', '10.0.1.0/24']),
          throwsA(isA<ConversionException>()));
    });
  });

  group('sumarizarRedes: pasos', () {
    test('resumen exacto', () {
      expect(sumarizarRedes(_cuatro).pasos, <String>[
        '1. Rango que cubren las redes: 192.168.0.0 a 192.168.3.255.',
        '2. Se busca el prefijo más largo en el que la primera y la última '
            'dirección comparten la red: /22.',
        '3. La ruta resumen es 192.168.0.0/22 (máscara 255.255.252.0), que '
            'abarca 1024 direcciones.',
        '4. Las redes suman exactamente 1024 direcciones: el resumen es exacto.',
      ]);
    });

    test('sobran direcciones', () {
      final r = sumarizarRedes(<String>['10.0.2.0/24', '10.0.0.0/24']);
      expect(r.red, '10.0.0.0');
      expect(r.prefijo, 22);
      expect(r.direccionesSobrantes, 512);
      expect(r.pasos.first, '1. Rango que cubren las redes: 10.0.0.0 a 10.0.2.255.');
      expect(
        r.pasos.last,
        '4. Las redes suman 512 y el resumen abarca 1024: sobran 512 '
        'direcciones que no pertenecen a ninguna de ellas.',
      );
    });

    test('redes solapadas', () {
      final r = sumarizarRedes(<String>['10.0.0.0/23', '10.0.1.0/24']);
      expect(r.direccionesSobrantes, 0);
      expect(r.pasos.last, '4. Aviso: algunas redes se solapan entre sí.');
    });

    test('la red más grande puede venir primero', () {
      final r = sumarizarRedes(<String>['10.0.0.0/16', '10.0.4.0/24']);
      expect(r.prefijo, 16);
      expect(r.pasos.first, '1. Rango que cubren las redes: 10.0.0.0 a 10.0.255.255.');
    });

    test('con una sola red pide al menos 2', () {
      expect(
        () => sumarizarRedes(<String>['10.0.0.0/24']),
        throwsA(predicate((e) => '$e' == 'Escribe al menos 2 redes para sumarizar.')),
      );
    });

    test('dos /1 se resumen en /0', () {
      final r = sumarizarRedes(<String>['0.0.0.0/1', '128.0.0.0/1']);
      expect(r.prefijo, 0);
      expect(r.exacta, isTrue);
    });
  });

  group('comandoResumen', () {
    final r = revisarResumen(_vlsm).resumen;

    test('con siguiente salto', () {
      expect(comandoResumen(r, ' 10.0.0.2 '),
          'ip route 192.168.10.0 255.255.255.128 10.0.0.2');
    });

    test('sin siguiente salto deja el marcador', () {
      expect(comandoResumen(r, '  '),
          'ip route 192.168.10.0 255.255.255.128 [siguiente salto]');
    });

    test('siguiente salto inválido', () {
      expect(
        () => comandoResumen(r, '10.0.0.300'),
        throwsA(predicate(
            (e) => '$e' == 'Siguiente salto inválido: 10.0.0.300 (usa a.b.c.d).')),
      );
    });
  });
}
