import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nettia_core/nettia_core.dart';

/// Respuesta de NETIA: bloques ``` con el editor de código propio (colores
/// One Dark) y el resto del texto como Markdown real — tablas, negrita,
/// código en línea, encabezados y listas — no solo negrita/código a mano.
class RespuestaFormateada extends StatelessWidget {
  const RespuestaFormateada({super.key, required this.texto});

  final String texto;

  MarkdownStyleSheet _hojaEstilos(BuildContext context) {
    final theme = Theme.of(context);
    const base = TextStyle(fontSize: 14, height: 1.5);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: base,
      listBullet: base,
      code: NetworkTheme.mono(
        size: 12.5,
        color: OneDark.iface,
      ).copyWith(backgroundColor: Colors.white.withValues(alpha: 0.08)),
      tableHead: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      tableBody: const TextStyle(fontSize: 13),
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.4),
        width: 0.8,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      tableColumnWidth: const IntrinsicColumnWidth(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partes = texto.split('```');
    final hijos = <Widget>[];
    for (var i = 0; i < partes.length; i++) {
      final esCodigo = i.isOdd;
      final trozo = partes[i];
      if (esCodigo) {
        final nl = trozo.indexOf('\n');
        final lenguaje = nl == -1
            ? trozo.trim()
            : trozo.substring(0, nl).trim();
        final codigo = nl == -1 ? '' : trozo.substring(nl + 1);
        if (codigo.trim().isEmpty) continue;
        hijos.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: EditorCodeBlock(
              code: codigo,
              lenguaje: lenguaje.isEmpty ? 'cisco-ios' : lenguaje,
            ),
          ),
        );
      } else {
        final textoLimpio = trozo.trim();
        if (textoLimpio.isEmpty) continue;
        hijos.add(
          MarkdownBody(
            data: textoLimpio,
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubWeb,
            styleSheet: _hojaEstilos(context),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hijos,
    );
  }
}
