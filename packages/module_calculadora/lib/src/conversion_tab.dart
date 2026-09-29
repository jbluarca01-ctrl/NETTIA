import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/conversiones.dart';
import 'widgets/resultado_widgets.dart';

InputDecoration _dec(String etiqueta, {String? pista}) => InputDecoration(
      labelText: etiqueta,
      hintText: pista,
      border: const OutlineInputBorder(),
      isDense: true,
    );

const TextStyle _mono = TextStyle(fontFamilyFallback: kMonoFallback, fontSize: 14);

/// Pestaña "Conversión": máscara/wildcard/prefijo, bases numéricas y
/// sumarización de rutas.
class ConversionTab extends StatefulWidget {
  const ConversionTab({super.key});

  @override
  State<ConversionTab> createState() => _ConversionTabState();
}

class _ConversionTabState extends State<ConversionTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _mascara = TextEditingController(text: '/26');
  final TextEditingController _numero = TextEditingController(text: '192');
  int _base = 10;
  final TextEditingController _redes = TextEditingController(
    text: '192.168.0.0/24\n192.168.1.0/24\n192.168.2.0/24\n192.168.3.0/24',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mascara.dispose();
    _numero.dispose();
    _redes.dispose();
    super.dispose();
  }

  Widget _bloqueMascara() {
    try {
      final c = convertirMascara(_mascara.text);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          FilaDato('Prefijo:', '/${c.prefijo}'),
          FilaDato('Máscara:', c.mascara),
          FilaDato('Wildcard (ACL/OSPF):', c.wildcard),
          FilaDato('Hosts útiles:', '${c.hosts}'),
        ],
      );
    } on ConversionException catch (e) {
      return MensajeError(e.mensaje);
    }
  }

  Widget _bloqueNumero() {
    try {
      final n = convertirNumero(_numero.text, _base);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          FilaDato('Decimal:', '${n.decimal}'),
          FilaDato('Binario:', n.binario),
          FilaDato('Hexadecimal:', n.hexadecimal),
        ],
      );
    } on ConversionException catch (e) {
      return MensajeError(e.mensaje);
    }
  }

  Widget _bloqueSumarizacion() {
    final lineas = _redes.text
        .split(RegExp(r'[\n,;]'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    try {
      final r = sumarizarRedes(lineas);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          FilaDato('Ruta resumen:', '${r.red}/${r.prefijo}'),
          FilaDato('Máscara:', r.mascara),
          FilaDato('¿Resumen exacto?', r.exacta ? 'Sí' : 'No (sobran ${r.direccionesSobrantes})'),
          const SizedBox(height: 6),
          PasosYAvisos(pasos: r.pasos),
        ],
      );
    } on ConversionException catch (e) {
      return MensajeError(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SeccionCalculadora(
            titulo: 'Prefijo, máscara y wildcard',
            icono: NettiaIcons.calculadora,
            hijos: <Widget>[
              TextField(
                controller: _mascara,
                style: _mono,
                decoration: _dec('Prefijo, máscara o wildcard',
                    pista: '/24, 255.255.255.0 o 0.0.0.255'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              _bloqueMascara(),
            ],
          ),
          const SizedBox(height: 12),
          SeccionCalculadora(
            titulo: 'Decimal, binario y hexadecimal',
            icono: NettiaIcons.comandos,
            hijos: <Widget>[
              SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 10, label: Text('Dec')),
                  ButtonSegment<int>(value: 2, label: Text('Bin')),
                  ButtonSegment<int>(value: 16, label: Text('Hex')),
                ],
                selected: <int>{_base},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _base = s.first),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _numero,
                style: _mono,
                decoration: _dec('Número (en la base elegida)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              _bloqueNumero(),
            ],
          ),
          const SizedBox(height: 12),
          SeccionCalculadora(
            titulo: 'Sumarizar rutas',
            icono: NettiaIcons.diagrama,
            hijos: <Widget>[
              TextField(
                controller: _redes,
                minLines: 3,
                maxLines: 8,
                style: _mono,
                decoration: _dec('Una red por línea (a.b.c.d/n)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              _bloqueSumarizacion(),
            ],
          ),
        ],
      ),
    );
  }
}
