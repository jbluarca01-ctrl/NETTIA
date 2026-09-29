// Pasos de aceptación de t06_menu_disenador.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:nettia/src/shell/nettia_shell.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'comun.dart';

class _IaFalsa implements AiDiagnosisService {
  @override
  void cancelarStream() {}

  @override
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'General',
  }) => const Stream<String>.empty();
}

/// El fondo tiene una animación infinita: se avanza por cuadros.
Future<void> _avanzar() async {
  for (var i = 0; i < 8; i++) {
    await probador.pump(const Duration(milliseconds: 60));
  }
}

final _pasos = StepRegistry<void>.fromMap({
  'Nettia abierta con el perfil "{p}"'.mapper(): (_, ctx) async {
    SharedPreferences.setMockInitialValues({
      'nettia_user_profile': ctx.arg<String>(0),
    });
    await UserProfileService.instance.load();
    probador.view.physicalSize = const Size(1200, 2400);
    probador.view.devicePixelRatio = 1;
    addTearDown(probador.view.reset);
    await probador.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: NettiaShell(aiService: _IaFalsa()),
      ),
    );
    await _avanzar();
  },
  'abro el módulo "{m}" del menú'.mapper(): (_, ctx) async {
    await probador.tap(find.byTooltip('Menú'));
    await _avanzar();
    await probador.tap(find.text(ctx.arg<String>(0)));
    await _avanzar();
  },
  'la barra superior dice "{t}"'.mapper(): (_, ctx) async {
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(ctx.arg<String>(0)),
      ),
      findsOneWidget,
    );
  },
  'veo la pestaña "{t}" del Diseñador'.mapper(): (_, ctx) async {
    expect(find.widgetWithText(Tab, ctx.arg<String>(0)), findsOneWidget);
  },
});

Future<void> main() async {
  await correrFeature('t06_menu_disenador.feature', _pasos);
}
