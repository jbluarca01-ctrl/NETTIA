import 'package:flutter/material.dart';

import '../logic/clasificacion_ipv4.dart';
import 'resultado_widgets.dart';

/// Clase, tipo y explicación de una IPv4 (pestaña "Red"). No muestra nada si
/// la IP no es válida.
class ClasificacionVista extends StatelessWidget {
  const ClasificacionVista(this.ip, {super.key});
  final String ip;

  @override
  Widget build(BuildContext context) {
    final c = clasificarIpv4(ip);
    if (c == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilaDato('Clase:', c.claseTexto),
        FilaDato('Tipo:', c.tipo.texto),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Text(
            c.explicacion,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
