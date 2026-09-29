Feature: Auditoría de una running-config contra el plan
  Se pega la salida de "show running-config" de un equipo y se compara con
  el plan: cada diferencia sale con su gravedad y los comandos que la
  corrigen. Solo se revisa lo que aparece en el texto (un switch no se
  audita como router ni al revés).

  Background:
    Given la red base "192.168.10.0/24" con los segmentos "VENTAS:50,TI:20"

  Scenario: Router que coincide con el plan
    Given la running-config:
      """
      hostname R1
      interface GigabitEthernet0/0/0
       no ip address
      interface GigabitEthernet0/0/0.10
       encapsulation dot1Q 10
       ip address 192.168.10.1 255.255.255.192
      interface GigabitEthernet0/0/0.20
       encapsulation dot1Q 20
       ip address 192.168.10.65 255.255.255.224
      ip dhcp excluded-address 192.168.10.1
      ip dhcp excluded-address 192.168.10.65
      ip dhcp pool VENTAS
       network 192.168.10.0 255.255.255.192
       default-router 192.168.10.1
      ip dhcp pool TI
       network 192.168.10.64 255.255.255.224
       default-router 192.168.10.65
      """
    When audito la configuración
    Then no hay hallazgos

  Scenario: Router con errores típicos de laboratorio
    Given la running-config:
      """
      interface GigabitEthernet0/0/0
       no ip address
       shutdown
      interface GigabitEthernet0/0/0.10
       encapsulation dot1Q 20
       ip address 192.168.10.1 255.255.255.0
      ip dhcp pool VENTAS
       network 192.168.10.0 255.255.255.192
       default-router 192.168.10.62
      """
    When audito la configuración
    Then los hallazgos son:
      """
      CRÍTICO | La interfaz física GigabitEthernet0/0/0 está apagada; sus subinterfaces no pasan tráfico. | interface GigabitEthernet0/0/0 / no shutdown
      CRÍTICO | VENTAS: el gateway 192.168.10.1 tiene máscara 255.255.255.0; el plan dice 255.255.255.192. | interface GigabitEthernet0/0/0.10 / ip address 192.168.10.1 255.255.255.192
      CRÍTICO | VENTAS: GigabitEthernet0/0/0.10 no tiene encapsulation dot1Q 10. | interface GigabitEthernet0/0/0.10 / encapsulation dot1Q 10
      CRÍTICO | VENTAS: el pool DHCP entrega el gateway 192.168.10.62; debe ser 192.168.10.1. | ip dhcp pool VENTAS / default-router 192.168.10.1
      AVISO | VENTAS: el gateway 192.168.10.1 no está excluido del DHCP; el pool podría entregárselo a una PC. | ip dhcp excluded-address 192.168.10.1
      CRÍTICO | TI: ninguna interfaz tiene el gateway 192.168.10.65. | interface GigabitEthernet0/0/0.20 / encapsulation dot1Q 20 / ip address 192.168.10.65 255.255.255.224 / no shutdown
      AVISO | TI: no hay pool DHCP para 192.168.10.64/27. | ip dhcp pool TI / network 192.168.10.64 255.255.255.224 / default-router 192.168.10.65
      """

  Scenario: Switch con troncal incompleto
    Given la running-config:
      """
      hostname SW1
      interface FastEthernet0/1
       switchport access vlan 10
       switchport mode access
      interface FastEthernet0/2
       switchport access vlan 30
       switchport mode access
      interface GigabitEthernet0/1
       switchport trunk allowed vlan 10,50-60
       switchport mode trunk
      """
    When audito la configuración
    Then los hallazgos son:
      """
      AVISO | GigabitEthernet0/1: la VLAN nativa es 1; el plan usa 99 y debe coincidir en ambos extremos. | interface GigabitEthernet0/1 / switchport trunk native vlan 99
      CRÍTICO | GigabitEthernet0/1: el troncal no permite la VLAN 20 (TI). | interface GigabitEthernet0/1 / switchport trunk allowed vlan add 20
      AVISO | FastEthernet0/2 está en la VLAN 30, que no está en el plan. | interface FastEthernet0/2 / switchport access vlan <10|20>
      AVISO | TI: ningún puerto de acceso está en la VLAN 20. | interface range FastEthernet0/X - Y / switchport mode access / switchport access vlan 20
      """

  Scenario: Switch capa 3 con SVI que falta
    Given la running-config:
      """
      ip routing
      interface Vlan10
       ip address 192.168.10.1 255.255.255.192
      """
    When audito la configuración
    Then los hallazgos son:
      """
      CRÍTICO | TI: ninguna interfaz tiene el gateway 192.168.10.65. | interface Vlan20 / ip address 192.168.10.65 255.255.255.224 / no shutdown
      """

  Scenario: Texto que no es una configuración
    Given la running-config:
      """
      hola, esto no es una configuración
      """
    When audito la configuración
    Then los hallazgos son:
      """
      AVISO | No se reconoció ninguna interfaz con IP, pool DHCP ni puerto de switch. Pega la salida completa de show running-config. | show running-config
      """
