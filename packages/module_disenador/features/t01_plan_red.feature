Feature: Plan de direccionamiento a partir de requisitos
  De una red base y una lista de segmentos (nombre y hosts) sale un plan
  VLSM con VLAN, gateway, rango reservado, rango DHCP y utilización por
  segmento, sin solaparse y dentro de la red base.

  Scenario: Plan básico con el gateway en la primera IP útil
    Given la red base "192.168.10.0/24"
    And el segmento "VENTAS" con 50 hosts
    And el segmento "TI" con 20 hosts
    When planifico la red
    Then el segmento "VENTAS" queda en la VLAN 10 con la red "192.168.10.0/26"
    And el segmento "VENTAS" tiene máscara "255.255.255.192" y wildcard "0.0.0.63"
    And el segmento "VENTAS" tiene gateway "192.168.10.1" y broadcast "192.168.10.63"
    And el segmento "VENTAS" reparte por DHCP "192.168.10.2 – 192.168.10.62" con 61 direcciones
    And el segmento "VENTAS" no reserva direcciones
    And el segmento "VENTAS" tiene una utilización del 81 %
    And el segmento "TI" queda en la VLAN 20 con la red "192.168.10.64/27"
    And el segmento "TI" tiene gateway "192.168.10.65" y broadcast "192.168.10.95"
    And el segmento "TI" reparte por DHCP "192.168.10.66 – 192.168.10.94" con 29 direcciones
    And quedan 160 direcciones libres

  Scenario: IPs reservadas y gateway en la última IP útil
    Given la red base "10.0.0.0/24"
    And el segmento "SERVIDORES" con 10 hosts
    And 5 IPs reservadas por segmento
    And el gateway en la última IP útil
    When planifico la red
    Then el segmento "SERVIDORES" queda en la VLAN 10 con la red "10.0.0.0/27"
    And el segmento "SERVIDORES" tiene gateway "10.0.0.30" y broadcast "10.0.0.31"
    And el segmento "SERVIDORES" reserva "10.0.0.1 – 10.0.0.5"
    And el segmento "SERVIDORES" reparte por DHCP "10.0.0.6 – 10.0.0.29" con 24 direcciones

  Scenario: Margen de crecimiento
    Given la red base "172.16.0.0/24"
    And el segmento "AULA" con 100 hosts
    And un crecimiento del 20 %
    When planifico la red
    Then el segmento "AULA" queda en la VLAN 10 con la red "172.16.0.0/25"
    And el segmento "AULA" tiene una utilización del 80 %

  Scenario: Las VLAN automáticas saltan las ya usadas
    Given la red base "192.168.0.0/24"
    And el segmento "A" con 10 hosts en la VLAN 20
    And el segmento "B" con 10 hosts
    And el segmento "C" con 10 hosts
    When planifico la red
    Then el segmento "A" queda en la VLAN 20 con la red "192.168.0.0/28"
    And el segmento "B" queda en la VLAN 10 con la red "192.168.0.16/28"
    And el segmento "C" queda en la VLAN 30 con la red "192.168.0.32/28"

  Scenario: Los segmentos no caben en la red base
    Given la red base "192.168.1.0/28"
    And el segmento "GRANDE" con 50 hosts
    When planifico la red
    Then el diseño se rechaza con "No caben: al asignar \"GRANDE\" (51 hosts, bloque de 64) se acaba el espacio de 192.168.1.0/28 (16 direcciones). Usa una red más grande."

  Scenario: VLAN repetida
    Given la red base "192.168.0.0/24"
    And el segmento "A" con 10 hosts en la VLAN 20
    And el segmento "B" con 10 hosts en la VLAN 20
    When planifico la red
    Then el diseño se rechaza con "La VLAN 20 está repetida (\"A\" y \"B\")."

  Scenario: VLAN reservada
    Given la red base "192.168.0.0/24"
    And el segmento "A" con 10 hosts en la VLAN 1
    When planifico la red
    Then el diseño se rechaza con "La VLAN 1 no es válida para \"A\": usa 2–1001 o 1006–4094 (la 1 y la 1002–1005 están reservadas)."

  Scenario: VLAN igual a la nativa
    Given la red base "192.168.0.0/24"
    And el segmento "A" con 10 hosts en la VLAN 99
    When planifico la red
    Then el diseño se rechaza con "La VLAN 99 de \"A\" es la VLAN nativa; la nativa no debe llevar usuarios."

  Scenario: Nombre repetido
    Given la red base "192.168.0.0/24"
    And el segmento "Ventas" con 10 hosts
    And el segmento "VENTAS" con 5 hosts
    When planifico la red
    Then el diseño se rechaza con "El nombre \"VENTAS\" está repetido."
