Feature: Aplicar los comandos de corrección (Repara la red, nivel 2)
  SPEC-002 T1. Nettia aplica a la running-config los comandos que escribe el
  estudiante, con los modos de IOS (global, interfaz y pool), y la vuelve a
  auditar. Los comandos se separan con ";" en los escenarios.

  Background:
    Given la red base "192.168.10.0/24" con los segmentos "VENTAS:50,TI:20"

  Scenario Outline: Cada falla se arregla escribiendo sus comandos (SPEC-002-RF1, RF2, RF3, RF5)
    When inyecto la falla "<falla>" en el segmento "TI"
    And aplico a "<equipo>" los comandos "<comandos>"
    Then el auditor no reporta nada en "R1"
    And el auditor no reporta nada en "SW1"
    And no quedó ningún comando sin reconocer

    Examples:
      | falla                   | equipo | comandos                                                                                   |
      | fisicaApagada           | R1     | enable;configure terminal;interface GigabitEthernet0/0/0;no shutdown;end;write memory      |
      | subinterfazApagada      | R1     | conf t;int g0/0/0.20;no shutdown;exit                                                      |
      | mascaraGateway          | R1     | interface GigabitEthernet0/0/0.20;ip address 192.168.10.65 255.255.255.224                 |
      | sinEncapsulacion        | R1     | interface Gi0/0/0.20;encapsulation dot1Q 20                                                |
      | gatewayEquivocado       | R1     | INTERFACE gig0/0/0.20;IP ADDRESS 192.168.10.65 255.255.255.224                             |
      | sinDefaultRouter        | R1     | ip dhcp pool TI;default-router 192.168.10.65                                               |
      | defaultRouterEquivocado | R1     | ip dhcp pool ti;default-router 192.168.10.65                                               |
      | sinPool                 | R1     | ip dhcp pool TI;network 192.168.10.64 255.255.255.224;default-router 192.168.10.65;exit    |
      | gatewayNoExcluido       | R1     | ip dhcp excluded-address 192.168.10.65                                                     |
      | puertoOtraVlan          | SW1    | interface range fa0/13 - 24;switchport access vlan 20                                      |
      | troncalSinVlan          | SW1    | interface GigabitEthernet0/1;switchport trunk allowed vlan add 20                          |
      | nativaDistinta          | SW1    | int g0/1;switchport trunk native vlan 99                                                   |

  Scenario: Un comando reemplaza la línea del mismo tipo (SPEC-002-RF2)
    When genero la configuración sin falla
    And aplico a "SW1" los comandos "int g0/1;switchport trunk allowed vlan 10,99"
    Then el auditor reporta en "SW1" solo "GigabitEthernet0/1: el troncal no permite la VLAN 20 (TI)."

  Scenario: shutdown reemplaza a no shutdown (SPEC-002-RF2)
    When genero la configuración sin falla
    And aplico a "R1" los comandos "int g0/0/0;shutdown"
    Then el auditor reporta en "R1" solo "La interfaz física GigabitEthernet0/0/0 está apagada; sus subinterfaces no pasan tráfico."

  Scenario: Lo que no se reconoce se informa en orden y no cambia nada (SPEC-002-RF4)
    When genero la configuración sin falla
    And aplico a "R1" los comandos "router ospf 1;no shutdown;ip dhcp pool TI;switchport mode trunk;exit;default-router 1.1.1.1"
    Then no se reconocieron "router ospf 1,no shutdown,switchport mode trunk,default-router 1.1.1.1"
    And la configuración de "R1" no cambió

  Scenario: Una interfaz que no existe se crea antes de end (SPEC-002-RF3)
    When genero la configuración sin falla
    And aplico a "R1" los comandos "interface GigabitEthernet0/0/1;no shutdown"
    Then las últimas líneas de "R1" son "interface GigabitEthernet0/0/1;no shutdown;exit;end;write memory"
