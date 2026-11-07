// Pasos de aceptación de t11_activacion.feature.
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:nettia/main.dart';
import 'package:nettia/src/widgets/acerca_de_dialogo.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../licencia_prueba.dart';
import 'comun.dart';

const _seleccionPerfil = '¿Cómo vas a usar Nettia?';
late Map<String, Object> _prefs;
String? _portapapeles;

Future<String> _licencia(String androidId, String nombre) async {
  final par = await Ed25519().newKeyPairFromSeed(
    List<int>.generate(32, (i) => i),
  );
  final firma = await Ed25519().sign(
    mensajeLicencia(codigoTelefono(androidId), nombre),
    keyPair: par,
  );
  return armarLicencia(nombre, firma.bytes);
}

Future<String> _firmar(String androidId, String nombre) async =>
    await probador.runAsync(() => _licencia(androidId, nombre)) as String;

/// Deja correr la verificación (asíncrona) y redibuja.
Future<void> _esperar({int cuadros = 2}) async {
  await probador.runAsync(() => Future<void>.delayed(Duration.zero));
  for (var i = 0; i < cuadros; i++) {
    await probador.pump(const Duration(milliseconds: 100));
  }
}

Future<String?> _guardada() async => (await SharedPreferences.getInstance())
    .getString(GuardianLicencia.claveGuardada);

Future<void> _abrir() async {
  SharedPreferences.setMockInitialValues(_prefs);
  await UserProfileService.instance.load();
  probador.view.physicalSize = const Size(1200, 2400);
  probador.view.devicePixelRatio = 1;
  addTearDown(probador.view.reset);
  probador.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (c) async {
      if (c.method == 'Clipboard.setData') {
        _portapapeles = (c.arguments as Map)['text'] as String;
      }
      return null;
    },
  );
  await probador.pumpWidget(const NettiaApp());
  await _esperar();
}

final _pasos = StepRegistry<void>.fromMap({
  'un teléfono con ANDROID_ID "{id}" sin licencia guardada'.mapper(): (
    _,
    ctx,
  ) async {
    usarTelefonoDePrueba(androidId: ctx.arg<String>(0));
    _prefs = {};
  },
  'un teléfono con ANDROID_ID "{id}" con licencia guardada a nombre de "{n}"'
      .mapper(): (_, ctx) async {
    final id = ctx.arg<String>(0);
    usarTelefonoDePrueba(androidId: id);
    _prefs = {
      GuardianLicencia.claveGuardada: await _firmar(id, ctx.arg<String>(1)),
    };
  },
  'un teléfono con ANDROID_ID "{id}" con licencia guardada del ANDROID_ID "{o}"'
      .mapper(): (_, ctx) async {
    usarTelefonoDePrueba(androidId: ctx.arg<String>(0));
    _prefs = {
      GuardianLicencia.claveGuardada: await _firmar(ctx.arg<String>(1), 'X'),
    };
  },
  'un teléfono que no entrega sus datos'.mapper(): (_, ctx) async {
    usarTelefonoDePrueba(conDatos: false);
    _prefs = {};
  },
  'el APK está firmado con la huella "{h}" y se exige "{e}"'.mapper(): (
    _,
    ctx,
  ) async {
    final guardada = _prefs;
    usarTelefonoDePrueba(
      huellaApk: ctx.arg<String>(0),
      huellaExigida: ctx.arg<String>(1),
    );
    _prefs = guardada;
  },
  'el perfil "{p}" ya elegido'.mapper(): (_, ctx) async {
    _prefs = {..._prefs, 'nettia_user_profile': ctx.arg<String>(0)};
  },
  'abro Nettia'.mapper(): (_, ctx) async => _abrir(),
  'abro Nettia y llego al menú'.mapper(): (_, ctx) async {
    await _abrir();
    await _esperar(cuadros: 45); // splash
    expect(find.byTooltip('Menú'), findsOneWidget);
  },
  'la licencia guardada se reemplaza por una de otro teléfono'.mapper(): (
    _,
    ctx,
  ) async {
    final otra = await _firmar('0123456789abcdef', 'Ana Pérez');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GuardianLicencia.claveGuardada, otra);
  },
  'abro el módulo "{m}" del menú'.mapper(): (_, ctx) async {
    await probador.tap(find.byTooltip('Menú'));
    await _esperar(cuadros: 8);
    await probador.tap(find.text(ctx.arg<String>(0)));
    await _esperar(cuadros: 8);
  },
  'toco "{b}"'.mapper(): (_, ctx) async {
    await probador.tap(find.text(ctx.arg<String>(0)));
    await _esperar();
  },
  'pego la licencia firmada para este teléfono a nombre de "{n}"'.mapper(): (
    _,
    ctx,
  ) async {
    final lic = await _firmar(androidIdPrueba, ctx.arg<String>(0));
    await probador.enterText(find.byType(TextField), lic);
  },
  'pego la licencia firmada para el ANDROID_ID "{id}" a nombre de "{n}"'
      .mapper(): (_, ctx) async {
    final lic = await _firmar(ctx.arg<String>(0), ctx.arg<String>(1));
    await probador.enterText(find.byType(TextField), lic);
  },
  'veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsOneWidget);
  },
  'veo el código del teléfono "{c}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsOneWidget);
  },
  'el portapapeles tiene "{c}"'.mapper(): (_, ctx) async {
    expect(_portapapeles, ctx.arg<String>(0));
  },
  'veo la selección de perfil'.mapper(): (_, ctx) async {
    expect(find.text(_seleccionPerfil), findsOneWidget);
  },
  'no veo la selección de perfil'.mapper(): (_, ctx) async {
    expect(find.text(_seleccionPerfil), findsNothing);
  },
  'la licencia quedó guardada'.mapper(): (_, ctx) async {
    expect(await _guardada(), isNotNull);
  },
  'no hay licencia guardada'.mapper(): (_, ctx) async {
    expect(await _guardada(), isNull);
  },
  '"Acerca de Nettia" dice "{t}"'.mapper(): (_, ctx) async {
    await probador.pumpWidget(
      const MaterialApp(home: Scaffold(body: AcercaDeDialogo())),
    );
    expect(find.text(ctx.arg<String>(0)), findsOneWidget);
  },
});

Future<void> main() async {
  await correrFeature('t11_activacion.feature', _pasos);
}
