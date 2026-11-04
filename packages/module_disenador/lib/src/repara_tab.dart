import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/repara.dart';
import 'repara_nivel2.dart';
import 'vistas_resultado.dart';

const double _hueco = 12;
const TextStyle _consola = TextStyle(fontFamilyFallback: kMonoFallback);

EjercicioRepara _alAzar() => ejercicioAlAzar(Random());

/// Pestaña "Repara la red" (SPEC-001 T2): síntoma, running-config de los
/// equipos y 4 causas; al comprobar, si acertó y el diagnóstico del auditor.
class RepararTab extends StatefulWidget {
  const RepararTab({this.crear = _alAzar, super.key});

  /// Crea cada ejercicio nuevo (al azar; fijo en las pruebas).
  final EjercicioRepara Function() crear;

  @override
  State<RepararTab> createState() => _RepararTabState();
}

class _RepararTabState extends State<RepararTab> {
  // Nacen con "Nuevo ejercicio"; se descartan con el siguiente o al salir.
  EjercicioRepara? _ejercicio;
  int? _elegida;
  ResultadoRepara? _resultado;
  late bool _faltaElegir;
  // Nivel elegido (SPEC-002 T2): se conserva entre ejercicios; se descarta
  // al salir.
  var _nivel = _Nivel.causa;

  void _nuevo() => setState(() {
    _ejercicio = widget.crear();
    _elegida = null;
    _resultado = null;
    _faltaElegir = false;
  });

  void _comprobar() => setState(() {
    final i = _elegida;
    _faltaElegir = i == null;
    _resultado = i == null ? null : _ejercicio!.responder(i);
  });

  @override
  Widget build(BuildContext context) {
    final e = _ejercicio;
    return ListView(
      padding: const EdgeInsets.all(_hueco),
      children: [
        FilledButton(onPressed: _nuevo, child: const Text('Nuevo ejercicio')),
        const SizedBox(height: _hueco),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in _Nivel.values)
              ChoiceChip(
                label: Text(_texto(n)),
                selected: _nivel == n,
                onSelected: (_) => setState(() => _nivel = n),
              ),
          ],
        ),
        if (e == null)
          const Text('Toca Nuevo ejercicio para empezar.')
        else if (_nivel == _Nivel.causa)
          ..._ejercicioVisible(context, e)
        else
          ReparaNivel2(e, key: ObjectKey(e)),
      ],
    );
  }



  List<Widget> _ejercicioVisible(BuildContext context, EjercicioRepara e) {
    final titulo = Theme.of(context).textTheme.titleSmall;
    return [
      Text('Síntoma', style: titulo),
      Text(e.sintoma),
      for (final c in e.configs) ...[
        const SizedBox(height: _hueco),
        Text('show running-config de ${c.hostname}', style: titulo),
        SelectableText(c.texto, style: _consola),
      ],
      const SizedBox(height: _hueco),
      Text('¿Cuál es la causa?', style: titulo),
      for (var i = 0; i < e.causas.length; i++)
        ListTile(
          key: ValueKey('repara_causa_$i'),
          leading: Icon(_elegida == i ? Icons.radio_button_checked : Icons.radio_button_unchecked),
          title: Text(e.causas[i]),
          onTap: () => setState(() => _elegida = i),
        ),
      FilledButton(onPressed: _comprobar, child: const Text('Comprobar')),
      if (_faltaElegir) const Text('Elige una causa antes de comprobar.'),
      ..._resultadoVisible(),
    ];
  }

  List<Widget> _resultadoVisible() {
    final r = _resultado;
    if (r == null) return const [];
    return [
      Padding(
        key: const ValueKey('repara_resultado'),
        padding: const EdgeInsets.only(top: _hueco),
        child: Text(r.acierto ? 'Correcto: ${r.causaCorrecta}' : 'Incorrecto. La causa era: ${r.causaCorrecta}'),
      ),
      for (final h in r.hallazgos) TarjetaHallazgo(h),
    ];
  }
}

/// Niveles de la pestaña (SPEC-002 T2).
enum _Nivel { causa, correccion }

String _texto(_Nivel n) => switch (n) {
  _Nivel.causa => 'Nivel 1: elegir la causa',
  _Nivel.correccion => 'Nivel 2: escribir la corrección',
};
