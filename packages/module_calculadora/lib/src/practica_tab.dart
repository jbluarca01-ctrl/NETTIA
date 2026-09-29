import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/practica.dart';
import 'widgets/resultado_widgets.dart';

/// Pestaña "Práctica": ejercicios al azar donde escribes tu respuesta y la app
/// la corrige campo por campo y muestra el procedimiento.
class PracticaTab extends StatefulWidget {
  const PracticaTab({super.key, this.rnd});

  /// Para pruebas: generador con semilla.
  final Random? rnd;

  @override
  State<PracticaTab> createState() => _PracticaTabState();
}

class _PracticaTabState extends State<PracticaTab>
    with AutomaticKeepAliveClientMixin {
  late final Random _rnd = widget.rnd ?? Random();
  TipoEjercicio _tipo = TipoEjercicio.dividirSubredes;
  late Ejercicio _ejercicio = generarEjercicio(_tipo, _rnd);
  List<TextEditingController> _controles = <TextEditingController>[];
  List<ResultadoCampo>? _resultados;
  int _hechos = 0;
  int _perfectos = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _prepararControles();
  }

  void _prepararControles() {
    for (final c in _controles) {
      c.dispose();
    }
    _controles = <TextEditingController>[
      for (final _ in _ejercicio.campos) TextEditingController(),
    ];
    _resultados = null;
  }

  @override
  void dispose() {
    for (final c in _controles) {
      c.dispose();
    }
    super.dispose();
  }

  void _nuevo() {
    setState(() {
      _ejercicio = generarEjercicio(_tipo, _rnd);
      _prepararControles();
    });
  }

  void _corregir() {
    final r = corregir(_ejercicio, _controles.map((c) => c.text).toList());
    setState(() {
      _resultados = r;
      _hechos++;
      if (r.every((x) => x.acierto)) _perfectos++;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final r = _resultados;
    final aciertos = r?.where((x) => x.acierto).length ?? 0;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SeccionCalculadora(
            titulo: 'Práctica de subneteo',
            icono: NettiaIcons.estudiante,
            hijos: <Widget>[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  for (final t in TipoEjercicio.values)
                    ChoiceChip(
                      label: Text(t.titulo, style: const TextStyle(fontSize: 12)),
                      selected: _tipo == t,
                      onSelected: (_) {
                        _tipo = t;
                        _nuevo();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                _ejercicio.enunciado,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _ejercicio.campos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _campo(i, theme),
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: r == null ? _corregir : null,
                      child: const Text('Corregir'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _nuevo,
                      child: const Text('Otro ejercicio'),
                    ),
                  ),
                ],
              ),
              if (r != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  aciertos == r.length
                      ? '✅ ¡Todo correcto! ($aciertos/${r.length})'
                      : 'Acertaste $aciertos de ${r.length}. Revisa las marcadas.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                PasosYAvisos(pasos: _ejercicio.pasos),
              ],
              const SizedBox(height: 8),
              Text(
                'Ejercicios resueltos: $_hechos · sin errores: $_perfectos',
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campo(int i, ThemeData theme) {
    final campo = _ejercicio.campos[i];
    final res = _resultados == null ? null : _resultados![i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _controles[i],
          enabled: res == null,
          style: const TextStyle(fontFamilyFallback: kMonoFallback, fontSize: 14),
          decoration: InputDecoration(
            labelText: campo.etiqueta,
            hintText: campo.ayuda.isEmpty ? null : campo.ayuda,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: res == null
                ? null
                : Icon(
                    res.acierto ? NettiaIcons.validado : NettiaIcons.aviso,
                    color: res.acierto ? NetworkTheme.ledGreen : theme.colorScheme.error,
                  ),
          ),
        ),
        if (res != null && !res.acierto)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: SelectableText(
              'Correcto: ${campo.correcta}',
              style: TextStyle(
                fontSize: 12.5,
                fontFamilyFallback: kMonoFallback,
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
