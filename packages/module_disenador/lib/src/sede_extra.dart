import 'package:flutter/material.dart';

import 'campos.dart';
import 'logic/formulario.dart';

const double _hueco = 12;

/// Lo que se escribe de una sede 2, 3… (SPEC-003 T4): su red base y sus
/// segmentos. Nace cuando se eligen más routers y se libera con [liberar]
/// cuando se eligen menos o se cierra la pantalla.
class SedeExtra {
  SedeExtra(this.numero);

  /// Número de la sede (2, 3…): también el de su router.
  final int numero;
  final red = TextEditingController();
  final List<(TextEditingController, TextEditingController)> filas = [_fila()];

  static (TextEditingController, TextEditingController) _fila() => (TextEditingController(), TextEditingController());

  EntradaSede get entrada => EntradaSede(red.text, [for (final (n, h) in filas) (n.text, h.text)]);

  void liberar() {
    red.dispose();
    filas.forEach(_liberarFila);
  }

  static void _liberarFila((TextEditingController, TextEditingController) f) {
    f.$1.dispose();
    f.$2.dispose();
  }
}

/// Tarjeta plegable "Sede k (Rk)" con la red base y los segmentos.
class TarjetaSede extends StatefulWidget {
  const TarjetaSede(this.sede, {super.key});

  final SedeExtra sede;

  @override
  State<TarjetaSede> createState() => _TarjetaSedeState();
}

class _TarjetaSedeState extends State<TarjetaSede> {
  SedeExtra get _s => widget.sede;

  void _agregar() => setState(() => _s.filas.add(SedeExtra._fila()));

  /// Quita la fila [i]; sus controladores se liberan después del cuadro en
  /// que dejan de usarse.
  void _quitar(int i) {
    final fila = _s.filas[i];
    setState(() => _s.filas.removeAt(i));
    WidgetsBinding.instance.addPostFrameCallback((_) => SedeExtra._liberarFila(fila));
  }

  @override
  Widget build(BuildContext context) {
    final k = _s.numero;
    return Card(
      margin: const EdgeInsets.only(bottom: _hueco),
      child: ExpansionTile(
        key: ValueKey('sede_$k'),
        initiallyExpanded: true,
        title: Text('Sede $k (R$k)'),
        childrenPadding: const EdgeInsets.all(_hueco),
        children: [
          campoTexto(_s.red, 'Red base', key: ValueKey('sede${k}_red'), pista: '192.168.${10 * k}.0/24'),
          for (var i = 0; i < _s.filas.length; i++) _fila(k, i),
          botonAgregar('Agregar segmento a la sede $k', _agregar),
        ],
      ),
    );
  }

  Widget _fila(int k, int i) {
    final (nombre, hosts) = _s.filas[i];
    final n = i + 1;
    return filaConQuitar(ObjectKey(nombre), [
      Expanded(child: campoTexto(nombre, 'Nombre', key: ValueKey('sede${k}_nombre_$n'))),
      const SizedBox(width: _hueco),
      Expanded(child: campoTexto(hosts, 'Hosts', key: ValueKey('sede${k}_hosts_$n'))),
    ], 'Quitar segmento $n de la sede $k', () => _quitar(i));
  }
}
