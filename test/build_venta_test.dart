import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Corre el script en una copia aislada del proyecto: [config] es el
/// contenido de lib/src/licencia_config.dart y [conKeystore] crea
/// android/key.properties. Así el test no depende de lo que tenga hoy la
/// configuración real (desde el 2026-11-06 ya trae la clave y la huella).
Future<ProcessResult> _verificar(String config, {bool conKeystore = false}) async {
  final raiz = Directory.systemTemp.createTempSync('nettia_venta_');
  addTearDown(() => raiz.deleteSync(recursive: true));
  Directory('${raiz.path}/scripts').createSync();
  File('scripts/build_venta.ps1').copySync('${raiz.path}/scripts/build_venta.ps1');
  File('${raiz.path}/lib/src/licencia_config.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(config);
  if (conKeystore) {
    File('${raiz.path}/android/key.properties')
      ..createSync(recursive: true)
      ..writeAsStringSync('storeFile=x');
  }
  return Process.run(
    Platform.isWindows ? 'powershell' : 'pwsh',
    [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      '${raiz.path}/scripts/build_venta.ps1',
      '-SoloVerificar',
    ],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}

const _sinClave =
    "List<int> get clavePublicaVenta => _bytes('');\nString get huellaVenta => 'AA:BB';\n";
const _sinHuella =
    "List<int> get clavePublicaVenta => _bytes('0102');\nString get huellaVenta => '';\n";
const _completa =
    "List<int> get clavePublicaVenta => _bytes('0102');\nString get huellaVenta => 'AA:BB';\n";

/// SPEC-005 RF19: el build de venta no se hace sin clave, huella ni keystore.
void main() {
  test('sin clave de venta el script se niega y lo dice', () async {
    final r = await _verificar(_sinClave, conKeystore: true);
    expect(r.exitCode, 1);
    expect('${r.stdout}${r.stderr}', contains('Falta la clave pública de venta'));
  });

  test('sin huella del certificado el script se niega y lo dice', () async {
    final r = await _verificar(_sinHuella, conKeystore: true);
    expect(r.exitCode, 1);
    expect('${r.stdout}${r.stderr}', contains('Falta la huella SHA-256'));
  });

  test('sin android/key.properties el script se niega y lo dice', () async {
    final r = await _verificar(_completa);
    expect(r.exitCode, 1);
    expect('${r.stdout}${r.stderr}', contains('Falta android/key.properties'));
  });

  test('con clave, huella y keystore queda listo', () async {
    final r = await _verificar(_completa, conKeystore: true);
    expect(r.exitCode, 0);
    expect('${r.stdout}${r.stderr}', contains('Listo para el build de venta.'));
  });

  test('el script compila ofuscado y guarda símbolos fuera del repo', () {
    final s = File('scripts/build_venta.ps1').readAsStringSync();
    expect(s, contains('--obfuscate'));
    expect(s, contains(r'--split-debug-info=$simbolos'));
    expect(s, contains(r'$env:USERPROFILE'));
    expect(s, contains('android/key.properties'));
    expect(s, contains("huellaVenta => '';"));
  });
}
