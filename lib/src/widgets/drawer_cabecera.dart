import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

/// La IA está sin conexión si el proveedor activo es el local, si el usuario
/// prefiere el modo offline o si el proveedor no tiene clave.
bool iaSinConexion({
  required String proveedor,
  required bool offlinePreferido,
  required String clave,
}) => proveedor == 'offline' || offlinePreferido || clave.isEmpty;

/// Cabecera del menú lateral: logo, nombre y estado de la IA.
class DrawerCabecera extends StatelessWidget {
  const DrawerCabecera({super.key, required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 18, left: 18, right: 18),
      child: Row(
        children: [
          NettiaLogo(
            size: 28,
            color: theme.colorScheme.onSurface,
            accent: theme.colorScheme.primary,
            accent2: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nettia',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                _estado(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _estado() {
    final color = offline ? NetworkTheme.amberAlert : NetworkTheme.ledGreen;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          offline ? 'MODO OFFLINE' : 'AI EN LÍNEA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
