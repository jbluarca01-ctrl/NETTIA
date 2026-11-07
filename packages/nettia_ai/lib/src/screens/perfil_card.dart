import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

/// Tarjeta "Perfil de uso": elige entre Estudiante y Profesional.
class PerfilCard extends StatelessWidget {
  const PerfilCard({super.key, required this.isDark});

  final bool isDark;

  /// Cambia el perfil tras confirmar: recarga el menú, el corpus y el tono
  /// del asistente.
  Future<void> _cambiarPerfil(BuildContext context, UserProfile nuevo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar de perfil'),
        content: Text(
          'Pasarás al perfil ${nuevo.etiqueta}. El menú y el tono del '
          'asistente se ajustarán a ese perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
    if (confirmado == true) await UserProfileService.instance.setProfile(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final perfil = UserProfileService.instance.profile ?? UserProfile.estudiante;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<UserProfile>(
              segments: [
                for (final p in UserProfile.values)
                  ButtonSegment(
                    value: p,
                    label: Text(p.etiqueta),
                    icon: Icon(
                      p == UserProfile.estudiante ? NettiaIcons.estudiante : NettiaIcons.profesional,
                      size: 16,
                    ),
                  ),
              ],
              selected: {perfil},
              showSelectedIcon: false,
              onSelectionChanged: (sel) => _cambiarPerfil(context, sel.first),
            ),
            const SizedBox(height: 10),
            Text(
              perfil.descripcion,
              style: TextStyle(fontSize: 12.5, color: isDark ? NetworkTheme.darkTextSecondary : NetworkTheme.lightTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
