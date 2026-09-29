import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

/// Texto de la insignia según el nivel de verificación de los fragmentos que
/// respaldaron la respuesta.
String textoInsignia(List<FuenteLocalUsada> fuentes) {
  final conComandos = fuentes.where((f) => f.tieneComandos).toList();
  if (conComandos.isNotEmpty && conComandos.every((f) => f.comandosProbados)) {
    return 'Base local · comandos probados en equipo';
  }
  if (conComandos.isNotEmpty) {
    return 'Base local · verificado con documentación oficial · comandos NO probados en equipo';
  }
  return 'Base local · verificado con fuentes cruzadas';
}

/// Pie de una respuesta apoyada en la base local: insignia de verificación y
/// botones para decir si funcionó. Los comentarios se guardan en el teléfono
/// ([FeedbackService]); el usuario decide si los envía al autor.
class PieVerificacion extends StatefulWidget {
  const PieVerificacion({super.key, required this.fuentes, required this.pregunta});

  final List<FuenteLocalUsada> fuentes;
  final String pregunta;

  @override
  State<PieVerificacion> createState() => _PieVerificacionState();
}

class _PieVerificacionState extends State<PieVerificacion> {
  VeredictoFragmento? _dado;

  Future<void> _votar(VeredictoFragmento v) async {
    var nota = '';
    if (v == VeredictoFragmento.noFunciono) {
      final escrita = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final c = TextEditingController();
          return AlertDialog(
            title: const Text('¿Qué falló?'),
            content: TextField(
              controller: c,
              maxLength: 160,
              decoration: const InputDecoration(
                hintText: 'Opcional: qué comando dio error o qué no coincidió',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(''),
                child: const Text('Omitir'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
      if (escrita == null) return; // cerró el diálogo: no se guarda
      nota = escrita;
    }
    final ahora = DateTime.now();
    for (final f in widget.fuentes) {
      await FeedbackService.instance.registrar(EntradaFeedback(
        fecha: ahora,
        fragmentoId: f.id,
        veredicto: v,
        pregunta: widget.pregunta,
        nota: nota,
      ));
    }
    if (mounted) setState(() => _dado = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenue = theme.textTheme.bodyMedium?.color?.withAlpha(150);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(NettiaIcons.validado, size: 14, color: tenue),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  textoInsignia(widget.fuentes),
                  style: TextStyle(fontSize: 11.5, color: tenue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_dado != null)
            Text(
              '✔ Gracias, guardado: ${_dado!.etiqueta}',
              style: TextStyle(fontSize: 11.5, color: tenue),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 0,
              children: <Widget>[
                for (final v in VeredictoFragmento.values)
                  ActionChip(
                    label: Text(v.etiqueta, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _votar(v),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
