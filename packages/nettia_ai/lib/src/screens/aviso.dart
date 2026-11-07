import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

/// Resultado de una acción: mensaje emergente (no queda fijo en pantalla).
/// Los mensajes que empiezan con ✅ se pintan en verde.
void avisar(BuildContext context, String mensaje) {
  final ok = mensaje.startsWith('✅');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            ok ? NetworkTheme.ledGreen.withValues(alpha: 0.95) : null,
        duration: const Duration(seconds: 3),
      ),
    );
}
