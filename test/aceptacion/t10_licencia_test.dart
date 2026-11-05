// Pasos de aceptación de t10_licencia.feature.
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

/// Semillas de prueba: la de "Nettia" y una ajena. Nunca son las de venta.
final _semillaNettia = List<int>.generate(32, (i) => i);
final _semillaAjena = List<int>.generate(32, (i) => 255 - i);

late String _androidId;
late String _texto;
ResultadoLicencia? _resultado;

Future<String> _firmar(
  List<int> semilla,
  String androidId,
  String nombre,
) async {
  final par = await Ed25519().newKeyPairFromSeed(semilla);
  final firma = await Ed25519().sign(
    mensajeLicencia(codigoTelefono(androidId), nombre),
    keyPair: par,
  );
  return armarLicencia(nombre, firma.bytes);
}

Future<List<int>> _clavePublicaNettia() async {
  final par = await Ed25519().newKeyPairFromSeed(_semillaNettia);
  return (await par.extractPublicKey()).bytes;
}

final _pasos = StepRegistry<void>.fromMap({
  'un teléfono con ANDROID_ID "{id}"'.mapper(): (_, ctx) async {
    _androidId = ctx.arg<String>(0);
    _resultado = null;
  },
  'su código de teléfono es "{c}"'.mapper(): (_, ctx) async {
    expect(codigoTelefono(_androidId), ctx.arg<String>(0));
  },
  'una licencia firmada para ese teléfono a nombre de "{n}"'.mapper(): (
    _,
    ctx,
  ) async {
    _texto =
        await probador.runAsync(
              () => _firmar(_semillaNettia, _androidId, ctx.arg<String>(0)),
            )
            as String;
  },
  'una licencia firmada para el ANDROID_ID "{id}" a nombre de "{n}"'.mapper(): (
    _,
    ctx,
  ) async {
    _texto =
        await probador.runAsync(
              () => _firmar(
                _semillaNettia,
                ctx.arg<String>(0),
                ctx.arg<String>(1),
              ),
            )
            as String;
  },
  'una licencia firmada con otra clave para ese teléfono a nombre de "{n}"'
      .mapper(): (_, ctx) async {
    _texto =
        await probador.runAsync(
              () => _firmar(_semillaAjena, _androidId, ctx.arg<String>(0)),
            )
            as String;
  },
  'la pegaron entre comillas y partida en dos líneas'.mapper(): (_, ctx) async {
    final mitad = _texto.length ~/ 2;
    _texto = ' "${_texto.substring(0, mitad)}\n  ${_texto.substring(mitad)}" ';
  },
  'le cambiaron el nombre a "{n}"'.mapper(): (_, ctx) async {
    final partes = _texto.split('.');
    final firma = decodificarBase64Url(partes[2]);
    _texto = armarLicencia(ctx.arg<String>(0), firma);
  },
  'el texto pegado "{t}"'.mapper(): (_, ctx) async {
    _texto = ctx.arg<String>(0);
  },
  'la reviso'.mapper(): (_, ctx) async {
    _resultado = await probador.runAsync(
      () async => verificarLicencia(
        _texto,
        androidId: _androidId,
        clavePublica: await _clavePublicaNettia(),
      ),
    );
  },
  'la licencia es válida a nombre de "{n}"'.mapper(): (_, ctx) async {
    expect(_resultado, LicenciaValida(ctx.arg<String>(0)));
  },
  'la licencia se rechaza por "{m}"'.mapper(): (_, ctx) async {
    expect(
      _resultado,
      LicenciaInvalida(MotivoRechazo.values.byName(ctx.arg<String>(0))),
    );
  },
});

void main() => correrFeature('t10_licencia.feature', _pasos);
