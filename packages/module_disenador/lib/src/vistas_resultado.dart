import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/auditor.dart';
import 'logic/formulario.dart';
import 'logic/generador.dart';
import 'logic/plan_red.dart';

const double _hueco = 12;
const TextStyle _consola = TextStyle(fontFamilyFallback: kMonoFallback);

/// Lista con el [contenido] del diseño, o el aviso de que falta diseñar.
Widget _conDiseno(Diseno? d, List<Widget> Function(Diseno d) contenido) {
  if (d == null) {
    return const Center(child: Text('Completa los datos y toca Diseñar.'));
  }
  return ListView(
    padding: const EdgeInsets.all(_hueco),
    children: contenido(d),
  );
}

/// Pestaña Plan: un recuadro por segmento y las direcciones libres.
class VistaPlan extends StatelessWidget {
  const VistaPlan(this.diseno, {super.key});

  final Diseno? diseno;

  @override
  Widget build(BuildContext context) => _conDiseno(
    diseno,
    (d) => [
      for (final s in d.plan.segmentos) _TarjetaSegmento(s),
      Text(
        'Quedan ${d.plan.direccionesLibres} direcciones libres en la red base.',
      ),
      for (final aviso in d.plan.avisos) Text(aviso),
    ],
  );
}

class _TarjetaSegmento extends StatelessWidget {
  const _TarjetaSegmento(this.s);

  final SegmentoPlan s;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: _hueco),
    child: Padding(
      padding: const EdgeInsets.all(_hueco),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s.nombre} · VLAN ${s.vlan}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text('Red ${s.red}/${s.cidr} · máscara ${s.mascara}'),
          Text('Gateway ${s.gateway} · DHCP ${s.dhcp}'),
          if (s.reservadas case final r?) Text('Reservadas $r'),
          Text('${s.hostsPedidos} hosts · uso del DHCP ${s.utilizacionPct} %'),
        ],
      ),
    ),
  );
}

/// Pestaña Configuración: la de cada equipo, lista para copiar.
class VistaConfiguracion extends StatelessWidget {
  const VistaConfiguracion(this.diseno, {super.key});

  final Diseno? diseno;

  @override
  Widget build(BuildContext context) =>
      _conDiseno(diseno, (d) => [for (final e in d.equipos) _TarjetaEquipo(e)]);
}

class _TarjetaEquipo extends StatelessWidget {
  const _TarjetaEquipo(this.e);

  final ConfigEquipo e;

  void _copiar(BuildContext context) {
    unawaited(Clipboard.setData(ClipboardData(text: e.texto)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configuración de ${e.hostname} copiada.')),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: _hueco),
    child: Padding(
      padding: const EdgeInsets.all(_hueco),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.hostname,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => _copiar(context),
                icon: const Icon(NettiaIcons.copiar),
                label: Text('Copiar ${e.hostname}'),
              ),
            ],
          ),
          SelectableText(e.texto, style: _consola),
        ],
      ),
    ),
  );
}

/// Pestaña Verificación: equipo y comando, con lo que se debe ver.
class VistaVerificacion extends StatelessWidget {
  const VistaVerificacion(this.diseno, {super.key});

  final Diseno? diseno;

  @override
  Widget build(BuildContext context) => _conDiseno(
    diseno,
    (d) => [
      for (final p in d.verificacion)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${p.equipo} · ${p.comando}', style: _consola),
          subtitle: Text(p.esperado),
        ),
    ],
  );
}

/// Pestaña Auditar: se pega una running-config y se compara con el plan.
/// El texto y los hallazgos los guarda la pantalla del Diseñador, así no se
/// pierden al cambiar de pestaña.
class VistaAuditar extends StatelessWidget {
  const VistaAuditar(
    this.diseno,
    this.texto,
    this.hallazgos, {
    required this.onAuditar,
    super.key,
  });

  final Diseno? diseno;
  final TextEditingController texto;

  /// `null` hasta la primera auditoría del diseño actual.
  final List<Hallazgo>? hallazgos;
  final void Function(PlanRed plan) onAuditar;

  @override
  Widget build(BuildContext context) => _conDiseno(
    diseno,
    (d) => [
      const Text('Pega el show running-config de un equipo de la red.'),
      const SizedBox(height: _hueco),
      TextField(
        key: const ValueKey('auditar_texto'),
        controller: texto,
        minLines: 6,
        maxLines: 14,
        style: _consola,
        decoration: const InputDecoration(
          labelText: 'running-config',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: _hueco),
      FilledButton(
        onPressed: () => onAuditar(d.plan),
        child: const Text('Auditar'),
      ),
      ..._resultado(),
    ],
  );

  List<Widget> _resultado() {
    final h = hallazgos;
    if (h == null) return const [];
    if (h.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: _hueco),
          child: Text('Sin diferencias con el plan.'),
        ),
      ];
    }
    return [for (final x in h) _TarjetaHallazgo(x)];
  }
}

class _TarjetaHallazgo extends StatelessWidget {
  const _TarjetaHallazgo(this.h);

  final Hallazgo h;

  @override
  Widget build(BuildContext context) {
    final (etiqueta, color) =
        h.gravedad == Gravedad.critico
            ? ('CRÍTICO', Theme.of(context).colorScheme.error)
            : ('AVISO', NetworkTheme.amberAlert);
    return Card(
      margin: const EdgeInsets.only(top: _hueco),
      child: Padding(
        padding: const EdgeInsets.all(_hueco),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: TextStyle(color: color)),
            Text(h.mensaje),
            for (final c in h.correccion) SelectableText(c, style: _consola),
          ],
        ),
      ),
    );
  }
}
