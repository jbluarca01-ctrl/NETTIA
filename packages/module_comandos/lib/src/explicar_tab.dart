import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/explicador_show.dart';

/// Pestaña "Explicar salida": pegas la salida de un `show` y la app explica
/// cada línea y señala lo que hay que revisar.
class ExplicarSalidaTab extends StatefulWidget {
  const ExplicarSalidaTab({super.key});

  @override
  State<ExplicarSalidaTab> createState() => _ExplicarSalidaTabState();
}

class _ExplicarSalidaTabState extends State<ExplicarSalidaTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _texto = TextEditingController();
  ExplicacionShow? _explicacion;
  bool _explicado = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _explicar() {
    setState(() {
      _explicacion = explicarSalidaShow(_texto.text);
      _explicado = true;
    });
  }

  Future<void> _pegar() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    if (datos?.text == null || !mounted) return;
    _texto.text = datos!.text!;
    _explicar();
  }

  (IconData, Color) _estilo(Nivel n) => switch (n) {
        Nivel.ok => (NettiaIcons.validado, NetworkTheme.ledGreen),
        Nivel.aviso => (NettiaIcons.aviso, NetworkTheme.amberAlert),
        Nivel.problema => (NettiaIcons.aviso, Theme.of(context).colorScheme.error),
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final e = _explicacion;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          Text(
            'Pega aquí la salida de un comando show',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Reconoce: show ip interface brief · show vlan brief · show ip ospf neighbor. '
            'No se envía a ningún lado: se analiza en tu teléfono.',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(170),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _texto,
            minLines: 6,
            maxLines: 14,
            style: const TextStyle(fontFamilyFallback: kMonoFallback, fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Router# show ip interface brief\nInterface  IP-Address  OK? Method Status  Protocol\n…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: _explicar,
                  child: const Text('Explicar'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(NettiaIcons.copiar, size: 16),
                label: const Text('Pegar y explicar'),
                onPressed: _pegar,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_explicado && e == null)
            Text(
              'No reconozco ese texto. Copia la salida completa de show ip interface brief, show vlan brief o show ip ospf neighbor, incluida la fila de encabezados.',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          if (e != null) ...<Widget>[
            Text(
              '${e.tipo.comando}: ${e.resumen}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            for (final h in e.hallazgos)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(_estilo(h.nivel).$1, size: 18, color: _estilo(h.nivel).$2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SelectableText(
                              h.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFamilyFallback: kMonoFallback,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SelectableText(h.detalle, style: const TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Son causas frecuentes, no un diagnóstico definitivo: confirma con `show interfaces`, `show running-config` y la topología.',
              style: TextStyle(
                fontSize: 11.5,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
