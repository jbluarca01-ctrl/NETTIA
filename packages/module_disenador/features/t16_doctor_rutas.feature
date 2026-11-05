 no ip route 192.168.0.0 255.255.0.0 10.0.0.2 | ip route 192.168.20.0 255.255.255.128 10.0.0.2 | no ip route 192.168.20.0 255.255.255.128 10.0.0.3;ip route 192.168.20.0 255.255.255.128 10.0.0.2 | interface GigabitEthernet0/0/1;ip address 10.0.0.1 255.255.255.252 | interface GigabitEthernet0/0/1;ip address 10.0.0.1 255.255.255.252;no shutdown |Feature: Doctor de redes sobre la running-config
  SPEC-004 T2. El doctor compara la running-config de cada router con el
  diseño de varios routers: enlaces, rutas estáticas o OSPF y el camino de
  ida y vuelta entre sedes. Caso central: el tercer parcial, con las fallas
  sembradas una por una.

  Background:
    Given el diseño del parcial con el enrutamiento "estaticaResumida"

  Scenario: Sin fallas no hay nada que decir (SPEC-004-RF2, RF3, RF6)
    When reviso "R1,R2" como "estatica"
    Then el doctor no dice nada de "R1"
    And el doctor no dice nada de "R2"
    And el camino entre sedes no tiene problemas

  Scenario Outline: Fallas del enlace y de las rutas en R1 (SPEC-004-RF2, RF3)
    When en "R1" cambio "<antes>" por "<despues>"
    And reviso "R1" como "estatica"
    Then el doctor dice de "R1" solo "<mensaje>"
    And la corrección de "R1" es "<correccion>"

    Examples:
      | antes                                         | despues                                                                       | mensaje                                                                                   | correccion |
      | ip address 10.0.0.1 255.255.255.252           | ip address 10.0.0.5 255.255.255.252                                           | R1: ninguna interfaz tiene 10.0.0.1 (enlace con R2).                                      | interface GigabitEthernet0/0/1;ip address 10.0.0.1 255.255.255.252;no shutdown |
      | ip address 10.0.0.1 255.255.255.252           | ip address 10.0.0.1 255.255.255.0                                             | R1: GigabitEthernet0/0/1 tiene máscara 255.255.255.0; el enlace con R2 es /30.            | interface GigabitEthernet0/0/1;ip address 10.0.0.1 255.255.255.252 |
      | ip route 192.168.20.0 255.255.255.128 10.0.0.2 | ip route 192.168.20.0 255.255.255.128 10.0.0.3                               | R1: la ruta 192.168.20.0/25 sale por 10.0.0.3; hacia la sede 2 el vecino es 10.0.0.2.      | no ip route 192.168.20.0 255.255.255.128 10.0.0.3;ip route 192.168.20.0 255.255.255.128 10.0.0.2 |
      | ip route 192.168.20.0 255.255.255.128 10.0.0.2 | ip route 192.168.20.0 255.255.255.192 10.0.0.2                               | R1: no hay ruta hacia 192.168.20.64/27, 192.168.20.96/28, 192.168.20.112/29 (sede 2).      | ip route 192.168.20.0 255.255.255.128 10.0.0.2 |
      | ip route 192.168.20.0 255.255.255.128 10.0.0.2 | ip route 192.168.0.0 255.255.0.0 10.0.0.2                                    | R1: la ruta 192.168.0.0/16 tapa redes de su propia sede.                                   | no ip route 192.168.0.0 255.255.0.0 10.0.0.2 |

  Scenario: El enlace apagado (SPEC-004-RF2)
    When en "R1" pongo "shutdown" después de "ip address 10.0.0.1 255.255.255.252"
    And reviso "R1" como "estatica"
    Then el doctor dice de "R1" solo "R1: GigabitEthernet0/0/1 (enlace con R2) está apagada."
    And la corrección es "interface GigabitEthernet0/0/1;no shutdown"

  Scenario: Sin ninguna ruta hacia la otra sede, con la corrección (SPEC-004-RF3)
    When en "R1" quito "ip route 192.168.20.0 255.255.255.128 10.0.0.2"
    And reviso "R1" como "estatica"
    Then el doctor dice de "R1" solo "R1: no hay ruta hacia 192.168.20.0/26, 192.168.20.64/27, 192.168.20.96/28, 192.168.20.112/29 (sede 2)."
    And la corrección es "ip route 192.168.20.0 255.255.255.128 10.0.0.2"

  Scenario: Revisar como OSPF una red con estáticas (SPEC-004-RF4, RF5)
    When reviso "R1" como "ospf"
    Then el doctor dice de "R1" "R1: no tiene router ospf."
    And el doctor dice de "R1" "R1 usa rutas estáticas; estás revisando OSPF."

  Scenario: Falta la ruta de regreso: la ida llega, la vuelta no (SPEC-004-RF6)
    When en "R2" quito "ip route 192.168.10.0 255.255.255.128 10.0.0.1"
    And reviso "R1,R2" como "estatica"
    Then el camino entre sedes dice solo "Sede 2 → sede 1 no llega: R2 no tiene ruta hacia la sede 1."
    And el doctor dice de "R2" solo "R2: no hay ruta hacia 192.168.10.0/26, 192.168.10.64/27, 192.168.10.96/28, 192.168.10.112/29 (sede 1)."

  Scenario: Con un solo router pegado se pide el otro para revisar el camino (SPEC-004-RF6)
    When reviso "R1" como "estatica"
    Then el camino entre sedes dice solo "Para revisar el camino entre todas las sedes pega también: R2."

  Scenario: El enlace apagado corta el camino en los dos sentidos (SPEC-004-RF6)
    When en "R2" pongo "shutdown" después de "ip address 10.0.0.2 255.255.255.252"
    And reviso "R1,R2" como "estatica"
    Then el camino entre sedes dice "Sede 1 → sede 2 no llega: R2 tiene apagado el enlace con R1."
    And el camino entre sedes dice "Sede 2 → sede 1 no llega: R2 tiene apagado el enlace con R1."

  Scenario: Sin el enlace configurado se corta el camino en los dos sentidos (SPEC-004-RF6)
    When en "R2" cambio "ip address 10.0.0.2 255.255.255.252" por "ip address 10.0.0.9 255.255.255.252"
    And reviso "R1,R2" como "estatica"
    Then el camino entre sedes dice "Sede 1 → sede 2 no llega: R2 no tiene configurado el enlace con R1."
    And el camino entre sedes dice "Sede 2 → sede 1 no llega: R2 no tiene configurado el enlace con R1."

  Scenario: La ruta de regreso con otro siguiente salto corta la vuelta (SPEC-004-RF6)
    When en "R2" cambio "ip route 192.168.10.0 255.255.255.128 10.0.0.1" por "ip route 192.168.10.0 255.255.255.128 10.0.0.3"
    And reviso "R1,R2" como "estatica"
    Then el camino entre sedes dice solo "Sede 2 → sede 1 no llega: R2 manda a la sede 1 por un siguiente salto equivocado."

  Scenario: OSPF sin fallas (SPEC-004-RF4, RF6)
    Given el diseño del parcial con el enrutamiento "ospf"
    When reviso "R1,R2" como "ospf"
    Then el doctor no dice nada de "R1"
    And el doctor no dice nada de "R2"
    And el camino entre sedes no tiene problemas

  Scenario: OSPF sin anunciar el enlace corta el camino (SPEC-004-RF4, RF6)
    Given el diseño del parcial con el enrutamiento "ospf"
    When en "R2" quito "network 10.0.0.0 0.0.0.3 area 0"
    And reviso "R1,R2" como "ospf"
    Then el doctor dice de "R2" solo "R2: OSPF no anuncia 10.0.0.0/30 (enlace con R1)."
    And el camino entre sedes dice "Sede 1 → sede 2 no llega: R2 no anuncia en OSPF el enlace con R1."

  Scenario: OSPF en otra área no cuenta como anunciado (SPEC-004-RF4)
    Given el diseño del parcial con el enrutamiento "ospf"
    When en "R1" cambio "network 192.168.10.64 0.0.0.31 area 0" por "network 192.168.10.64 0.0.0.31 area 1"
    And reviso "R1,R2" como "ospf"
    Then el doctor dice de "R1" solo "R1: OSPF no anuncia 192.168.10.64/27 (B)."
    And la corrección de "R1" es "router ospf 1;network 192.168.10.64 0.0.0.31 area 0"
    And el camino entre sedes dice solo "Sede 2 → sede 1 no llega: R1 no anuncia en OSPF todos sus segmentos."

  Scenario: Revisar como estáticas una red con OSPF (SPEC-004-RF3, RF5)
    Given el diseño del parcial con el enrutamiento "ospf"
    When reviso "R1" como "estatica"
    Then el doctor dice de "R1" "R1: no hay ruta hacia 192.168.20.0/26, 192.168.20.64/27, 192.168.20.96/28, 192.168.20.112/29 (sede 2)."
    And el doctor dice de "R1" "R1 usa OSPF; estás revisando rutas estáticas."

  Scenario: Sin router ospf, la corrección trae el bloque completo (SPEC-004-RF4)
    When reviso "R2" como "ospf"
    Then la corrección del hallazgo "R2: no tiene router ospf." es "router ospf 1;router-id 2.2.2.2;network 192.168.20.0 0.0.0.63 area 0;network 192.168.20.64 0.0.0.31 area 0;network 192.168.20.96 0.0.0.15 area 0;network 192.168.20.112 0.0.0.7 area 0;network 10.0.0.0 0.0.0.3 area 0"

  Scenario: Tres routers: el del medio sin ruta corta el camino entre las puntas (SPEC-004-RF6)
    Given el diseño de tres sedes con el enrutamiento "estaticaResumida"
    When en "R2" quito "ip route 192.168.30.0 255.255.255.192 10.0.0.6"
    And reviso "R1,R2,R3" como "estatica"
    Then el camino entre sedes dice "Sede 1 → sede 3 no llega: R2 no tiene ruta hacia la sede 3."
    And el camino entre sedes dice "Sede 2 → sede 3 no llega: R2 no tiene ruta hacia la sede 3."
    And el camino entre sedes tiene 2 problemas

  Scenario: Una máscara que no es máscara no cuenta como ruta (SPEC-004-RF3)
    When en "R1" cambio "ip route 192.168.20.0 255.255.255.128 10.0.0.2" por "ip route 192.168.20.0 255.0.255.0 10.0.0.2"
    And reviso "R1" como "estatica"
    Then el doctor dice de "R1" solo "R1: no hay ruta hacia 192.168.20.0/26, 192.168.20.64/27, 192.168.20.96/28, 192.168.20.112/29 (sede 2)."

  Scenario: Con dos rutas iguales hacia la sede vale la primera (SPEC-004-RF3)
    When en "R1" pongo "ip route 192.168.20.0 255.255.255.128 10.0.0.3" después de "ip route 192.168.20.0 255.255.255.128 10.0.0.2"
    And reviso "R1" como "estatica"
    Then el doctor no dice nada de "R1"

  Scenario: La ruta por defecto no tapa las redes propias (SPEC-004-RF3)
    When en "R1" pongo "ip route 0.0.0.0 0.0.0.0 10.0.0.2" después de "ip route 192.168.20.0 255.255.255.128 10.0.0.2"
    And reviso "R1" como "estatica"
    Then el doctor no dice nada de "R1"

  Scenario: Una ruta /1 sí tapa las redes propias (SPEC-004-RF3)
    When en "R1" pongo "ip route 128.0.0.0 128.0.0.0 10.0.0.2" después de "ip route 192.168.20.0 255.255.255.128 10.0.0.2"
    And reviso "R1" como "estatica"
    Then el doctor dice de "R1" solo "R1: la ruta 128.0.0.0/1 tapa redes de su propia sede."

  Scenario: Sin OSPF ni rutas estáticas no hay aviso de otro enrutamiento (SPEC-004-RF5)
    When en "R2" quito "ip route 192.168.10.0 255.255.255.128 10.0.0.1"
    And reviso "R2" como "ospf"
    Then el doctor dice de "R2" solo "R2: no tiene router ospf."

  Scenario: Con tres sedes y un solo router se piden los otros dos (SPEC-004-RF6)
    Given el diseño de tres sedes con el enrutamiento "estaticaResumida"
    When reviso "R1" como "estatica"
    Then el camino entre sedes dice solo "Para revisar el camino entre todas las sedes pega también: R2, R3."

  Scenario: Si ninguno anuncia el enlace, cada sentido nombra al router de salida (SPEC-004-RF6)
    Given el diseño del parcial con el enrutamiento "ospf"
    When en "R1" quito "network 10.0.0.0 0.0.0.3 area 0"
    And en "R2" quito "network 10.0.0.0 0.0.0.3 area 0"
    And reviso "R1,R2" como "ospf"
    Then el camino entre sedes dice "Sede 1 → sede 2 no llega: R1 no anuncia en OSPF el enlace con R2."
    And el camino entre sedes dice "Sede 2 → sede 1 no llega: R2 no anuncia en OSPF el enlace con R1."
