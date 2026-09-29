import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'explicar_tab.dart';

class _CommandSnippet {
  final String title;
  final String command;
  final String description;

  const _CommandSnippet({
    required this.title,
    required this.command,
    required this.description,
  });
}

/// Módulo independiente: repositorio de comandos CLI y plantillas.
class ComandosScreen extends StatefulWidget {
  const ComandosScreen({super.key});

  @override
  State<ComandosScreen> createState() => _ComandosScreenState();
}

class _ComandosScreenState extends State<ComandosScreen> {
  static const List<_CommandSnippet> _switchCommands = <_CommandSnippet>[
    _CommandSnippet(
      title: 'Entrar a modo privilegiado',
      command: 'enable',
      description: 'Primer paso siempre: habilita el modo EXEC privilegiado.',
    ),
    _CommandSnippet(
      title: 'Entrar a modo de configuración global',
      command: 'configure terminal',
      description: 'Punto de partida para cualquier cambio de configuración.',
    ),
    _CommandSnippet(
      title: 'Crear una VLAN',
      command: 'vlan <id>',
      description: 'Crea la VLAN con el número indicado (ej. vlan 10).',
    ),
    _CommandSnippet(
      title: 'Nombrar la VLAN',
      command: 'name <NOMBRE>',
      description: 'Se ejecuta dentro del modo de configuración de la VLAN.',
    ),
    _CommandSnippet(
      title: 'Entrar a una interfaz (o rango)',
      command: 'interface range fastEthernet 0/<inicio>-<fin>',
      description:
          'Para un solo puerto usar "interface fastEthernet 0/<n>".',
    ),
    _CommandSnippet(
      title: 'Poner el puerto en modo acceso',
      command: 'switchport mode access',
      description: 'Necesario antes de asignar el puerto a una VLAN.',
    ),
    _CommandSnippet(
      title: 'Asignar el puerto a una VLAN',
      command: 'switchport access vlan <id>',
      description: 'Asocia el/los puerto(s) seleccionados a esa VLAN.',
    ),
    _CommandSnippet(
      title: 'Poner el puerto en modo trunk',
      command: 'switchport mode trunk',
      description: 'Para el enlace hacia el router u otro switch.',
    ),
    _CommandSnippet(
      title: 'Permitir VLANs en el trunk',
      command: 'switchport trunk allowed vlan <lista>',
      description: 'Ej.: switchport trunk allowed vlan 10,20,30,40.',
    ),
    _CommandSnippet(
      title: 'Guardar la configuración',
      command: 'copy running-config startup-config',
      description: 'Persiste los cambios para que sobrevivan a un reinicio.',
    ),
  ];

  // --- COMANDOS GENÉRICOS DE ROUTER-ON-A-STICK (SUBINTERFACES dot1Q) ---

  static const List<_CommandSnippet> _routerCommands = <_CommandSnippet>[
    _CommandSnippet(
      title: 'Entrar a modo privilegiado',
      command: 'enable',
      description: 'Primer paso siempre: habilita el modo EXEC privilegiado.',
    ),
    _CommandSnippet(
      title: 'Entrar a modo de configuración global',
      command: 'configure terminal',
      description: 'Punto de partida para cualquier cambio de configuración.',
    ),
    _CommandSnippet(
      title: 'Entrar a la interfaz física',
      command: 'interface gigabitEthernet 0/0/0',
      description: 'La interfaz física no lleva IP en router-on-a-stick.',
    ),
    _CommandSnippet(
      title: 'Activar la interfaz física',
      command: 'no shutdown',
      description: 'Sin esto la interfaz queda administrativamente abajo.',
    ),
    _CommandSnippet(
      title: 'Crear una subinterfaz',
      command: 'interface gigabitEthernet 0/0/0.<id>',
      description: 'El <id> suele coincidir con el número de VLAN.',
    ),
    _CommandSnippet(
      title: 'Encapsular dot1Q en la subinterfaz',
      command: 'encapsulation dot1Q <vlan_id>',
      description: 'Asocia la subinterfaz a esa VLAN etiquetada por el trunk.',
    ),
    _CommandSnippet(
      title: 'Asignar IP y máscara a la subinterfaz',
      command: 'ip address <ip> <mascara>',
      description: 'Esa IP funciona como gateway de esa VLAN.',
    ),
    _CommandSnippet(
      title: 'Guardar la configuración',
      command: 'copy running-config startup-config',
      description: 'Persiste los cambios para que sobrevivan a un reinicio.',
    ),
  ];

