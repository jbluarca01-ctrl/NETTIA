import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/aplicar.dart';
import 'logic/auditor.dart';
import 'logic/generador.dart';
import 'logic/repara.dart';
import 'vistas_resultado.dart';

const double _hueco = 12;
const TextStyle _consola = TextStyle(fontFamilyFallback: kMonoFallback);

/// Nivel 2 de "Repara la red" (SPEC-002 T2): el estudiante escribe los
/// comandos en el equipo que elija y Nettia los aplica y vuelve a auditar.
class ReparaNivel2 extends StatefulWidget {
  const ReparaNivel2(this.ejercicio, {super.key});

  final EjercicioRepara ejercicio;

  @override
  State<ReparaNivel2> createState() => _ReparaNivel2State();
}

class _ReparaNivel2State extends State<ReparaNivel2> {
  // Nacen con el ejercicio y cambian al aplicar; se descartan con el
  // siguiente ejercicio (el widget lleva su clave) o al salir.
  late List<ConfigEquipo> _configs = widget.ejercicio.configs;
  late String _equipo = _configs.first.hostname;
  var _texto = '';
  List<Hallazgo>? _hallazgos;
  List<String> _noReconocidos = const [];
  late bool _verSolucion;

  void _aplicar() => setState(() {
    final i = _configs.indexWhere((c) => c.hostname == _equipo);
    final r = aplicarComandos(_configs[i], _texto);
    _configs = [..._configs]..[i] = r.config;
    _noReconocidos = r.noReconocidos;
    _hallazgos = auditarTodas(_configs, widget.ejercicio.plan);
    _verSolucion = false;
  });

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.titleSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Síntoma', style: titulo),
        Text(widget.ejercicio.sintoma),
        for (final c in _configs) ...[
          const SizedBox(height: _hueco),
          Text('show running-config de ${c.hostname}', style: titulo),
          SelectableText(c.texto, key: ValueKey('repara_config_${c.hostname}'), style: _consola),
        ],
        const SizedBox(height: _hueco),
        Text('Escribe la corrección', style: titulo),
        ..._editor(),
        const SizedBox(height: _hueco),
        FilledButton(onPressed: _aplicar, child: const Text('Aplicar y auditar')),
        ..._resultado(),
      ],
    );
  }

  /// El equipo donde se aplican los comandos y el cuadro para escribirlos.
  List<Widget> _editor() => [
    Wrap(
      spacing: 8,
      children: [
        for (final c in _configs)
          ChoiceChip(
            label: Text(c.hostname),
            selected: _equipo == c.hostname,
            onSelected: (_) => setState(() => _equipo = c.hostname),
          ),
      ],
    ),
    TextField(
      key: const ValueKey('repara_comandos'),
      onChanged: (t) => _texto = t,
      minLines: 4,
      maxLines: null,
      style: _consola,
      decoration: const InputDecoration(hintText: 'interface …'),
    ),
  ];

  List<Widget> _resultado() {
    final hallazgos = _hallazgos;
    if (hallazgos == null) return const [];
    return [
      const SizedBox(height: _hueco),
      for (final c in _noReconocidos) Text('No reconocido: $c'),
      if (hallazgos.isEmpty)
        const Text('¡Red reparada! El auditor ya no encuentra problemas.')
      else ...[
        const Text('Todavía hay problemas:'),
        for (final h in hallazgos) Text(h.mensaje),
        if (_verSolucion)
          for (final h in hallazgos) TarjetaHallazgo(h)
        else
          FilledButton.tonal(
            onPressed: () => setState(() => _verSolucion = true),
            child: const Text('Ver la solución'),
          ),
      ],
    ];
  }
}
