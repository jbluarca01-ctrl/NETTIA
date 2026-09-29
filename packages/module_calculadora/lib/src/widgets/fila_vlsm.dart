import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import '../logic/ipv4_subnetting.dart';

/// Una fila editable de "Nombre" + "Hosts", reutilizada por VLSM y por
/// "Dividir → Tamaños personalizados" (ambos asignan a cada fila el bloque
/// más pequeño que le alcanza según sus hosts).
class FilaVlsm {
  FilaVlsm(String nombre, String hosts)
      : nombre = TextEditingController(text: nombre),
        hosts = TextEditingController(text: hosts);
  final TextEditingController nombre;
  final TextEditingController hosts;
  void dispose() {
    nombre.dispose();
    hosts.dispose();
  }
}

/// Quita `filas[indice]`, notifica el cambio y libera sus controladores tras
/// el cuadro (el campo aún los usa en este cuadro). Compartido por VLSM y
/// Dividir → Tamaños personalizados.
void quitarFilaVlsm(
    List<FilaVlsm> filas, int indice, VoidCallback notificarCambio) {
  final fila = filas.removeAt(indice);
  notificarCambio();
  WidgetsBinding.instance.addPostFrameCallback((_) => fila.dispose());
}

/// Filas de ejemplo por defecto (100/50/25 hosts), usadas como estado
/// inicial tanto por VLSM como por "Dividir → Tamaños personalizados".
List<FilaVlsm> filasVlsmDeEjemplo() => <FilaVlsm>[
      FilaVlsm('LAN 1', '100'),
      FilaVlsm('LAN 2', '50'),
      FilaVlsm('LAN 3', '25'),
    ];

/// Libera los controladores de todas las [filas].
void disposeFilasVlsm(List<FilaVlsm> filas) {
  for (final f in filas) {
    f.dispose();
  }
}

/// Construye los [RequerimientoVlsm] a partir de las filas escritas,
/// ignorando las que aún no tienen un número de hosts válido.
List<RequerimientoVlsm> requerimientosDesde(List<FilaVlsm> filas) {
  final reqs = <RequerimientoVlsm>[];
  for (var i = 0; i < filas.length; i++) {
    final hosts = int.tryParse(filas[i].hosts.text.trim());
    if (hosts == null) continue;
    final nombre = filas[i].nombre.text.trim();
    reqs.add(RequerimientoVlsm(nombre.isEmpty ? 'Red ${i + 1}' : nombre, hosts));
  }
  return reqs;
}

/// Campo de texto numérico denso (solo dígitos, hasta 7 caracteres),
/// reutilizado por "Hosts" en [FilaVlsmRow] y por la cantidad/hosts de
/// "Dividir".
class CampoNumeroDenso extends StatelessWidget {
  const CampoNumeroDenso({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(7),
      ],
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

/// Fila visual de una [FilaVlsm]: nombre, hosts y botón de quitar.
class FilaVlsmRow extends StatelessWidget {
  const FilaVlsmRow({
    super.key,
    required this.fila,
    required this.onChanged,
    required this.onQuitar,
  });

  final FilaVlsm fila;
  final VoidCallback onChanged;

  /// Null deshabilita el botón (ej. cuando solo queda una fila).
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: TextField(
              controller: fila.nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: CampoNumeroDenso(
              controller: fila.hosts,
              labelText: 'Hosts',
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onQuitar,
          ),
        ],
      ),
    );
  }
}

/// Fila con el campo de red (IPv4) y el dropdown de prefijo (/1 a /29),
/// reutilizada por "Dividir" y "VLSM".
class RedYPrefijoRow extends StatelessWidget {
  const RedYPrefijoRow({
    super.key,
    required this.ip,
    required this.etiquetaIp,
    required this.cidr,
    required this.onIpChanged,
    required this.onCidrChanged,
  });

  final TextEditingController ip;
  final String etiquetaIp;
  final int cidr;
  final VoidCallback onIpChanged;
  final ValueChanged<int> onCidrChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: TextField(
            controller: ip,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              LengthLimitingTextInputFormatter(15),
            ],
            style: const TextStyle(
                fontFamilyFallback: kMonoFallback, fontSize: 14),
            decoration: InputDecoration(
              labelText: etiquetaIp,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => onIpChanged(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            initialValue: cidr,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Prefijo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: <DropdownMenuItem<int>>[
              for (var c = 1; c <= 29; c++)
                DropdownMenuItem<int>(value: c, child: Text('/$c')),
            ],
            onChanged: (nuevo) => onCidrChanged(nuevo ?? cidr),
          ),
        ),
      ],
    );
  }
}

/// Sección "Redes y hosts que necesita cada una": la lista de [FilaVlsm]
/// editables más el botón "Agregar red". Reutilizada por "Dividir →
/// Tamaños personalizados" y "VLSM".
class ListaFilasVlsm extends StatelessWidget {
  const ListaFilasVlsm({
    super.key,
    required this.filas,
    required this.onChanged,
    required this.onQuitar,
    required this.onAgregar,
  });

  final List<FilaVlsm> filas;
  final VoidCallback onChanged;
  final void Function(int indice) onQuitar;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Redes y hosts que necesita cada una:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (var i = 0; i < filas.length; i++)
          KeyedSubtree(
            key: ObjectKey(filas[i]),
            child: FilaVlsmRow(
              fila: filas[i],
              onChanged: onChanged,
              onQuitar: filas.length <= 1 ? null : () => onQuitar(i),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar red'),
            onPressed: onAgregar,
          ),
        ),
      ],
    );
  }
}

/// Estado y wiring de una lista de [FilaVlsm] (filas de ejemplo, dispose,
/// agregar/quitar y el widget ya armado), reutilizados por VLSM y por
/// "Dividir → Tamaños personalizados" para no duplicar esa lógica.
mixin FilasVlsmState<T extends StatefulWidget> on State<T> {
  final List<FilaVlsm> filasVlsm = filasVlsmDeEjemplo();

  void disposeFilas() => disposeFilasVlsm(filasVlsm);

  void _quitarFilaVlsm(int i) =>
      quitarFilaVlsm(filasVlsm, i, () => setState(() {}));

  void _agregarFilaVlsm() => setState(
      () => filasVlsm.add(FilaVlsm('LAN ${filasVlsm.length + 1}', '')));

  Widget construirListaFilasVlsm() => ListaFilasVlsm(
        filas: filasVlsm,
        onChanged: () => setState(() {}),
        onQuitar: _quitarFilaVlsm,
        onAgregar: _agregarFilaVlsm,
      );
}
