Feature: Fallas de "Repara la red"
  SPEC-001 T1. Cada falla cambia una sola cosa en un solo equipo de la
  configuración que genera el Diseñador, y el auditor la detecta con
  exactamente un hallazgo en ese equipo y ninguno en el otro.

  Background:
    Given la red base "192.168.10.0/24" con los segmentos "VENTAS:50,TI:20"

  Scenario: Sin falla los dos equipos pasan la auditoría (SPEC-001-RF1)
    When genero la configuración sin falla
    Then el auditor no reporta nada en "R1"
    And el auditor no reporta nada en "SW1"

  Scenario Outline: Cada falla deja un solo hallazgo en su equipo (SPEC-001-RF2, RF3)
    When inyecto la falla "<falla>" en el segmento "TI"
    Then el auditor reporta en "<equipo>" solo "<hallazgo>"
    And el auditor no reporta nada en "<otro>"

    Examples:
      | falla                   | equipo | otro | hallazgo                                                                                      |
      | fisicaApagada           | R1     | SW1  | La interfaz física GigabitEthernet0/0/0 está apagada; sus subinterfaces no pasan tráfico.      |
      | subinterfazApagada      | R1     | SW1  | TI: GigabitEthernet0/0/0.20 está apagada (shutdown).                                          |
      | mascaraGateway          | R1     | SW1  | TI: el gateway 192.168.10.65 tiene máscara 255.255.255.240; el plan dice 255.255.255.224.     |
      | sinEncapsulacion        | R1     | SW1  | TI: GigabitEthernet0/0/0.20 no tiene encapsulation dot1Q 20.                                  |
      | gatewayEquivocado       | R1     | SW1  | TI: ninguna interfaz tiene el gateway 192.168.10.65.                                          |
      | sinDefaultRouter        | R1     | SW1  | TI: el pool DHCP no entrega gateway (default-router).                                         |
      | defaultRouterEquivocado | R1     | SW1  | TI: el pool DHCP entrega el gateway 192.168.10.66; debe ser 192.168.10.65.                    |
      | sinPool                 | R1     | SW1  | TI: no hay pool DHCP para 192.168.10.64/27.                                                   |
      | gatewayNoExcluido       | R1     | SW1  | TI: el gateway 192.168.10.65 no está excluido del DHCP; el pool podría entregárselo a una PC. |
      | puertoOtraVlan          | SW1    | R1   | TI: ningún puerto de acceso está en la VLAN 20.                                               |
      | troncalSinVlan          | SW1    | R1   | GigabitEthernet0/1: el troncal no permite la VLAN 20 (TI).                                    |
      | nativaDistinta          | SW1    | R1   | GigabitEthernet0/1: la VLAN nativa es 1; el plan usa 99 y debe coincidir en ambos extremos.   |

  Scenario Outline: Síntoma y causa de cada falla (SPEC-001-RF4)
    When inyecto la falla "<falla>" en el segmento "TI"
    Then el síntoma es "<sintoma>"
    And la causa es "<causa>"

    Examples:
      | falla                   | sintoma                                                                                                  | causa                                                      |
      | fisicaApagada           | Ningún PC de ninguna VLAN recibe IP por DHCP: todos quedan con 169.254.x.x y nadie llega a su gateway.   | La interfaz física del router está apagada (shutdown).     |
      | subinterfazApagada      | Los PC de TI quedan con 169.254.x.x y no llegan a su gateway; las demás VLAN funcionan.                  | La subinterfaz del segmento está apagada (shutdown).       |
      | mascaraGateway          | Algunos PC de TI reciben IP pero no llegan al gateway 192.168.10.65; otros PC del mismo segmento sí.     | El gateway del router tiene la máscara equivocada.         |
      | sinEncapsulacion        | Los PC de TI quedan con 169.254.x.x aunque sus puertos de acceso y el troncal están bien.                | A la subinterfaz le falta encapsulation dot1Q.             |
      | gatewayEquivocado       | Los PC de TI reciben IP y gateway 192.168.10.65, pero el ping al gateway falla.                          | La subinterfaz tiene una IP distinta del gateway del plan. |
      | sinDefaultRouter        | Los PC de TI reciben IP pero sin puerta de enlace: llegan a su red, no a las otras VLAN.                 | El pool DHCP no tiene default-router.                      |
      | defaultRouterEquivocado | Los PC de TI reciben como puerta de enlace 192.168.10.66 y no salen de su red.                           | El pool DHCP entrega un default-router equivocado.         |
      | sinPool                 | Los PC de TI quedan con 169.254.x.x; las demás VLAN reciben IP sin problema.                             | No hay pool DHCP para el segmento.                         |
      | gatewayNoExcluido       | De vez en cuando un PC de TI recibe la IP 192.168.10.65 y aparece un conflicto de IP con el router.      | El gateway no está excluido del DHCP.                      |
      | puertoOtraVlan          | Los PC de TI reciben una IP de la red de VENTAS (192.168.10.0/26).                                       | Los puertos de acceso del segmento están en otra VLAN.     |
      | troncalSinVlan          | Los PC de TI quedan con 169.254.x.x; en el switch sus puertos están en la VLAN 20.                       | El troncal no permite la VLAN del segmento.                |
      | nativaDistinta          | El switch avisa de native VLAN mismatch en el troncal hacia el router.                                   | La VLAN nativa del troncal no coincide con la del router.  |
