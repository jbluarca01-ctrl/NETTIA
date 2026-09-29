/// Base de conocimiento local de Nettia: respuestas heurísticas sin conexión ni API Key.
String generateOfflineResponse(String query) {
  final q = query.toLowerCase();

  if (q.contains('trunk') ||
      q.contains('troncal') ||
      q.contains('802.1q') ||
      q.contains('dot1q')) {
    return '### Configuración de Enlace Troncal (IEEE 802.1Q)\n\n'
        'Un enlace troncal transporta tráfico de múltiples VLANs a través de un solo puerto físico agregando una etiqueta 802.1Q de 4 bytes.\n\n'
        '**Comandos esenciales en Switch Cisco:**\n'
        '```ios\n'
        'Switch# configure terminal\n'
        'Switch(config)# interface gigabitEthernet 0/1\n'
        'Switch(config-if)# switchport mode trunk\n'
        'Switch(config-if)# switchport trunk allowed vlan 10,20,30\n'
        '```\n\n'
        '**Comando de verificación:**\n'
        '`show interfaces trunk`\n\n'
        '💡 *Tip:* Asegúrate de que ambos extremos del enlace compartan la misma VLAN nativa (por defecto VLAN 1).';
  }

  if (q.contains('router-on-a-stick') ||
      q.contains('subinterfaz') ||
      q.contains('subinterface')) {
    return '### Router-on-a-Stick (Enrutamiento Inter-VLAN)\n\n'
        'Permite enrutar paquetes entre distintas VLANs utilizando una sola interfaz física dividida en subinterfaces lógicas.\n\n'
        '**Pasos clave de configuración:**\n'
        '1. Activar la interfaz física del enrutador sin asignar IP:\n'
        '```ios\n'
        'Router(config)# interface g0/0/0\n'
        'Router(config-if)# no shutdown\n'
        '```\n'
        '2. Crear subinterfaces dot1Q (una por cada VLAN):\n'
        '```ios\n'
        'Router(config)# interface g0/0/0.10\n'
        'Router(config-subif)# encapsulation dot1Q 10\n'
        'Router(config-subif)# ip address 192.168.10.1 255.255.255.0\n'
        '```\n'
        '3. En el switch, el puerto conectado al router DEBE estar en modo troncal (`switchport mode trunk`).';
  }

  if (q.contains('subnet') ||
      q.contains('subred') ||
      q.contains('cidr') ||
      q.contains('mascara')) {
    return '### Cálculo de Subredes y Máscaras CIDR\n\n'
        'Para segmentar una red IPv4 necesitas:\n'
        '- **Bits de red (/n):** Definen la máscara de subred.\n'
        '- **Bits de host (32 - n):** Cantidad de hosts utilizables = `2^(32 - n) - 2`.\n\n'
        '**Ejemplo /24 (255.255.255.0):**\n'
        '- 8 bits de host = 256 direcciones totales (254 útiles).\n\n'
        '**Ejemplo /26 (255.255.255.192):**\n'
        '- Salto de bloque: 256 - 192 = 64 direcciones por subred.\n'
        '- Subredes: .0, .64, .128, .192 (62 hosts útiles por cada una).\n\n'
        '💡 *Tip:* Usa la calculadora en la parte superior para ver el desglose binario octeto por octeto.';
  }

  if (q.contains('modbus') ||
      q.contains('ethernet/ip') ||
      q.contains('profinet') ||
      q.contains('industrial') ||
      RegExp(r'\bot\b').hasMatch(q)) {
    return '### Redes Industriales y Segmentación OT\n\n'
        'Al diseñar VLANs en entornos de automatización e industria 4.0:\n\n'
        '1. **Modbus TCP (Puerto 502):** Puede cruzar routers/firewalls ya que opera sobre TCP/IP estándar con direccionamiento Capa 3.\n'
        '2. **EtherNet/IP (CIP):** El tráfico de control implícito (UDP 2222) depende de Multicast. Es crítico habilitar **IGMP Snooping** en los switches para no saturar los puertos.\n'
        '3. **Profinet RT / IRT:** El tráfico de tiempo real opera directamente en Capa 2 (Ethertype 0x8892). **No cruza routers** y debe permanecer en su propia VLAN de control.\n\n'
        '💡 *Buenas prácticas:* Aislar la celda de producción según el Modelo Purdue / ISA-99 / IEC 62443.';
  }

  if (q.contains('ping') ||
      q.contains('falla') ||
      q.contains('no responde') ||
      q.contains('error')) {
    return '### Diagnóstico de Fallas de Comunicación\n\n'
        'Aplica el método OSI de abajo hacia arriba:\n\n'
        '1. **Capa 1 (Física):** Revisa el estado de los enlaces (puertos en verde).\n'
        '2. **Capa 2 (Enlace):**\n'
        '   - Switch: `show vlan brief` (valida asignación de puertos a su VLAN).\n'
        '   - Troncal: `show interfaces trunk` (revisa que el troncal permita la VLAN).\n'
        '3. **Capa 3 (Red):**\n'
        '   - Revisa `ipconfig` en el host: IP, máscara y Default Gateway.\n'
        '   - En el router: `show ip interface brief` y `show ip route`.\n'
        '   - Haz ping primero al Gateway local; si responde, prueba el host de destino.';
  }

  return '### Asistente NETIA — Redes & Automatización\n\n'
      'Estoy listo para ayudarte con:\n'
      '- **VLANs & Trunks:** Configuración 802.1Q, accesos y enlaces troncales.\n'
      '- **Router-on-a-Stick:** Subinterfaces, dot1Q y enrutamiento inter-VLAN.\n'
      '- **Cálculo de Subredes:** Conversiones decimal/binario, rangos de hosts y gateways.\n'
      '- **Redes Industriales (OT):** Modbus TCP, EtherNet/IP, Profinet e IEC 62443.\n'
      '- **Diagnóstico IOS:** Comandos `show`, depuración de conectividad y análisis de fallas.\n\n'
      '¿Qué tema o comando te gustaría revisar?';
}
