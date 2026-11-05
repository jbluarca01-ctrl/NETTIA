import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SPEC-005 RF19: el build de venta no se hace sin clave, huella ni keystore.
void main() {
  test('sin clave de venta el script se niega y lo dice', () async {
    final r = await Process.run(
      Platform.isWindows ? 'powershell' : 'pwsh',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        'scripts/build_venta.ps1',
        '-SoloVerificar',
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    expect(r.exitCode, 1);
    expect(
      '${r.stdout}${r.stderr}',
      contains('Falta la clave pública de venta'),
    );
  });

  test('el script compila ofuscado y guarda símbolos fuera del repo', () {
    final s = File('scripts/build_venta.ps1').readAsStringSync();
    expect(s, contains('--obfuscate'));
    expect(s, contains(r'--split-debug-info=$simbolos'));
    expect(s, contains(r'$env:USERPROFILE'));
    expect(s, contains('android/key.properties'));
    expect(s, contains("huellaVenta = ''"));
  });
}
