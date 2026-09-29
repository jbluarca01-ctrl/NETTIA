import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../nettia_icons.dart';
import '../syntax/ios_syntax.dart';
import '../theme/network_theme.dart';

/// Bloque de código estilo editor: semáforo, etiqueta de lenguaje, números de
/// línea, colores One Dark Pro, guías de sangría estilo indent-rainbow y
/// botón de copiar. Siempre oscuro (como un editor), en ambos temas.
class EditorCodeBlock extends StatelessWidget {
  const EditorCodeBlock({
    super.key,
    required this.code,
    this.lenguaje = 'cisco-ios',
  });

  final String code;

  /// Etiqueta que se muestra en la barra superior.
  final String lenguaje;

  void _copiar(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Comando copiado'),
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _barra(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      color: Colors.white.withValues(alpha: 0.05),
      child: Row(
        children: <Widget>[
          for (final c in const <Color>[
            NetworkTheme.redDown,
            NetworkTheme.amberAlert,
            NetworkTheme.ledGreen,
          ])
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(shape: BoxShape.circle, color: c),
            ),
          const SizedBox(width: 6),
          Text(lenguaje, style: NetworkTheme.mono(size: 11, color: NetworkTheme.inkMuted)),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 32),
            visualDensity: VisualDensity.compact,
            icon: const Icon(NettiaIcons.copiar, size: 18),
            color: NetworkTheme.inkMuted,
            tooltip: 'Copiar',
            onPressed: () => _copiar(context),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo(List<String> lineas, TextStyle base, TextStyle numeros) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (var i = 1; i <= lineas.length; i++) Text('$i', style: numeros),
              ],
            ),
            const SizedBox(width: 14),
            SelectableText.rich(
              TextSpan(
                style: base,
                children: <InlineSpan>[
                  for (var i = 0; i < lineas.length; i++) ...<InlineSpan>[
                    ...resaltarIos(lineas[i], base),
                    if (i < lineas.length - 1) const TextSpan(text: '\n'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineas = code.trimRight().split('\n');
    final base = NetworkTheme.mono(size: 12.5, color: OneDark.fg);
    final numeros = NetworkTheme.mono(size: 12.5, color: NetworkTheme.inkMuted);

    return Container(
      decoration: BoxDecoration(
        color: NetworkTheme.ink,
        borderRadius: BorderRadius.circular(NetworkTheme.radiusMd),
        border: Border.all(color: NetworkTheme.darkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _barra(context),
          _cuerpo(lineas, base, numeros),
        ],
      ),
    );
  }
}
