import 'package:flutter/material.dart';

import '../nettia_icons.dart';
import '../theme/network_theme.dart';
import '../widgets/nettia_logo.dart';
import 'user_profile.dart';

/// Primera pantalla de la app (antes del splash y del menú): el usuario elige
/// si es estudiante o profesional. Sin AppBar, sin menú y sin fondo animado.
class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key, required this.onSelected});

  /// Se llama tras guardar el perfil elegido.
  final VoidCallback onSelected;

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  bool _guardando = false;

  Future<void> _elegir(UserProfile perfil) async {
    if (_guardando) return;
    setState(() => _guardando = true);
    await UserProfileService.instance.setProfile(perfil);
    if (!mounted) return;
    widget.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._Encabezado(theme: theme).children,
                  _OpcionPerfil(
                    icono: NettiaIcons.estudiante,
                    perfil: UserProfile.estudiante,
                    color: theme.colorScheme.primary,
                    onTap: () => _elegir(UserProfile.estudiante),
                  ),
                  const SizedBox(height: 12),
                  _OpcionPerfil(
                    icono: NettiaIcons.profesional,
                    perfil: UserProfile.profesional,
                    color: theme.colorScheme.tertiary,
                    onTap: () => _elegir(UserProfile.profesional),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo, título y subtítulo de la pantalla de selección de perfil. No es un
/// widget independiente en el árbol (solo agrupa sus hijos): así `build` de
/// [_ProfileSelectionScreenState] se mantiene bajo el máximo de líneas.
class _Encabezado {
  const _Encabezado({required this.theme});

  final ThemeData theme;

  List<Widget> get children => [
        Center(
          child: NettiaLogo(
            size: 56,
            color: theme.textTheme.bodyLarge?.color,
            accent: theme.colorScheme.primary,
            accent2: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '¿Cómo vas a usar Nettia?',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Adaptamos el asistente y las herramientas a tu perfil. '
          'Puedes cambiarlo después en Configuración.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
      ];
}

class _OpcionPerfil extends StatelessWidget {
  const _OpcionPerfil({
    required this.icono,
    required this.perfil,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final UserProfile perfil;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(NetworkTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icono, size: 32, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.etiqueta,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perfil.descripcion,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
