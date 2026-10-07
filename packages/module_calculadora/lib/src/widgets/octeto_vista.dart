import 'package:flutter/material.dart';

import '../logic/and_ipv4.dart';
import 'resultado_widgets.dart';

const _ordinales = <String>['1.er', '2.º', '3.er', '4.º'];

/// Bloque y AND del octeto interesante de [ip]/[cidr] (pestaña "Red").
class OctetoVista extends StatelessWidget {
  const OctetoVista(this.ip, this.cidr, {super.key});
  final String ip;
  final int cidr;

  @override
  Widget build(BuildContext context) {
    final oi = octetoInteresante(ip.split('.').map(int.parse).toList(), cidr);
    if (oi == null) {
      return const FilaDato('Bloque (salto):', 'La máscara corta entre octetos');
    }
    return Column(
      children: <Widget>[
        FilaDato(
          'Bloque (salto):',
          '${oi.bloque} en el ${_ordinales[oi.posicion - 1]} octeto '
              '(256 − ${oi.mascara})',
        ),
        FilaDato('AND del octeto:', oi.operacion),
      ],
    );
  }
}
