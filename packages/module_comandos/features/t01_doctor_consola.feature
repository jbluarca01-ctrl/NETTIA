Feature: Doctor de consola
  Se pega lo que muestra la consola (errores de IOS, mensajes de syslog o
  la salida de un ping en una PC) y sale un diagnóstico por problema, con la
  causa y los comandos para corregirlo usando los datos del propio mensaje.

  Scenario: Comando mal escrito en configuración global
    Given la salida de consola:
      """
      Switch(config)#swithcport mode access
                     ^
      % Invalid input detected at '^' marker.
      """
    When la diagnostico
    Then los diagnósticos son:
      """
      Comando no reconocido | IOS no entiende "swithcport" en el modo de configuración global (Switch(config)#). | Revisa cómo escribiste "swithcport". / Escribe ? en ese punto para ver las opciones válidas. / Si es un comando de interfaz, entra primero con interface <nombre>.
      """

  Scenario: Comando de configuración escrito en modo usuario
    Given la salida de consola:
      """
      Router>configure terminal
             ^
      % Invalid input detected at '^' marker.
      """
    When la diagnostico
    Then los diagnósticos son:
      """
      Comando no reconocido | IOS no entiende "configure" en el modo usuario (Router>). | Revisa cómo escribiste "configure". / Escribe ? en ese punto para ver las opciones válidas. / Estás en modo usuario: entra primero con enable.
      """

  Scenario: Varios mensajes de syslog a la vez
    Given la salida de consola:
      """
      %LINK-5-CHANGED: Interface GigabitEthernet0/0, changed state to administratively down
      %CDP-4-NATIVE_VLAN_MISMATCH: Native VLAN mismatch discovered on GigabitEthernet0/1 (99), with Switch GigabitEthernet0/2 (1).
      %LINEPROTO-5-UPDOWN: Line protocol on Interface Serial0/0/0, changed state to down
      %LINK-3-UPDOWN: Interface FastEthernet0/5, changed state to down
      """
    When la diagnostico
    Then los diagnósticos son:
      """
      Interfaz apagada | GigabitEthernet0/0 está en shutdown. | interface GigabitEthernet0/0 / no shutdown
      VLAN nativa distinta en el troncal | GigabitEthernet0/1 usa la nativa 99 y el otro extremo (Switch GigabitEthernet0/2) usa la 1. | En ambos extremos del troncal: / interface GigabitEthernet0/1 / switchport trunk native vlan 99
      Protocolo de línea caído | Serial0/0/0 tiene señal pero la capa 2 no sube: encapsulación distinta, falta clock rate en el extremo DCE o el otro lado está apagado. | show interfaces Serial0/0/0 / En el extremo DCE de un serial: clock rate 64000 / Usa la misma encapsulación en ambos extremos.
      Enlace caído | FastEthernet0/5 no detecta señal: cable desconectado, tipo de cable incorrecto o el otro extremo apagado. | Revisa el cable y que el otro extremo tenga no shutdown. / show interfaces FastEthernet0/5
      """

  Scenario: Errores de direccionamiento
    Given la salida de consola:
      """
      % 192.168.1.0 overlaps with GigabitEthernet0/0
      % Bad mask /33 for address 10.0.0.1
      %IP-4-DUPADDR: Duplicate address 192.168.1.10 on GigabitEthernet0/0, sourced by 0060.2F3A.1B01
      %DHCPD-4-PING_CONFLICT: DHCP address conflict:  server pinged 192.168.1.5.
      """
    When la diagnostico
    Then los diagnósticos son:
      """
      Redes solapadas | La red 192.168.1.0 ya está en GigabitEthernet0/0; dos interfaces de un router no pueden estar en la misma subred. | Usa otra subred (el Diseñador de red las calcula sin solaparse). / show ip interface brief
      Máscara inválida | /33 no es una máscara válida para 10.0.0.1. | Usa una máscara contigua, p. ej. 255.255.255.0 (/24). / ip address 10.0.0.1 <máscara>
      IP duplicada | Otro equipo (MAC 0060.2F3A.1B01) usa 192.168.1.10 en GigabitEthernet0/0. | Cambia la IP fija de uno de los dos equipos. / Si la entrega el DHCP, exclúyela: ip dhcp excluded-address 192.168.1.10
      Conflicto de DHCP | 192.168.1.5 está en el pool pero ya la usa un equipo con IP fija. | ip dhcp excluded-address 192.168.1.5 / clear ip dhcp conflict *
      """

  Scenario: Problemas de capa 2 y de enrutamiento
    Given la salida de consola:
      """
      %PM-4-ERR_DISABLE: psecure-violation error detected on Fa0/1, putting Fa0/1 in err-disable state
      %PM-4-ERR_DISABLE: bpduguard error detected on Gi0/2, putting Gi0/2 in err-disable state
      %SW_MATM-4-MACFLAP_NOTIF: Host 0050.0f1a.2b3c in vlan 10 is flapping between port Fa0/3 and port Fa0/4
      %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on GigabitEthernet0/0 from FULL to DOWN, Neighbor Down: Dead timer expired
      """
    When la diagnostico
    Then los diagnósticos son:
      """
      Puerto bloqueado por port-security | Fa0/1 vio una MAC no permitida y quedó en err-disable. | show port-security interface Fa0/1 / interface Fa0/1 / shutdown / no shutdown
      Puerto en err-disable | Gi0/2 se desactivó por bpduguard. | Corrige la causa antes de reactivarlo. / interface Gi0/2 / shutdown / no shutdown
      Posible bucle de capa 2 | La MAC 0050.0f1a.2b3c salta entre Fa0/3 y Fa0/4 en la VLAN 10. | Revisa enlaces redundantes entre switches. / show spanning-tree vlan 10
      Vecino OSPF perdido | El vecino 2.2.2.2 dejó de enviar hellos por GigabitEthernet0/0. | show ip ospf neighbor / Compara en ambos routers hello/dead, área y subred: show ip ospf interface GigabitEthernet0/0
      """

  Scenario: Mensajes de comandos y de una PC
    Given la salida de consola:
      """
      Router#confgi
      Translating "confgi"...domain server (255.255.255.255)
      % Incomplete command.
      % Ambiguous command:  "sh i"
      Request timed out.
      Destination host unreachable.
      Request timed out.
      """
    When la diagnostico
    Then los diagnósticos son:
      """
      IOS intentó resolver un nombre | "confgi" no es un comando, así que IOS lo tomó como nombre de equipo y lo buscó por DNS. | Corrige el comando. / Para no esperar la próxima vez: no ip domain-lookup
      Comando incompleto | Faltan parámetros al final del comando. | Repite el comando y escribe ? al final para ver qué falta.
      Comando ambiguo | La abreviatura "sh i" coincide con varios comandos. | Escribe más letras o usa ? para ver las opciones.
      Ping sin respuesta | El paquete salió pero no volvió: revisa gateway, VLAN del puerto y ruta de regreso. | 1) ping a tu gateway / 2) show vlan brief: ¿el puerto está en la VLAN correcta? / 3) show interfaces trunk: ¿el troncal permite la VLAN? / 4) show ip route en el router: ¿hay ruta de regreso?
      Destino inalcanzable | Algún equipo no sabe cómo llegar: falta el gateway en la PC o una ruta en el router. | ipconfig: ¿la PC tiene default gateway? / show ip route en el router
      """

  Scenario: Nada reconocible
    Given la salida de consola:
      """
      Router#show clock
      *0:12:33.123 UTC Mon Mar 1 1993
      """
    When la diagnostico
    Then no hay diagnósticos
