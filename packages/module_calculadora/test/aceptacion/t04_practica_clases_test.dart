// Pasos de aceptación de t04_practica_clases.feature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkart/gherkart.dart';
import 'package:module_calculadora/src/logic/practica.dart';
import 'package:module_calculadora/src/practica_tab.dart';
import 'package:nettia_core/nettia_core.dart';

import 'comun.dart';

late Ejercicio _e;
List<ResultadoCampo> _correccion = const [];

(String, int) _ipYPrefijo(String texto) {
  final partes = texto.split('/');
  return (partes[0], int.parse(partes[1]));
}

final _pasos = StepRegistry<void>.fromMap({
  'el ejercicio de red para "{ip}"'.mapper(): (_, ctx) async {
    final (ip, cidr) = _ipYPrefijo(ctx.arg<String>(0));
    _e = ejercicioRedDeIp(ip, cidr);
  },
  'el ejercicio de clasificar "{ip}"'.mapper(): (_, ctx) async {
    _e = ejercicioClasificar(ctx.arg<String>(0));
  },
  'el ejercicio de asignar "{ip}"'.mapper(): (_, ctx) async {
    final (ip, cidr) = _ipYPrefijo(ctx.arg<String>(0));
    _e = ejercicioAsignable(ip, cidr);
  },
  'el ejercicio VLSM de "{red}" con {a}, {b}, {c} y {d} hosts'.mapper(
    types: {'a': int, 'b': int, 'c': int, 'd': int},
  ): (_, ctx) async {
    final (red, cidr) = _ipYPrefijo(ctx.arg<String>(0));
    _e = ejercicioVlsm(red, cidr, [
      for (var i = 1; i <= 4; i++) ctx.arg<int>(i),
    ]);
  },
  'la respuesta de "{campo}" es "{valor}"'.mapper(): (_, ctx) async {
    final campo = _e.campos.singleWhere(
      (c) => c.etiqueta == ctx.arg<String>(0),
    );
    expect(campo.correcta, ctx.arg<String>(1));
  },
  'el procedimiento incluye "{t}"'.mapper(): (_, ctx) async {
    expect(_e.pasos.join('\n'), contains(ctx.arg<String>(0)));
  },
  'respondo "{a}" y "{b}"'.mapper(): (_, ctx) async {
    _correccion = corregir(_e, [ctx.arg<String>(0), ctx.arg<String>(1)]);
  },
  'todo está correcto'.mapper(): (_, ctx) async {
    expect(_correccion.every((r) => r.acierto), isTrue);
  },
  'la pestaña "Práctica"'.mapper(): (_, ctx) async {
    await probador.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: PracticaTab()),
      ),
    );
  },
  'hay un ejercicio "{t}"'.mapper(): (_, ctx) async {
    expect(find.widgetWithText(ChoiceChip, ctx.arg<String>(0)), findsOneWidget);
  },
});

void main() => correrFeature('t04_practica_clases.feature', _pasos);
