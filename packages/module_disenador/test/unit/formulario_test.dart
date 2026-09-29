import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/formulario.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

Matcher _error(String mensaje) => throwsA(
  isA<DisenoException>().having((e) => e.mensaje, 'mensaje', mensaje),
);

void main() {
  group('leerRedBase', () {
    test('separa la red y el prefijo, sin espacios', () {
      expect(leerRedBase(' 10.0.0.0 / 16 '), ('10.0.0.0', 16));
    });

    test('sin prefijo o con prefijo inválido explica cómo escribirla', () {
      const msg = 'Escribe la red base con su prefijo, p. ej. 192.168.10.0/24.';
      expect(() => leerRedBase('10.0.0.0'), _error(msg));
      expect(() => leerRedBase('10.0.0.0/x'), _error(msg));
      expect(() => leerRedBase('10.0.0.0/24/1'), _error(msg));
    });
  });

  group('leerSegmentos', () {
    test('ignora las filas vacías y quita espacios', () {
      final s = leerSegmentos(const [(' A ', ' 5 '), (' ', '')]);
      expect(s.single.nombre, 'A');
      expect(s.single.hosts, 5);
    });

    test('una fila con solo el nombre pide los hosts como número', () {
      expect(
        () => leerSegmentos(const [('LAB', ''), ('X', '1')]),
        _error('"LAB": escribe los hosts como un número.'),
      );
    });

    test(
      'una fila con solo los hosts se conserva (el plan pide el nombre)',
      () {
        expect(leerSegmentos(const [('', '3')]).single.hosts, 3);
      },
    );
  });

  group('leerEntero', () {
    test('vacío o con espacios vale 0', () {
      expect(leerEntero('  ', 'x'), 0);
    });

    test('lee el número sin espacios', () {
      expect(leerEntero(' 7 ', 'x'), 7);
    });

    test('texto no numérico nombra el campo', () {
      expect(
        () => leerEntero('mucho', 'crecimiento'),
        _error('El campo "crecimiento" debe ser un número.'),
      );
    });
  });

  group('disenar', () {
    test('arma plan, configuración y verificación con las opciones', () {
      final d = disenar(
        const EntradaDiseno(
          redBase: '10.0.0.0/24',
          segmentos: [('A', '10')],
          reservadas: '2',
          crecimiento: '50',
          gatewayAlFinal: true,
          topologia: Topologia.switchCapa3,
          dns: ' 8.8.8.8 ',
          dominio: ' lab.local ',
          clave: ' Cl4ve ',
        ),
      );
      final a = d.plan.segmentos.single;
      expect(d.plan.opciones.reservadas, 2);
      expect(d.plan.opciones.crecimientoPct, 50);
      expect(a.gateway, '10.0.0.30');
      expect(d.equipos.single.lineas, contains('enable secret Cl4ve'));
      expect(d.equipos.single.lineas, contains(' dns-server 8.8.8.8'));
      expect(d.equipos.single.lineas, contains(' domain-name lab.local'));
      expect(d.verificacion.first.equipo, 'SW1');
    });

    test('los errores de la red base llegan como DisenoException', () {
      expect(
        () => disenar(
          const EntradaDiseno(redBase: '300.0.0.0/24', segmentos: [('A', '1')]),
        ),
        throwsA(isA<DisenoException>()),
      );
    });
  });
}
