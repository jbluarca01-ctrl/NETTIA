import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import '../logic/ipv4_subnetting.dart';

const TextStyle _mono = TextStyle(
  fontFamilyFallback: kMonoFallback,
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
);

/// Tarjeta de sección con título, usada por las pestañas de la calculadora.
class SeccionCalculadora extends StatelessWidget {
  const SeccionCalculadora({
    super.key,
    required this.titulo,
    required this.icono,
    required this.hijos,
  });

  final String titulo;
  final IconData icono;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icono, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...hijos,
          ],
        ),
      ),
    );
  }
}

/// Mensaje de error de validación (rojo, con ícono).
class MensajeError extends StatelessWidget {
  const MensajeError(this.mensaje, {super.key});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: color, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

/// Fila "etiqueta: valor" con el valor seleccionable.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            flex: 4,
            child: Text(etiqueta,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 6,
            child:
                SelectableText(valor, textAlign: TextAlign.end, style: _mono),
          ),
        ],
      ),
    );
  }
}

/// Pasos del cálculo y avisos, para mostrar cómo se llegó a la respuesta.
class PasosYAvisos extends StatelessWidget {
  const PasosYAvisos({super.key, required this.pasos, this.avisos = const []});
  final List<String> pasos;
  final List<String> avisos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final a in avisos)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(NettiaIcons.aviso,
                    size: 16, color: NetworkTheme.amberAlert),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(a, style: const TextStyle(fontSize: 12.5))),
              ],
            ),
          ),
        if (pasos.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text('Cómo se calcula (paso a paso)',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            children: <Widget>[
              for (final p in pasos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(p,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Tabla de subredes IPv4 con desplazamiento horizontal y botón de copiar.
/// Las filas a partir de [primerasUsadas] se atenúan (subredes libres).
class TablaSubredesIpv4 extends StatelessWidget {
  const TablaSubredesIpv4({
    super.key,
    required this.subredes,
    this.primerasUsadas,
  });

  final List<SubredIpv4> subredes;
  final int? primerasUsadas;

  String _comoTexto() {
    final b = StringBuffer(
        '#\tRed\tMáscara\tGateway\tPrimer host\tÚltimo host\tBroadcast\tHosts\n');
    for (final s in subredes) {
      b.writeln('${s.nombre ?? s.indice}\t${s.red}/${s.cidr}\t${s.mascara}\t'
          '${s.gateway}\t${s.primerHost}\t${s.ultimoHost}\t${s.broadcast}\t'
          '${s.hostsUtiles}');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final conNombre = subredes.any((s) => s.nombre != null);
    final tenue = Theme.of(context).disabledColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(NettiaIcons.copiar, size: 16),
            label: const Text('Copiar tabla'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _comoTexto()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Tabla copiada'),
                  behavior: SnackBarBehavior.floating,
                ));
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 36,
            dataRowMinHeight: 34,
            dataRowMaxHeight: 40,
            columns: <DataColumn>[
              DataColumn(label: Text(conNombre ? 'Red' : '#')),
              const DataColumn(label: Text('Subred')),
              const DataColumn(label: Text('Máscara')),
              const DataColumn(label: Text('Gateway')),
              const DataColumn(label: Text('Primer host')),
              const DataColumn(label: Text('Último host')),
              const DataColumn(label: Text('Broadcast')),
              const DataColumn(label: Text('Hosts'), numeric: true),
            ],
            rows: <DataRow>[
              for (final s in subredes)
                DataRow(
                  cells: <DataCell>[
                    for (final t in <String>[
                      s.nombre ?? '${s.indice}',
                      '${s.red}/${s.cidr}',
                      s.mascara,
                      s.gateway,
                      s.primerHost,
                      s.ultimoHost,
                      s.broadcast,
                      '${s.hostsUtiles}',
                    ])
                      DataCell(SelectableText(
                        t,
                        style: (primerasUsadas != null &&
                                s.indice > primerasUsadas!)
                            ? _mono.copyWith(color: tenue)
                            : _mono,
                      )),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
