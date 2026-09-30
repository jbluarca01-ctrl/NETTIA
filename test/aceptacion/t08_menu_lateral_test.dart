// Pasos de aceptación de t08_menu_lateral.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:nettia/src/widgets/network_drawer.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

class _Mundo {
  final andamio = GlobalKey<ScaffoldState>();
  NettiaModulo? elegido;
  var ajustes = 0;
}

late _Mundo _mundo;

final _titulos = <String, NettiaModulo>{
  for (final m in NettiaModulo.values) _tituloDe(m): m,
};

String _tituloDe(NettiaModulo m) => switch (m) {
  NettiaModulo.calculadora => 'Calculadora de Subredes',
  NettiaModulo.comandos => 'Comandos CLI & Plantillas',
  NettiaModulo.asistente => 'Asistente NETIA',
  NettiaModulo.guia => 'Guía Metodológica',
  NettiaModulo.disenador => 'Diseñador de Red',
};

Future<void> _abrir(NettiaModulo actual) async {
  _mundo = _Mundo();
  probador.view.physicalSize = const Size(1200, 2400);
  probador.view.devicePixelRatio = 1;
  addTearDown(probador.view.reset);
  await probador.pumpWidget(
    MaterialApp(
      theme: NetworkTheme.darkTheme,
      home: Scaffold(
        key: _mundo.andamio,
        drawer: NetworkDrawer(
          profile: UserProfile.estudiante,
          current: actual,
          onSelectModule: (m) => _mundo.elegido = m,
          onOpenSettings: () => _mundo.ajustes++,
        ),
      ),
    ),
  );
  _mundo.andamio.currentState!.openDrawer();
  await probador.pumpAndSettle();
}

FontWeight? _pesoDe(String titulo) =>
    probador.widget<Text>(find.text(titulo)).style?.fontWeight;

final _pasos = StepRegistry<void>.fromMap({
  'el menú lateral abierto con el módulo actual "{m}"'.mapper(): (
    _,
    ctx,
  ) async {
    await _abrir(_titulos[ctx.arg<String>(0)]!);
  },
  'el menú muestra las entradas'.mapper(): (_, ctx) async {
    for (final fila in ctx.tableRows) {
      expect(find.text(fila['titulo']!), findsOneWidget);
      expect(find.text(fila['subtitulo']!), findsOneWidget);
    }
  },
  'el menú muestra los rótulos "{a}" y "{b}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsOneWidget);
    expect(find.text(ctx.arg<String>(1)), findsOneWidget);
  },
  'el pie del menú dice "{v}" y "{n}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsOneWidget);
    // "Nettia" aparece en la cabecera y en el pie.
    expect(find.text(ctx.arg<String>(1)), findsNWidgets(2));
  },
  'solo "{m}" aparece seleccionado'.mapper(): (_, ctx) async {
    final seleccionado = ctx.arg<String>(0);
    for (final t in [
      ..._titulos.keys,
      'Configuración & IA',
      'Acerca de Nettia',
    ]) {
      final esperado = t == seleccionado ? FontWeight.bold : FontWeight.w600;
      expect(_pesoDe(t), esperado, reason: t);
    }
  },
  'toco "{t}" en el menú'.mapper(): (_, ctx) async {
    await probador.tap(find.text(ctx.arg<String>(0)));
    await probador.pumpAndSettle();
  },
  'el menú se cerró'.mapper(): (_, ctx) async {
    expect(_mundo.andamio.currentState!.isDrawerOpen, isFalse);
  },
  'se eligió el módulo "{m}"'.mapper(): (_, ctx) async {
    expect(_mundo.elegido?.name, ctx.arg<String>(0));
    expect(_mundo.ajustes, 0);
  },
  'se abrieron los ajustes'.mapper(): (_, ctx) async {
    expect(_mundo.ajustes, 1);
    expect(_mundo.elegido, isNull);
  },
  'veo el diálogo con el botón "{b}"'.mapper(): (_, ctx) async {
    expect(
      find.widgetWithText(FilledButton, ctx.arg<String>(0)),
      findsOneWidget,
    );
    expect(_mundo.elegido, isNull);
    expect(_mundo.ajustes, 0);
  },
});

Future<void> main() async {
  await correrFeature('t08_menu_lateral.feature', _pasos);
}
