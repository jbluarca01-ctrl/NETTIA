import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

/// Diálogo "Acerca de Nettia": descripción, funciones, licencia y acceso a
/// las licencias de terceros.
class AcercaDeDialogo extends StatelessWidget {
  const AcercaDeDialogo({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NetworkTheme.radiusLg),
      ),
      title: _titulo(Theme.of(context)),
      content: _contenido,
      actions: [
        TextButton(
          onPressed: () => _abrirLicencias(context),
          child: const Text('Licencias de terceros'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }

  Widget _titulo(ThemeData tema) => Row(
    children: [
      NettiaLogo(
        size: 22,
        color: tema.colorScheme.onSurface,
        accent: tema.colorScheme.primary,
        accent2: tema.colorScheme.tertiary,
      ),
      const SizedBox(width: 10),
      const Text('Nettia'),
    ],
  );

  static const _contenido = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Suite integral de ingeniería para conmutación, enrutamiento y redes industriales.',
        style: TextStyle(fontSize: 13),
      ),
      SizedBox(height: 12),
      Text(
        '• Calculadoras: subredes, dividir, VLSM, IPv6, conversiones y práctica',
      ),
      Text('• Plantillas Cisco IOS para VLANs y Router-on-a-stick'),
      Text(
        '• Asistente NETIA con base local con fuentes y multi-proveedor de IA',
      ),
      Text('• Guía metodológica de 5 capas'),
      SizedBox(height: 12),
      Text(
        '© 2026 Praxia Dynamic. Licencia personal e intransferible: prohibido copiar, compartir o revender. '
        'Nettia es un proyecto independiente: Cisco, CCNA y Packet Tracer son marcas de sus respectivos propietarios.',
        style: TextStyle(fontSize: 11.5),
      ),
    ],
  );

  /// Cierra el diálogo y abre la página de licencias. El navegador se toma
  /// antes de cerrar: después, este contexto ya no está montado.
  void _abrirLicencias(BuildContext context) {
    final navegador = Navigator.of(context)..pop();
    navegador.push(
      MaterialPageRoute<void>(
        builder:
            (_) => const LicensePage(
              applicationName: 'Nettia',
              applicationVersion: '1.0.0',
            ),
      ),
    );
  }
}
