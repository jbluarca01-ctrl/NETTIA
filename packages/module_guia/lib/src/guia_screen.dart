import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

class _ConfigStep {
  final String device; // Físico, Switch, PCs, Router, Verificación
  final String title;
  final String detail;
  final String check; // prueba que valida el paso antes de avanzar

  const _ConfigStep({
    required this.device,
    required this.title,
    required this.detail,
    required this.check,
  });
}

/// Módulo independiente: guía metodológica de configuración en 5 pasos.
class GuiaScreen extends StatelessWidget {
  const GuiaScreen({super.key});

  static const List<_ConfigStep> _configSteps = <_ConfigStep>[
    _ConfigStep(
      device: 'Físico',
      title: 'Armar la topología y conectar los cables',
      detail:
          'PCs a los puertos de acceso del switch y un puerto del switch al '
          'router (ese será el trunk). Cable directo en ambos casos.',
      check:
          'Los enlaces de las PCs deben ponerse en verde. El del router sigue '
          'caído hasta el paso 4: es normal.',
    ),
    _ConfigStep(
      device: 'Switch',
      title: 'VLANs, puertos de acceso y trunk',
      detail:
          'Pestaña "Switch": Copiar Todo y pegar en la consola del switch. '
          'Todavía no hay gateway: llega con el router.',
      check:
          'show vlan brief: cada puerto debe aparecer en su VLAN. Aún no '
          'verifiques el trunk: sube cuando el router encienda su interfaz.',
    ),
    _ConfigStep(
      device: 'PCs',
      title: 'IP, máscara y gateway en cada PC',
      detail:
          'En Packet Tracer: PC > Desktop > IP Configuration. La IP va dentro '
          'de la subred de su VLAN y el gateway es la IP de la subinterfaz '
          'del router (primer host de la subred).',
      check:
          'Ping entre dos PCs de la MISMA VLAN: debe responder ya, sin router. '
          'Si falla, revisa la VLAN del puerto y que ambas IPs compartan '
          'subred.',
    ),
    _ConfigStep(
      device: 'Router',
      title: 'Interfaz física y subinterfaces',
      detail:
          'Pestaña "Router": la interfaz física va con no shutdown y sin IP; '
          'cada subinterfaz lleva su encapsulation dot1Q y la IP del gateway.',
      check:
          'show ip interface brief: subinterfaces en up/up. En el switch, '
          'show interfaces trunk ahora sí debe mostrar el trunk. Luego ping '
          'de cada PC a su gateway.',
    ),
    _ConfigStep(
      device: 'Verificación',
      title: 'Comunicación entre VLAN y guardado',
      detail:
          'Ping de una PC de una VLAN a una PC de la otra (pestaña "Pruebas '
          'CMD"). Revisa show ip route y guarda con copy running-config '
          'startup-config en el switch y en el router.',
      check:
          'El primer ping puede perder un paquete por el ARP: repite y debe '
          'responder. Si no responde, vuelve al paso donde falló la capa '
          'anterior.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildOrderGuide(theme),
    );
  }

  static IconData _iconoDe(String dispositivo) {
    final d = dispositivo.toLowerCase();
    if (d.contains('switch')) return NettiaIcons.switchRed;
    if (d.contains('router')) return NettiaIcons.router;
    if (d.contains('pc')) return NettiaIcons.pc;
    if (d.contains('verif')) return NettiaIcons.validado;
    return NettiaIcons.diagrama;
  }

  Widget _buildOrderGuide(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Text(
          'Configura de abajo hacia arriba y prueba cada capa antes de subir '
          'a la siguiente. El resultado final es el mismo en cualquier orden, '
          'pero así encuentras la falla más rápido.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _configSteps.length; i++)
          _buildStepTile(theme, i + 1, _configSteps[i]),
      ],
    );
  }

  /// Tarjeta expandible: kicker "PASO N · DISPOSITIVO" y título; al abrirla
  /// muestra el detalle y la prueba que valida el paso.
  Widget _buildStepTile(ThemeData theme, int number, _ConfigStep step) {
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: scheme.primary,
          collapsedIconColor: scheme.onSurfaceVariant,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(NetworkTheme.radiusSm),
            ),
            child: Icon(_iconoDe(step.device), size: 21, color: scheme.primary),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PASO $number · ${step.device.toUpperCase()}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                step.title,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          children: <Widget>[
            Text(step.detail, style: const TextStyle(fontSize: 13, height: 1.45)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(NetworkTheme.radiusSm),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.30)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(NettiaIcons.validado, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.check,
                      style: const TextStyle(fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
