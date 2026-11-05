import 'package:flutter/material.dart';

import 'logic/auditor.dart';
import 'logic/doctor_rutas.dart';
import 'logic/entrada_doctor.dart';
import 'vistas_resultado.dart';

const double _hueco = 12;

/// Nombre del [m] en pantalla (SPEC-004 T5).
String nombreModo(ModoRutas m) => switch (m) {
  ModoRutas.estatica => 'Estática',
  ModoRutas.ospf => 'OSPF',
};

/// Auditar con varios routers (SPEC-004 T5): se pegan una o varias salidas
/// y el doctor las revisa contra el diseño. El texto, el modo y el
/// resultado los guarda la pantalla del Diseñador.
class VistaDoctor extends StatelessWidget {
  const VistaDoctor(
    this.texto,
    this.resultado,
    this.modo, {
    required this.onModo,
    required this.onRevisar,
    super.key,
  });

  final TextEditingController texto;

  /// `null` hasta la primera revisión del diseño actual.
  final ResultadoDoctor? resultado;
  final ModoRutas modo;
  final void Function(ModoRutas modo) onModo;
  final VoidCallback onRevisar;

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.titleSmall;
    return ListView(
      padding: const EdgeInsets.all(_hueco),
      children: [
        const Text('Pega una o varias running-config o show ip route de los equipos, una tras otra.'),
        const SizedBox(height: _hueco),
        campoPegado(texto, 'running-config o show ip route'),
        const SizedBox(height: _hueco),
        Text('Revisar enrutamiento como', style: titulo),
        SegmentedButton<ModoRutas>(
          segments: [for (final m in ModoRutas.values) ButtonSegment(value: m, label: Text(nombreModo(m)))],
          selected: {modo},
          onSelectionChanged: (s) => onModo(s.first),
        ),
        const SizedBox(height: _hueco),
        FilledButton(onPressed: onRevisar, child: const Text('Auditar')),
        ..._resultado(context),
      ],
    );
  }

  List<Widget> _resultado(BuildContext context) {
    final r = resultado;
    if (r == null) return const [];
    if (r.bloques.isEmpty) return const [_Aviso('No se encontró ninguna running-config ni show ip route.')];
    final titulo = Theme.of(context).textTheme.titleMedium;
    return [
      if (r.sinDiferencias) const _Aviso('Sin diferencias con el diseño.'),
      for (final (nombre, hallazgos) in r.bloques) ...[
        Padding(padding: const EdgeInsets.only(top: _hueco), child: Text(nombre, style: titulo)),
        if (hallazgos.isEmpty) const Text('Sin diferencias.') else ..._tarjetas(hallazgos),
      ],
      if (r.camino case final camino?) ...[
        Padding(padding: const EdgeInsets.only(top: _hueco), child: Text('Camino entre sedes', style: titulo)),
        if (camino.isEmpty) const Text('Llega de cada sede a cada otra, ida y vuelta.') else ..._tarjetas(camino),
      ],
    ];
  }

  static List<Widget> _tarjetas(List<Hallazgo> hallazgos) => [for (final h in hallazgos) TarjetaHallazgo(h)];
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: _hueco), child: Text(texto));
}
