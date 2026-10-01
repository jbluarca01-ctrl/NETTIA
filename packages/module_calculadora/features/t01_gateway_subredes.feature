Feature: Gateway sugerido por subred
  Al dividir una red, cada subred muestra su gateway sugerido (el primer host
  útil, el mismo criterio de la pestaña "Red"), en la tabla y al copiarla.

  Scenario: Dividir muestra el gateway de cada subred
    Given la calculadora en la pestaña "Dividir"
    Then la tabla tiene la columna "Gateway"
    And la fila "2" tiene el gateway "192.168.1.17"
    And la fila "16" tiene el gateway "192.168.1.241"

  Scenario: Copiar la tabla incluye el gateway
    Given la calculadora en la pestaña "Dividir"
    When copio la tabla
    Then el texto copiado tiene la columna "Gateway"
    And el texto copiado tiene la fila "2	192.168.1.16/28	255.255.255.240	192.168.1.17	192.168.1.17	192.168.1.30	192.168.1.31	14"

  Scenario: VLSM también muestra el gateway de cada red
    Given la calculadora en la pestaña "VLSM"
    Then la tabla tiene la columna "Gateway"
    And la fila "LAN 1" tiene el gateway "192.168.1.1"
