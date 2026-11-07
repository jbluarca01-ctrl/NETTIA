import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import 'aviso.dart';

/// Tarjeta "Comentarios sobre las respuestas": copia o borra el reporte local.
class ComentariosCard extends StatelessWidget {
  const ComentariosCard({super.key});

  Future<void> _copiarReporte(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: FeedbackService.instance.reporte()));
    if (context.mounted) avisar(context, '✅ Reporte copiado. Pégalo en un mensaje para el autor.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: FeedbackService.instance,
        builder: (context, _) => _tarjeta(context),
      );

  Widget _tarjeta(BuildContext context) {
    final vacio = FeedbackService.instance.entradas.isEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guardados en este teléfono: ${FeedbackService.instance.entradas.length}. Son tus "Me funcionó / No funcionó / Lo probé en Packet Tracer" sobre la base local. Nada se envía solo: si quieres, copia el reporte y mándaselo al autor.',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(NettiaIcons.copiar, size: 16),
                  label: const Text('Copiar reporte'),
                  onPressed: vacio ? null : () => _copiarReporte(context),
                ),
                TextButton(
                  onPressed: vacio ? null : () => FeedbackService.instance.borrarTodo(),
                  child: const Text('Borrar comentarios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
