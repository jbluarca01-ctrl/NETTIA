import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/ipv4_subnetting.dart' show maxSubredesListadas;
import 'logic/ipv6.dart';
import 'widgets/resultado_widgets.dart';

const TextStyle _mono = TextStyle(
  fontFamilyFallback: kMonoFallback,
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
);

InputDecoration _decoracion(String etiqueta, {String? pista}) => InputDecoration(
      labelText: etiqueta,
      hintText: pista,
      border: const OutlineInputBorder(),
      isDense: true,
    );

final List<TextInputFormatter> _soloHex = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:]')),
  LengthLimitingTextInputFormatter(39),
];

/// Pestaña "IPv6": analizar una dirección, generar EUI-64 y subnetear.
class Ipv6Tab extends StatefulWidget {
  const Ipv6Tab({super.key});

  @override
  State<Ipv6Tab> createState() => _Ipv6TabState();
}

class _Ipv6TabState extends State<Ipv6Tab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _dir =
      TextEditingController(text: '2001:0db8:0000:0000:0000:ff00:0042:8329');

  final TextEditingController _prefijoEui = TextEditingController(text: '2001:db8:acad:1::');
  final TextEditingController _mac = TextEditingController(text: '00:1A:2B:3C:4D:5E');

  final TextEditingController _redSub = TextEditingController(text: '2001:db8:acad::');
  int _prefOrig = 48;
  int _prefNuevo = 64;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _dir.dispose();
    _prefijoEui.dispose();
    _mac.dispose();
    _redSub.dispose();
    super.dispose();
  }

  Widget _analisis() {
    try {
      final a = Ipv6.parse(_dir.text);
      final t = clasificarIpv6(a);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          FilaDato('Abreviada:', a.abreviada),
          FilaDato('Completa:', a.expandida),
          FilaDato('Tipo:', t.nombre),
          FilaDato('Prefijo del tipo:', t.prefijo),
          const SizedBox(height: 4),
          Text(t.descripcion, style: const TextStyle(fontSize: 12.5)),
        ],
      );
    } on Ipv6Exception catch (e) {
      return MensajeError(e.mensaje);
    }
  }

  Widget _eui64() {
    try {
      final base = Ipv6.parse(_prefijoEui.text);
      final dir = direccionEui64(base, _mac.text);
      final id = eui64DesdeMac(_mac.text)
          .map((g) => g.toRadixString(16).padLeft(4, '0'))
          .join(':');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          FilaDato('ID de interfaz (EUI-64):', id),
          FilaDato('Dirección completa:', dir.abreviada),
          const SizedBox(height: 4),
          const Text(
            'Se inserta fffe en medio de la MAC y se invierte el 7.º bit del '
            'primer byte (universal/local). Se usan los 64 bits altos del '
            'prefijo escrito.',
            style: TextStyle(fontSize: 12.5),
          ),
        ],
      );
    } on Ipv6Exception catch (e) {
      return MensajeError(e.mensaje);
    }
  }

  Widget _subneteo() {
    try {
      final d = subnetearIpv6(_redSub.text, _prefOrig, _prefNuevo,
          maxMostrar: maxSubredesListadas);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Divider(),
          FilaDato('Red original:',
              '${d.redOriginal.abreviada}/${d.prefijoOriginal}'),
          FilaDato('Subredes /${d.nuevoPrefijo}:', '${d.totalSubredes}'),
          const SizedBox(height: 6),
          PasosYAvisos(pasos: d.pasos, avisos: d.avisos),
          const SizedBox(height: 4),
          Text(
            d.totalSubredes > BigInt.from(d.primeras.length)
                ? 'Primeras ${d.primeras.length} subredes:'
                : 'Subredes:',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          for (final s in d.primeras)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText('${s.indice}.  ${s.red.abreviada}/${s.prefijo}',
                  style: _mono),
            ),
        ],
      );
    } on Ipv6Exception catch (e) {
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
            titulo: 'Analizar una dirección IPv6',
            icono: NettiaIcons.calculadora,
            hijos: <Widget>[
              TextField(
                controller: _dir,
                inputFormatters: _soloHex,
                style: _mono.copyWith(fontSize: 14),
                decoration: _decoracion('Dirección IPv6', pista: '2001:db8::1'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              _analisis(),
            ],
          ),
          const SizedBox(height: 12),
          SeccionCalculadora(
            titulo: 'EUI-64 desde una MAC',
            icono: NettiaIcons.router,
            hijos: <Widget>[
              TextField(
                controller: _prefijoEui,
                inputFormatters: _soloHex,
                style: _mono.copyWith(fontSize: 14),
                decoration: _decoracion('Prefijo /64', pista: '2001:db8:acad:1::'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mac,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:.\-]')),
                  LengthLimitingTextInputFormatter(17),
                ],
                style: _mono.copyWith(fontSize: 14),
                decoration: _decoracion('Dirección MAC', pista: '00:1A:2B:3C:4D:5E'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              _eui64(),
            ],
          ),
          const SizedBox(height: 12),
          SeccionCalculadora(
            titulo: 'Subnetear un prefijo IPv6',
            icono: NettiaIcons.diagrama,
            hijos: <Widget>[
              TextField(
                controller: _redSub,
                inputFormatters: _soloHex,
                style: _mono.copyWith(fontSize: 14),
                decoration: _decoracion('Red', pista: '2001:db8:acad::'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _prefOrig,
                      isExpanded: true,
                      decoration: _decoracion('Prefijo actual'),
                      items: <DropdownMenuItem<int>>[
                        for (var p = 16; p <= 120; p += 4)
                          DropdownMenuItem<int>(value: p, child: Text('/$p')),
                      ],
                      onChanged: (v) => setState(() => _prefOrig = v ?? _prefOrig),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _prefNuevo,
                      isExpanded: true,
                      decoration: _decoracion('Nuevo prefijo'),
                      items: <DropdownMenuItem<int>>[
                        for (var p = 16; p <= 128; p += 4)
                          DropdownMenuItem<int>(value: p, child: Text('/$p')),
                      ],
                      onChanged: (v) => setState(() => _prefNuevo = v ?? _prefNuevo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _subneteo(),
            ],
          ),
        ],
      ),
    );
  }
}
