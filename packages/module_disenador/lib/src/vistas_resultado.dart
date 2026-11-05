import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/auditor.dart';
import 'logic/formulario.dart';
import 'logic/generador.dart';
import 'logic/multisede.dart';
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
      const Padding(
        padding: EdgeInsets.only(bottom: _hueco),
        child: Text(
          'El gateway ocupa una dirección del bloque: 6 PC necesitan 7 '
          'direcciones y no caben en un /29 (6 útiles), por eso salen en un /28.',
        ),
      ),
      if (d.red case final red?) ..._planMultisede(context, red) else ..._planSede(d.plan),
    ],
  );
}

/// Los segmentos de una sede y lo que queda libre en su red base.
List<Widget> _planSede(PlanRed p) => [
  for (final s in p.segmentos) _TarjetaSegmento(s),
  Text('Quedan ${p.direccionesLibres} direcciones libres en la red base.'),
  for (final aviso in p.avisos) Text(aviso),
];

/// Nombre del [e] en pantalla (SPEC-003 T4).
String nombreEnrutamiento(Enrutamiento e) => switch (e) {
  Enrutamiento.estaticaResumida => 'Estática resumida',
  Enrutamiento.estaticaPorSubred => 'Estática por subred',
  Enrutamiento.ospf => 'OSPF',
};

/// Cuándo usar cada enrutamiento (nota pedida el 2026-11-04), debajo del
/// selector del Diseñador.
const notaEnrutamiento = [
  'Si el enunciado dice qué enrutamiento usar, usa ese.',
  'Estática resumida: 2 o 3 routers y las redes de cada sede son contiguas. Una sola ruta por sede.',
  'Estática por subred: las redes de una sede no se pueden resumir, o el ejercicio pide una ruta por cada red.',
  'OSPF: 4 o más routers, una red que va a crecer, o el enunciado pide enrutamiento dinámico. Los routers aprenden las redes solos.',
];

/// La [notaEnrutamiento] con su título, en letra chica.
Widget vistaNotaEnrutamiento(ThemeData tema) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('¿Cuál elegir?', style: tema.textTheme.labelLarge),
    for (final linea in notaEnrutamiento) Text(linea, style: tema.textTheme.bodySmall),
  ],
);

/// Con varios routers (SPEC-003 RF15): el plan de cada sede con su
/// resumen, los enlaces entre routers y el enrutamiento.
List<Widget> _planMultisede(BuildContext context, RedMultisede red) {
  final titulo = Theme.of(context).textTheme.titleMedium;
  return [
    for (var i = 0; i < red.sedes.length; i++) ...[
      Text(_tituloSede(red, i), style: titulo),
      ..._planSede(red.sedes[i]),
      const SizedBox(height: _hueco),
    ],
    Text('Enlaces entre routers', style: titulo),
    for (final e in red.enlaces) Text('R${e.desde + 1} ${e.ipDesde} ↔ R${e.desde + 2} ${e.ipHasta} · red ${e.red}/30'),
    Text('Enrutamiento: ${nombreEnrutamiento(red.enrutamiento)}'),
  ];
}

String _tituloSede(RedMultisede red, int i) {
  final p = red.sedes[i];
  final (resumen, prefijo) = resumenDe(p);
  return 'Sede ${i + 1} (R${i + 1}) · ${p.redBase}/${p.cidrBase} · resumen $resumen/$prefijo';
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
          Text(s.explicacion),
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
      campoPegado(texto, 'running-config'),
      const SizedBox(height: _hueco),
      FilledButton(
        onPressed: () => onAuditar(d.planPara(texto.text)),
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
    return [for (final x in h) TarjetaHallazgo(x)];
  }
}

/// Cuadro donde se pega lo que muestra un equipo (Auditar y el doctor).
Widget campoPegado(TextEditingController texto, String etiqueta) => TextField(
  key: const ValueKey('auditar_texto'),
  controller: texto,
  minLines: 6,
  maxLines: 14,
  style: _consola,
  decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder()),
);

/// Un hallazgo del auditor: gravedad, mensaje y comandos que lo corrigen.
class TarjetaHallazgo extends StatelessWidget {
  const TarjetaHallazgo(this.h, {super.key});

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
