import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/ipv4_subnetting.dart';
import 'widgets/fila_vlsm.dart';
import 'widgets/resultado_widgets.dart';

/// Pestaña "VLSM": asigna a cada red el bloque más pequeño que le alcance.
class VlsmTab extends StatefulWidget {
  const VlsmTab({super.key});

  @override
  State<VlsmTab> createState() => _VlsmTabState();
}

class _VlsmTabState extends State<VlsmTab>
    with AutomaticKeepAliveClientMixin, FilasVlsmState<VlsmTab> {
  final TextEditingController _ip = TextEditingController(text: '192.168.1.0');
  int _cidr = 24;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ip.dispose();
    disposeFilas();
    super.dispose();
  }

  ({ResultadoVlsm? resultado, String? error}) _calcular() {
    try {
      return (
        resultado:
            calcularVlsm(_ip.text, _cidr, requerimientosDesde(filasVlsm)),
        error: null
      );
    } on SubneteoException catch (e) {
      return (resultado: null, error: e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = _calcular();
    final res = r.resultado;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SeccionCalculadora(
            titulo: 'VLSM (máscaras de longitud variable)',
            icono: NettiaIcons.diagrama,
            hijos: <Widget>[
              RedYPrefijoRow(
                ip: _ip,
                etiquetaIp: 'Red disponible (IPv4)',
                cidr: _cidr,
                onIpChanged: () => setState(() {}),
                onCidrChanged: (v) => setState(() => _cidr = v),
              ),
              const SizedBox(height: 12),
              construirListaFilasVlsm(),
              const SizedBox(height: 6),
              if (res == null)
                MensajeError(r.error!)
              else ...<Widget>[
                const Divider(),
                FilaDato('Direcciones libres al final:',
                    '${res.direccionesLibres}'),
                const SizedBox(height: 6),
                PasosYAvisos(pasos: res.pasos, avisos: res.avisos),
              ],
            ],
          ),
          if (res != null) ...<Widget>[
            const SizedBox(height: 12),
            SeccionCalculadora(
              titulo: 'Asignación (de mayor a menor)',
              icono: NettiaIcons.calculadora,
              hijos: <Widget>[TablaSubredesIpv4(subredes: res.subredes)],
            ),
          ],
        ],
      ),
    );
  }
}
