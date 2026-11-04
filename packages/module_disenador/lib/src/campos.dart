import 'package:flutter/material.dart';

/// Piezas del formulario del Diseñador que comparten la sede 1 y las sedes
/// 2, 3… (SPEC-003 T4).
const double _hueco = 12;

/// Campo de texto con su etiqueta (y [pista]) y un hueco debajo.
Widget campoTexto(TextEditingController c, String etiqueta, {Key? key, String? pista}) => Padding(
  padding: const EdgeInsets.only(bottom: _hueco),
  child: TextField(
    key: key,
    controller: c,
    decoration: InputDecoration(labelText: etiqueta, hintText: pista),
  ),
);

/// Botón "+ [texto]" alineado a la izquierda.
Widget botonAgregar(String texto, VoidCallback alTocar) => Align(
  alignment: Alignment.centerLeft,
  child: TextButton.icon(onPressed: alTocar, icon: const Icon(Icons.add), label: Text(texto)),
);

/// Fila de un segmento: sus [campos] y el botón [tooltip] que la quita.
Widget filaConQuitar(Key key, List<Widget> campos, String tooltip, VoidCallback quitar) => Row(
  key: key,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    ...campos,
    IconButton(tooltip: tooltip, icon: const Icon(Icons.remove_circle_outline), onPressed: quitar),
  ],
);
