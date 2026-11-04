Feature: Ejercicio de "Repara la red"
  SPEC-001 T1. El ejercicio muestra el síntoma y 4 causas posibles; al
  responder dice si acertó, cuál era la causa y qué dice el auditor.

  Background:
    Given un ejercicio de la red base "192.168.10.0/24" con los segmentos "VENTAS:50,TI:20" y la falla "sinPool" en "TI"

  Scenario: Cuatro causas distintas, una es la correcta (SPEC-001-RF4)
    Then hay 4 causas distintas
    And la causa "No hay pool DHCP para el segmento." está entre ellas

  Scenario: Elegir la causa correcta (SPEC-001-RF5)
    When elijo la causa "No hay pool DHCP para el segmento."
    Then la respuesta es correcta

  Scenario: Elegir otra causa (SPEC-001-RF5)
    When elijo una causa que no es la correcta
    Then la respuesta es incorrecta
    And la causa correcta mostrada es "No hay pool DHCP para el segmento."

  Scenario: Al responder se ve el diagnóstico del auditor (SPEC-001-RF6)
    When elijo una causa que no es la correcta
    Then el diagnóstico es "TI: no hay pool DHCP para 192.168.10.64/27."
    And la corrección es "ip dhcp pool TI / network 192.168.10.64 255.255.255.224 / default-router 192.168.10.65"
