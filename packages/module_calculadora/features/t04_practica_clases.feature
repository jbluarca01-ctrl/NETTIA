Feature: Ejercicios de práctica de las Clases 13 a 17
  La pestaña "Práctica" trae los ejercicios que se piden en clase: red y
  broadcast de una IP con AND, clase y tipo de una IP, si una dirección se
  puede asignar a un host, y VLSM de 4 redes con red y broadcast.

  Scenario: Red y broadcast de 192.168.45.100/19 (Clase 13)
    Given el ejercicio de red para "192.168.45.100/19"
    Then la respuesta de "Dirección de red" es "192.168.32.0"
    And la respuesta de "Broadcast" es "192.168.63.255"
    And la respuesta de "Primer host útil" es "192.168.32.1"
    And la respuesta de "Último host útil" es "192.168.63.254"
    And el procedimiento incluye "45 AND 224 = 32"
    And el procedimiento incluye "Bloque = 256 − 224 = 32"

  Scenario: A qué subred pertenece 192.168.10.200/26 (ticket de la Clase 15)
    Given el ejercicio de red para "192.168.10.200/26"
    Then la respuesta de "Dirección de red" es "192.168.10.192"
    And la respuesta de "Broadcast" es "192.168.10.255"

  Scenario: Máscara que corta entre octetos
    Given el ejercicio de red para "172.16.5.20/16"
    Then la respuesta de "Dirección de red" es "172.16.0.0"
    And la respuesta de "Broadcast" es "172.16.255.255"
    And el procedimiento incluye "los 2 primeros octetos son de red"

  Scenario Outline: Clase y tipo (Clase 14)
    Given el ejercicio de clasificar "<ip>"
    Then la respuesta de "Clase" es "<clase>"
    And la respuesta de "Tipo" es "<tipo>"

    Examples:
      | ip              | clase | tipo         |
      | 172.15.1.1      | B     | publica      |
      | 10.15.3.7       | A     | privada      |
      | 169.254.10.5    | B     | apipa        |
      | 127.0.0.1       | A     | loopback     |
      | 224.10.10.10    | D     | multicast    |
      | 240.0.0.1       | E     | experimental |
      | 255.255.255.255 | E     | broadcast    |

  Scenario: Las tildes y mayúsculas no cuentan al corregir
    Given el ejercicio de clasificar "8.8.8.8"
    When respondo "a" y "Pública"
    Then todo está correcto

  Scenario Outline: ¿Se puede asignar a un host? (Clases 13 y 16)
    Given el ejercicio de asignar "<ip>"
    Then la respuesta de "¿Se puede asignar a un host? (si/no)" es "<resp>"
    And el procedimiento incluye "<motivo>"

    Examples:
      | ip                | resp | motivo                            |
      | 192.168.20.0/25   | no   | es la dirección de red            |
      | 192.168.20.127/25 | no   | es el broadcast                   |
      | 192.168.20.126/25 | si   | está entre la red y el broadcast  |
      | 10.0.0.5/31       | si   | punto a punto                     |
      | 10.0.0.4/31       | si   | punto a punto                     |

  Scenario: VLSM de 4 redes como en la Clase 17
    Given el ejercicio VLSM de "192.168.10.0/24" con 50, 25, 12 y 5 hosts
    Then la respuesta de "Red A: prefijo" es "/26"
    And la respuesta de "Red B: dirección de red" es "192.168.10.64"
    And la respuesta de "Red C: broadcast" es "192.168.10.111"
    And la respuesta de "Red D: prefijo" es "/29"
    And la respuesta de "Red D: broadcast" es "192.168.10.119"

  Scenario: Los ejercicios nuevos aparecen en la pestaña
    Given la pestaña "Práctica"
    Then hay un ejercicio "Red y broadcast de una IP"
    And hay un ejercicio "Clase y tipo de una IP"
    And hay un ejercicio "¿Se puede asignar?"
