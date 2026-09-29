import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

/// Lista de conversaciones guardadas de NETIA. Al tocar una, se cierra
/// devolviendo esa [Conversacion] para que la pantalla del asistente la
/// recargue.
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de conversaciones')),
      body: ListenableBuilder(
        listenable: HistorialConversacionesService.instance,
        builder: (context, _) {
          final conversaciones = HistorialConversacionesService.instance.conversaciones;
          if (conversaciones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tienes conversaciones guardadas. Se guardan solas '
                  'a medida que hablas con NETIA.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: conversaciones.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = conversaciones[i];
              return ListTile(
                title: Text(c.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${_fechaCorta(c.fecha)} · ${c.mensajes.length} mensajes',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar',
                  onPressed: () async {
                    await HistorialConversacionesService.instance.eliminar(c.id);
                  },
                ),
                onTap: () => Navigator.of(context).pop(c),
              );
            },
          );
        },
      ),
    );
  }
}