  // --- COMANDOS DE AUDITORÍA (VERIFICACIÓN IOS) ---

  static const List<_CommandSnippet> _auditCommands = <_CommandSnippet>[
    _CommandSnippet(
      title: 'Mapeo de VLANs y Puertos',
      command: 'show vlan brief',
      description:
          'Verifica qué puertos físicos pertenecen a cada VLAN en el Switch.',
    ),
    _CommandSnippet(
      title: 'Comprobación de Enlace Troncal',
      command: 'show interfaces trunk',
      description:
          'Muestra puertos en trunk, encapsulación dot1Q y VLANs permitidas.',
    ),
    _CommandSnippet(
      title: 'Estado de Interfaces y Subinterfaces',
      command: 'show ip interface brief',
      description:
          'Valida estado administrativo y físico (Up/Up) e IPs en Router/Switch.',
    ),
    _CommandSnippet(
      title: 'Tabla de Enrutamiento IP',
      command: 'show ip route',
      description:
          'Muestra las rutas directamente conectadas y gateways en el Router.',
    ),
  ];

  // --- COMANDOS INDIVIDUALES DE TERMINAL ---

  static const List<_CommandSnippet> _terminalCommands = <_CommandSnippet>[
    _CommandSnippet(
      title: 'Auditoría de Red Local (Capa 3)',
      command: 'ipconfig',
      description:
          'Muestra la dirección IP actual, máscara de subred y Default Gateway.',
    ),
    _CommandSnippet(
      title: 'Prueba de Conectividad con Gateway',
      command: 'ping 192.168.1.1',
      description:
          'Valida el alcance directo hacia la subinterfaz dot1Q del enrutador.',
    ),
    _CommandSnippet(
      title: 'Prueba de Conmutación Intra-VLAN (Capa 2)',
      command: 'ping 192.168.1.11',
      description:
          'Comprueba conmutación pura dentro del mismo segmento lógico de VLAN.',
    ),
    _CommandSnippet(
      title: 'Prueba de Enrutamiento Inter-VLAN (Capa 3)',
      command: 'ping 192.168.1.70',
      description:
          'Comprueba el salto de paquetes hacia otra VLAN cruzando el Router-on-a-Stick.',
    ),
  ];

  // --- COMANDOS DE ORDEN DE CONFIGURACIÓN (guía paso a paso) ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 5,
      child: Column(
        children: <Widget>[
          TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor:
                theme.textTheme.bodyMedium?.color?.withAlpha(150),
            indicatorColor: theme.colorScheme.primary,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const <Widget>[
              Tab(icon: Icon(NettiaIcons.switchRed, size: 18), text: 'Switch (VLANs)', iconMargin: EdgeInsets.only(bottom: 2)),
              Tab(icon: Icon(NettiaIcons.router, size: 18), text: 'Router (dot1Q)', iconMargin: EdgeInsets.only(bottom: 2)),
              Tab(icon: Icon(NettiaIcons.validado, size: 18), text: 'Auditoría IOS', iconMargin: EdgeInsets.only(bottom: 2)),
              Tab(icon: Icon(NettiaIcons.pc, size: 18), text: 'Pruebas CMD', iconMargin: EdgeInsets.only(bottom: 2)),
              Tab(icon: Icon(NettiaIcons.libro, size: 18), text: 'Explicar salida', iconMargin: EdgeInsets.only(bottom: 2)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _buildSnippetList(_switchCommands),
                _buildSnippetList(_routerCommands),
                _buildSnippetList(_auditCommands),
                _buildSnippetList(_terminalCommands),
                const ExplicarSalidaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnippetList(List<_CommandSnippet> list) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (BuildContext context, int index) {
        final _CommandSnippet item = list[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.title,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(170),
              ),
            ),
            const SizedBox(height: 8),
            EditorCodeBlock(code: item.command),
          ],
        );
      },
    );
  }
}
