import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_comandos/src/logic/doctor_consola.dart';

const List<String> _fragmentos = [
  'Router>configure terminal',
  'Router#confgure',
  'Switch(config)#swithcport mode access',
  '       ^',
  "% Invalid input detected at '^' marker.",
  '%LINK-5-CHANGED: Interface Gi0/0, changed state to administratively down',
  '%LINK-3-UPDOWN: Interface Fa0/5, changed state to down',
  '%PM-4-ERR_DISABLE: bpduguard error detected on Gi0/2, putting Gi0/2 in err-disable state',
  '% Ambiguous command:  "sh i"',
  'Request timed out.',
  'Destination host unreachable.',
  '',
  'texto cualquiera',
];

String _clave(Diagnostico d) => '${d.titulo}|${d.causa}';

void main() {
  property('ninguna salida produce diagnósticos repetidos ni vacíos', () {
    forAll(list(constantFrom(_fragmentos), maxLength: 12), (lineas) {
      final d = diagnosticarConsola(lineas.join('\n'));
      expect(d.map(_clave).toSet(), hasLength(d.length));
      for (final x in d) {
        expect(x.titulo, isNotEmpty);
        expect(x.causa, isNotEmpty);
        expect(x.solucion, isNotEmpty);
      }
    });
  });

  property('agregar líneas al final no cambia los diagnósticos anteriores', () {
    forAll(
      combine2(
        list(constantFrom(_fragmentos), maxLength: 8),
        list(constantFrom(_fragmentos), maxLength: 8),
      ),
      (entrada) {
        final (inicio, resto) = entrada;
        final antes = diagnosticarConsola(inicio.join('\n')).map(_clave);
        final despues = diagnosticarConsola(
          [...inicio, ...resto].join('\n'),
        ).map(_clave);
        expect(despues.take(antes.length), antes);
      },
    );
  });

  property('cualquier texto se procesa sin errores', () {
    forAll(string(maxLength: 200), (texto) {
      expect(() => diagnosticarConsola(texto), returnsNormally);
    });
  });
}
