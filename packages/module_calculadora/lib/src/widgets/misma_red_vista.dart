import 'package:flutter/material.dart';

import '../logic/misma_red.dart';
import 'resultado_widgets.dart';

/// Campo opcional "Otra IP o gateway" y si está en la misma red que [ip]/
/// [cidr] (pestaña "Red").
class MismaRedVista extends StatefulWidget {
  const MismaRedVista(this.ip, this.cidr, {super.key});
  final String ip;
  final int cidr;

  @override
  State<MismaRedVista> createState() => _MismaRedVistaState();
}

class _MismaRedVistaState extends State<MismaRedVista> {
  final TextEditingController _otra = TextEditingController();

  @override
  void dispose() {
    _otra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final respuesta = compararRed(widget.ip, _otra.text.trim(), widget.cidr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        TextField(
          controller: _otra,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Otra IP o gateway (opcional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (respuesta != null) FilaDato('¿Misma red?:', respuesta),
      ],
    );
  }
}
