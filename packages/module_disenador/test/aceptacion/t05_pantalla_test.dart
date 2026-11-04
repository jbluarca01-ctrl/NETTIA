// Pasos de aceptación de t05_pantalla.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_disenador/module_disenador.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

Future<void> _tocar(Finder f) async {
  await probador.ensureVisible(f);
  await probador.tap(f);
  await probador.pumpAndSettle();
}

final _pasos = StepRegistry<void>.fromMap({
  'la pantalla del Diseñador'.mapper(): (_, ctx) async {
    probador.view.physicalSize = const Size(1200, 4000);
    probador.view.devicePixelRatio = 1;
    addTearDown(probador.view.reset);
    await probador.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        // Sin const: así se ejecuta el constructor de la pantalla.
        home: Scaffold(body: DisenadorScreen()),
      ),
    );
  },
  'abro la pestaña "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.widgetWithText(Tab, ctx.arg<String>(0)));
  },
  'toco "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.text(ctx.arg<String>(0)).last);
  },
  'elijo "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.text(ctx.arg<String>(0)));
  },
  'activo "{t}"'.mapper(): (_, ctx) async {
    await _tocar(find.text(ctx.arg<String>(0)));
  },
  'escribo "{v}" en "{campo}"'.mapper(): (_, ctx) async {
    await probador.enterText(
      find.widgetWithText(TextField, ctx.arg<String>(1)),
      ctx.arg<String>(0),
    );
  },
  'escribo "{v}" en el nombre del segmento {n}'.mapper(types: {'n': int}): (
    _,
    ctx,
  ) async {
    await probador.enterText(
      find.byKey(ValueKey('segmento_nombre_${ctx.arg<int>(1)}')),
      ctx.arg<String>(0),
    );
  },
  'escribo "{v}" en los hosts del segmento {n}'.mapper(types: {'n': int}): (
    _,
    ctx,
  ) async {
    await probador.enterText(
      find.byKey(ValueKey('segmento_hosts_${ctx.arg<int>(1)}')),
      ctx.arg<String>(0),
    );
  },
  'escribo "{v}" en las PC del segmento {n} en SW{s}'.mapper(
    types: {'n': int, 's': int},
  ): (_, ctx) async {
    await probador.enterText(
      find.byKey(
        ValueKey('segmento_hosts_${ctx.arg<int>(1)}_sw${ctx.arg<int>(2)}'),
      ),
      ctx.arg<String>(0),
    );
  },
  'quito el segmento {n}'.mapper(types: {'n': int}): (_, ctx) async {
    await _tocar(find.byTooltip('Quitar segmento ${ctx.arg<int>(0)}'));
  },
  'pego la running-config:'.mapper(): (_, ctx) async {
    await probador.enterText(
      find.byKey(const ValueKey('auditar_texto')),
      docString(ctx.docContent),
    );
  },
  'veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsWidgets);
  },
  'no veo "{t}"'.mapper(): (_, ctx) async {
    expect(find.text(ctx.arg<String>(0)), findsNothing);
  },
  'veo el texto que contiene "{t}"'.mapper(): (_, ctx) async {
    expect(find.textContaining(ctx.arg<String>(0)), findsWidgets);
  },
  // SPEC-003 T4 (t15_pantalla_multisede.feature).
  'no veo el texto que contiene "{t}"'.mapper(): (_, ctx) async {
    expect(find.textContaining(ctx.arg<String>(0)), findsNothing);
  },
  'escribo "{v}" en la clave "{k}"'.mapper(): (_, ctx) async {
    await probador.enterText(find.byKey(ValueKey(ctx.arg<String>(1))), ctx.arg<String>(0));
  },
  'el campo "{k}" está vacío con la pista "{p}"'.mapper(): (_, ctx) async {
    final campo = probador.widget<TextField>(find.byKey(ValueKey(ctx.arg<String>(0))));
    expect(campo.controller!.text, isEmpty);
    expect(campo.decoration!.hintText, ctx.arg<String>(1));
  },
  '"{t}" está elegido'.mapper(): (_, ctx) async {
    final boton = probador.widget<SegmentedButton<Enrutamiento>>(find.byType(SegmentedButton<Enrutamiento>));
    expect([for (final s in boton.segments) if (boton.selected.contains(s.value)) (s.label! as Text).data], [ctx.arg<String>(0)]);
  },
  'la configuración de "{e}" tiene la línea "{l}"'.mapper(): (_, ctx) async {
    expect(_configuracion(ctx.arg<String>(0)).split('\n'), contains(ctx.arg<String>(1)));
  },
  'copio la configuración de "{e}"'.mapper(): (_, ctx) async {
    _copiada = _configuracion(ctx.arg<String>(0));
  },
  'pego lo copiado'.mapper(): (_, ctx) async {
    await probador.enterText(find.byKey(const ValueKey('auditar_texto')), _copiada!);
  },
  'los routers que se pueden elegir son "{lista}"'.mapper(): (_, ctx) async {
    final boton = probador.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>).first);
    expect([for (final s in boton.segments) (s.label! as Text).data], ctx.arg<String>(0).split(','));
  },
  'el campo "{k}" dice "{t}"'.mapper(): (_, ctx) async {
    expect(probador.widget<TextField>(find.byKey(ValueKey(ctx.arg<String>(0)))).controller!.text, ctx.arg<String>(1));
  },
  'la etiqueta del campo "{k}" es "{t}"'.mapper(): (_, ctx) async {
    expect(probador.widget<TextField>(find.byKey(ValueKey(ctx.arg<String>(0)))).decoration!.labelText, ctx.arg<String>(1));
  },
  'hay un campo con la clave "{k}"'.mapper(): (_, ctx) async {
    expect(find.byKey(ValueKey(ctx.arg<String>(0))), findsOneWidget);
  },
  'no hay un campo con la clave "{k}"'.mapper(): (_, ctx) async {
    expect(find.byKey(ValueKey(ctx.arg<String>(0))), findsNothing);
  },
  'en la sede {k} quito el segmento {n}'.mapper(): (_, ctx) async {
    await _tocar(find.byTooltip('Quitar segmento ${ctx.arg<String>(1)} de la sede ${ctx.arg<String>(0)}'));
  },
});

String? _copiada;

/// El texto de la configuración del equipo [hostname] en la pestaña
/// Configuración.
String _configuracion(String hostname) => [
  for (final t in probador.widgetList<SelectableText>(find.byType(SelectableText)))
    if (t.data!.contains('hostname $hostname\n')) t.data!,
].single;

Future<void> main() async {
  setUp(() => _copiada = null);
  await correrFeature('t05_pantalla.feature', _pasos);
  await correrFeature('t15_pantalla_multisede.feature', _pasos);
}
