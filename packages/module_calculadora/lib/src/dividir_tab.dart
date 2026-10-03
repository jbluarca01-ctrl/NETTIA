import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/ipv4_subnetting.dart';
import 'widgets/fila_vlsm.dart';
import 'widgets/resultado_widgets.dart';

/// Modo de la pestaña "Dividir": subredes iguales por cantidad, subredes
/// iguales por hosts, o un tamaño distinto por subred (como VLSM).
enum _ModoDividir { cantidad, hostsIguales, tamanosPersonalizados }

/// Pestaña "Dividir": parte una red IPv4 en N subredes del mismo tamaño, en
/// subredes que admitan cierta cantidad de hosts, o en bloques de tamaño
/// distinto por subred según los hosts que necesite cada una.
class DividirTab extends StatefulWidget {
  const DividirTab({super.key});

  @override
  State<DividirTab> createState() => _DividirTabState();
}

class _DividirTabState extends State<DividirTab>
    with AutomaticKeepAliveClientMixin, FilasVlsmState<DividirTab> {
  final TextEditingController _ip = TextEditingController(text: '192.168.1.0');
  final TextEditingController _cantidad = TextEditingController(text: '16');
  int _cidr = 24;
  _ModoDividir _modo = _ModoDividir.cantidad;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _ip.dispose();
    _cantidad.dispose();
    disposeFilas();
    super.dispose();
  }

  ({DivisionIpv4? division, ResultadoVlsm? vlsm, String? error}) _calcular() {
    if (_modo == _ModoDividir.tamanosPersonalizados) {
      try {
        return (
          division: null,
          vlsm: calcularVlsm(_ip.text, _cidr, requerimientosDesde(filasVlsm)),
          error: null
        );
      } on SubneteoException catch (e) {
        return (division: null, vlsm: null, error: e.mensaje);
      }
    }
    final n = int.tryParse(_cantidad.text.trim());
    if (n == null) {
      return (
        division: null,
        vlsm: null,
        error: _modo == _ModoDividir.hostsIguales
            ? 'Escribe cuántos hosts necesita cada subred.'
            : 'Escribe en cuántas subredes quieres dividir.'
      );
    }
    try {
      return (
        division: _modo == _ModoDividir.hostsIguales
            ? dividirPorHosts(_ip.text, _cidr, n)
            : dividirEnSubredes(_ip.text, _cidr, n),
        vlsm: null,
        error: null
      );
    } on SubneteoException catch (e) {
      return (division: null, vlsm: null, error: e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final r = _calcular();
    final d = r.division;
    final vlsm = r.vlsm;
    final subredes = d?.subredes ?? vlsm?.subredes;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SeccionCalculadora(
            titulo: 'Dividir una red en subredes',
            icono: NettiaIcons.calculadora,
            hijos: <Widget>[
              RedYPrefijoRow(
                ip: _ip,
                etiquetaIp: 'Red (IPv4)',
                cidr: _cidr,
                onIpChanged: () => setState(() {}),
                onCidrChanged: (v) => setState(() => _cidr = v),
              ),
              const SizedBox(height: 10),
              SegmentedButton<_ModoDividir>(
                segments: const <ButtonSegment<_ModoDividir>>[
                  ButtonSegment<_ModoDividir>(
                      value: _ModoDividir.cantidad,
                      label: Text('Nº de subredes')),
                  ButtonSegment<_ModoDividir>(
                      value: _ModoDividir.hostsIguales,
                      label: Text('Hosts por subred')),
                  ButtonSegment<_ModoDividir>(
                      value: _ModoDividir.tamanosPersonalizados,
                      label: Text('Tamaños personalizados')),
                ],
                selected: <_ModoDividir>{_modo},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _modo = s.first),
              ),
              const SizedBox(height: 10),
              if (_modo == _ModoDividir.tamanosPersonalizados)
                construirListaFilasVlsm()
              else
                CampoNumeroDenso(
                  controller: _cantidad,
                  labelText: _modo == _ModoDividir.hostsIguales
                      ? 'Hosts útiles que necesita cada subred'
                      : 'Cantidad de subredes',
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 12),
              if (subredes == null)
                MensajeError(r.error!)
              else ...<Widget>[
                const Divider(),
                if (d != null) ...<Widget>[
                  FilaDato(
                      'Red original:', '${d.redOriginal}/${d.cidrOriginal}'),
                  FilaDato('Nuevo prefijo:',
                      '/${d.nuevoCidr} (${d.subredes.first.mascara})'),
                  FilaDato('Bits prestados:', '${d.bitsPrestados}'),
                  FilaDato('Hosts útiles por subred:',
                      '${d.subredes.first.hostsUtiles}'),
                ],
                FilaDato('Subredes:', '${d?.totalSubredes ?? subredes.length}'),
                if (vlsm != null)
                  FilaDato('Direcciones libres al final:',
                      '${vlsm.direccionesLibres}'),
                const SizedBox(height: 6),
                PasosYAvisos(
                  pasos: d?.pasos ?? vlsm?.pasos ?? const <String>[],
                  avisos: d?.avisos ?? vlsm?.avisos ?? const <String>[],
                ),
              ],
            ],
          ),
          if (subredes != null) ...<Widget>[
            const SizedBox(height: 12),
            SeccionCalculadora(
              titulo: 'Subredes resultantes',
              icono: NettiaIcons.diagrama,
              hijos: <Widget>[
                TablaSubredesIpv4(
                  subredes: subredes,
                  primerasUsadas: d?.subredesPedidas,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
