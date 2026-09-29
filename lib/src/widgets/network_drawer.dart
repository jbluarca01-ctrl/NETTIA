import 'package:flutter/material.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_core/nettia_core.dart';

/// Menú lateral (hamburguesa) de Nettia — marca, lista plana de módulos
/// (sin submenús) y sección de sistema.
class NetworkDrawer extends StatelessWidget {
  const NetworkDrawer({
    super.key,
    required this.profile,
    required this.current,
    required this.onSelectModule,
    required this.onOpenSettings,
    this.netiaUnreadCount = 0,
  });

  final UserProfile profile;
  final NettiaModulo current;
  final void Function(NettiaModulo modulo) onSelectModule;
  final VoidCallback onOpenSettings;
  final int netiaUnreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = AiSettingsService.instance;
    final isOffline =
        settings.activeProvider.name == 'offline' ||
        settings.offlinePreferred ||
        settings.currentActiveKey.isEmpty;
    final accent = theme.colorScheme.primary;
    final accent2 = theme.colorScheme.tertiary;

    final modules = <_ModuleItem>[
      _ModuleItem(
        NettiaIcons.calculadora,
        'Calculadora de Subredes',
        'IPv4, CIDR y desglose binario',
        accent,
        NettiaModulo.calculadora,
      ),
      _ModuleItem(
        NettiaIcons.comandos,
        'Comandos CLI & Plantillas',
        'VLANs, Router-on-a-stick y pruebas',
        accent2,
        NettiaModulo.comandos,
      ),
      _ModuleItem(
        NettiaIcons.asistente,
        'Asistente NETIA',
        'Diagnóstico IA & protocolos OT',
        accent,
        NettiaModulo.asistente,
        badge: netiaUnreadCount,
      ),
      _ModuleItem(
        NettiaIcons.guia,
        'Guía Metodológica',
        'Los 5 pasos de configuración',
        accent2,
        NettiaModulo.guia,
      ),
      _ModuleItem(
        NettiaIcons.diagrama,
        'Diseñador de Red',
        'Plan, configuración, verificación y auditoría',
        accent,
        NettiaModulo.disenador,
      ),
    ];

    return Drawer(
      backgroundColor:
          isDark ? NetworkTheme.darkSurface : NetworkTheme.lightBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(NetworkTheme.radiusLg),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 18,
              left: 18,
              right: 18,
            ),
            child: Row(
              children: [
                NettiaLogo(
                  size: 28,
                  color: theme.textTheme.bodyLarge?.color,
                  accent: accent,
                  accent2: accent2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nettia',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isOffline
                                      ? NetworkTheme.amberAlert
                                      : NetworkTheme.ledGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOffline ? 'MODO OFFLINE' : 'AI EN LÍNEA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isOffline
                                      ? NetworkTheme.amberAlert
                                      : NetworkTheme.ledGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                _sectionLabel('MÓDULOS'),
                // Un módulo restringido no aparece: el perfil no lo ve, así que
                // tampoco puede seleccionarlo.
                for (final m in modules.where((m) => profile.puedeUsar(m.modulo)))
                  _row(
                    context,
                    icon: m.icon,
                    title: m.title,
                    subtitle: m.subtitle,
                    color: m.color,
                    selected: current == m.modulo,
                    badge: m.badge,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectModule(m.modulo);
                    },
                  ),
                const SizedBox(height: 12),
                _sectionLabel('SISTEMA'),
                _row(
                  context,
                  icon: NettiaIcons.ajustes,
                  title: 'Configuración & IA',
                  subtitle: 'Motores IA, apariencia y modelos',
                  color: NetworkTheme.amberAlert,
                  selected: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    onOpenSettings();
                  },
                ),
                _row(
                  context,
                  icon: NettiaIcons.acercaDe,
                  title: 'Acerca de Nettia',
                  subtitle: 'Versión 1.0.0',
                  color:
                      isDark
                          ? NetworkTheme.darkTextMuted
                          : NetworkTheme.lightTextSecondary,
                  selected: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAbout(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'v1.0.0',
                  style: NetworkTheme.mono(
                    size: 11,
                    color:
                        isDark
                            ? NetworkTheme.darkTextMuted
                            : NetworkTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  'Nettia',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? NetworkTheme.darkTextMuted
                            : NetworkTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: NetworkTheme.darkTextMuted,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool selected,
    VoidCallback? onTap,
    int badge = 0,
  }) {
    // Material (y no Container con decoración) para que el ListTile pinte su
    // fondo y su efecto de toque sobre él, sin ocultarlos.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(NetworkTheme.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NetworkTheme.radiusMd),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(NetworkTheme.radiusSm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
          trailing:
              badge > 0
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF14C4C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                  : null,
          onTap: onTap,
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NetworkTheme.radiusLg),
            ),
            title: Row(
              children: [
                NettiaLogo(
                  size: 22,
                  color: Theme.of(ctx).textTheme.bodyLarge?.color,
                  accent: Theme.of(ctx).colorScheme.primary,
                  accent2: Theme.of(ctx).colorScheme.tertiary,
                ),
                const SizedBox(width: 10),
                const Text('Nettia'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suite integral de ingeniería para conmutación, enrutamiento y redes industriales.',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 12),
                Text('• Calculadoras: subredes, dividir, VLSM, IPv6, conversiones y práctica'),
                Text('• Plantillas Cisco IOS para VLANs y Router-on-a-stick'),
                Text('• Asistente NETIA con base local con fuentes y multi-proveedor de IA'),
                Text('• Guía metodológica de 5 capas'),
                SizedBox(height: 12),
                Text(
                  '© 2026 Praxia Dynamic. Licencia personal e intransferible: prohibido copiar, compartir o revender. '
                  'Nettia es un proyecto independiente: Cisco, CCNA y Packet Tracer son marcas de sus respectivos propietarios.',
                  style: TextStyle(fontSize: 11.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showLicensePage(
                    context: context,
                    applicationName: 'Nettia',
                    applicationVersion: '1.0.0',
                  );
                },
                child: const Text('Licencias de terceros'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }
}

class _ModuleItem {
  _ModuleItem(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.modulo, {
    this.badge = 0,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final NettiaModulo modulo;
  final int badge;
}
