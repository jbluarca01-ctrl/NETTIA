// Pasos de aceptación de t07_android.feature.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:nettia/main.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'comun.dart';

String _texto = '';

String _leer(String ruta) => File(ruta).readAsStringSync();

/// Bloque `<etiqueta>…</etiqueta>` de un XML sencillo.
String _bloque(String xml, String etiqueta) {
  final inicio = xml.indexOf('<$etiqueta>');
  final fin = xml.indexOf('</$etiqueta>');
  expect(inicio, greaterThanOrEqualTo(0), reason: 'falta <$etiqueta>');
  return xml.substring(inicio, fin);
}

const _dominios = ['root', 'file', 'database', 'sharedpref', 'external'];

final _pasos = StepRegistry<void>.fromMap({
  'el manifiesto de Android'.mapper(): (_, ctx) async {
    _texto = _leer('android/app/src/main/AndroidManifest.xml');
  },
  'el respaldo automático está desactivado'.mapper(): (_, ctx) async {
    expect(_texto, contains('android:allowBackup="false"'));
  },
  'las reglas de extracción excluyen todos los datos del respaldo en la nube y de la transferencia entre dispositivos'
      .mapper(): (_, ctx) async {
    expect(
      _texto,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    final reglas = _leer(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    );
    for (final seccion in ['cloud-backup', 'device-transfer']) {
      final bloque = _bloque(reglas, seccion);
      for (final d in _dominios) {
        expect(bloque, contains('<exclude domain="$d" path="."/>'));
      }
    }
  },
  'la configuración de compilación de Android'.mapper(): (_, ctx) async {
    _texto = _leer('android/app/build.gradle.kts');
  },
  'la versión release se firma con la clave indicada en "{f}"'.mapper(): (
    _,
    ctx,
  ) async {
    expect(_texto, contains('rootProject.file("${ctx.arg<String>(0)}")'));
    expect(_texto, contains('create("release")'));
    expect(_texto, contains('signingConfigs.getByName("release")'));
    expect(_texto, isNot(contains('TODO: Add your own signing config')));
  },
  'las contraseñas pueden venir de variables de entorno en lugar del archivo'
      .mapper(): (_, ctx) async {
    expect(_texto, contains('System.getenv("NETTIA_STORE_PASSWORD")'));
    expect(_texto, contains('System.getenv("NETTIA_KEY_PASSWORD")'));
  },
  '"{f}" y los archivos de clave no se suben al repositorio'.mapper(): (
    _,
    ctx,
  ) async {
    final ignorados = _leer(
      'android/.gitignore',
    ).split('\n').map((l) => l.trim());
    expect(ignorados, contains(ctx.arg<String>(0)));
    expect(ignorados, containsAll(['**/*.keystore', '**/*.jks']));
  },
  'la app arrancada con un perfil guardado'.mapper(): (_, ctx) async {
    SharedPreferences.setMockInitialValues({
      'nettia_user_profile': 'estudiante',
    });
    await UserProfileService.instance.load();
    await probador.pumpWidget(const NettiaApp());
    await probador.pump();
  },
  'el botón de cancelar del sistema dice "{t}"'.mapper(): (_, ctx) async {
    final contexto = probador.element(find.byType(Scaffold).first);
    expect(
      MaterialLocalizations.of(contexto).cancelButtonLabel,
      ctx.arg<String>(0),
    );
    // Deja terminar el splash para no dejar temporizadores pendientes.
    for (var t = 0; t < 4000; t += 100) {
      await probador.pump(const Duration(milliseconds: 100));
    }
  },
});

Future<void> main() async {
  await correrFeature('t07_android.feature', _pasos);
}
