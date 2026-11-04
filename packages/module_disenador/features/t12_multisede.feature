Feature: Plan de una red con varios routers
  SPEC-003 T1. Cada sede (su red base y sus segmentos) tiene su router Rk;
  los routers van en cadena unidos por enlaces /30 tomados de la red de
  enlaces que escribe el estudiante, y se enrutan con estáticas resumidas
  (por defecto), estáticas por subred u OSPF. Caso central: el tercer
  parcial (RED1 192.168.10.0, RED2 192.168.20.0, enlace 10.0.0.0/30).

  Background:
    Given la sede 1 "192.168.10.0/24" con "A:50,B:25,C:12,D:5"
    And la sede 2 "192.168.20.0/24" con "A:50,B:25,C:12,D:5"

  Scenario: El parcial con estáticas resumidas (SPEC-003-RF1, RF3, RF5, RF6)
    When planifico con la red de enlaces "10.0.0.0/30" y el enrutamiento "estaticaResumida"
    Then el enlace 1 es "10.0.0.0/30" de "R1 10.0.0.1" a "R2 10.0.0.2"
    And el resumen de la sede 1 es "192.168.10.0/25"
    And el resumen de la sede 2 es "192.168.20.0/25"
    And las rutas de "R1" son "192.168.20.0 255.255.255.128 10.0.0.2"
    And las rutas de "R2" son "192.168.10.0 255.255.255.128 10.0.0.1"

  Scenario: Las VLAN se repiten entre sedes (SPEC-003-RF1)
    When planifico con la red de enlaces "10.0.0.0/30" y el enrutamiento "estaticaResumida"
    Then las VLAN de la sede 1 son "10,20,30,40"
    And las VLAN de la sede 2 son "10,20,30,40"

  Scenario: Tres routers en cadena: la sede lejana va por el vecino (SPEC-003-RF3, RF9)
    Given la sede 3 "192.168.30.0/24" con "A:50"
    When planifico con la red de enlaces "10.0.0.0/29" y el enrutamiento "estaticaResumida"
    Then el enlace 1 es "10.0.0.0/30" de "R1 10.0.0.1" a "R2 10.0.0.2"
    And el enlace 2 es "10.0.0.4/30" de "R2 10.0.0.5" a "R3 10.0.0.6"
    And las rutas de "R1" son "192.168.20.0 255.255.255.128 10.0.0.2,192.168.30.0 255.255.255.192 10.0.0.2"
    And las rutas de "R2" son "192.168.10.0 255.255.255.128 10.0.0.1,192.168.30.0 255.255.255.192 10.0.0.6"
    And las rutas de "R3" son "192.168.10.0 255.255.255.128 10.0.0.5,192.168.20.0 255.255.255.128 10.0.0.5"

  Scenario: Estáticas por subred (SPEC-003-RF7)
    When planifico con la red de enlaces "10.0.0.0/30" y el enrutamiento "estaticaPorSubred"
    Then las rutas de "R1" son "192.168.20.0 255.255.255.192 10.0.0.2,192.168.20.64 255.255.255.224 10.0.0.2,192.168.20.96 255.255.255.240 10.0.0.2,192.168.20.112 255.255.255.248 10.0.0.2"

  Scenario: OSPF anuncia los segmentos y el enlace en el área 0 (SPEC-003-RF8)
    When planifico con la red de enlaces "10.0.0.0/30" y el enrutamiento "ospf"
    Then las redes OSPF de "R1" son "192.168.10.0 0.0.0.63,192.168.10.64 0.0.0.31,192.168.10.96 0.0.0.15,192.168.10.112 0.0.0.7,10.0.0.0 0.0.0.3"
    And el router-id de "R2" es "2.2.2.2"
    And "R1" no tiene rutas estáticas

  Scenario Outline: La red de enlaces se valida (SPEC-003-RF4)
    When planifico con la red de enlaces "<enlaces>" y el enrutamiento "estaticaResumida"
    Then el diseño falla con "<mensaje>"

    Examples:
      | enlaces      | mensaje                                                          |
      | 0.0.0.0/0    | Escribe la red de los enlaces entre routers, p. ej. 10.0.0.0/30. |
      | 10.0.0.0     | Escribe la red de los enlaces entre routers, p. ej. 10.0.0.0/30. |
      | 10.0.0.1/30  | 10.0.0.1/30 no es una dirección de red: usa 10.0.0.0/30.         |
      | 10.0.0.0/31  | La red de enlaces 10.0.0.0/31 no alcanza: se necesitan 1 enlaces /30. |

  Scenario: Sin red de enlaces se pide escribirla (SPEC-003-RF4)
    When planifico sin red de enlaces y con el enrutamiento "ospf"
    Then el diseño falla con "Escribe la red de los enlaces entre routers, p. ej. 10.0.0.0/30."

  Scenario: Tres sedes no caben en un solo /30 (SPEC-003-RF4)
    Given la sede 3 "192.168.30.0/24" con "A:50"
    When planifico con la red de enlaces "10.0.0.0/30" y el enrutamiento "ospf"
    Then el diseño falla con "La red de enlaces 10.0.0.0/30 no alcanza: se necesitan 2 enlaces /30."

  Scenario: Las sedes no pueden solaparse entre sí ni con los enlaces (SPEC-003-RF2)
    Given la sede 3 "192.168.20.128/25" con "A:50"
    When planifico con la red de enlaces "10.0.0.0/29" y el enrutamiento "estaticaResumida"
    Then el diseño falla con "Las redes de la sede 2 y la sede 3 se solapan."

  Scenario: La red de enlaces no puede estar dentro de una sede (SPEC-003-RF2)
    When planifico con la red de enlaces "192.168.10.128/30" y el enrutamiento "estaticaResumida"
    Then el diseño falla con "La red de enlaces se solapa con la sede 1."
