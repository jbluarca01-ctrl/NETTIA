Feature: Enlaces punto a punto /31
  En un /31 (máscara 255.255.255.254) solo hay 2 direcciones y ambas se
  usan, una por extremo del enlace; no hay broadcast útil (Clase 13,
  RFC 3021).

  Scenario: /31 en la pestaña Red
    Given la pestaña "Red" con la IP "10.0.0.5" y el prefijo "/31"
    Then la fila "Dirección de Red:" dice "10.0.0.4"
    And la fila "Primer Host:" dice "10.0.0.4"
    And la fila "Último Host:" dice "10.0.0.5"
    And la fila "Broadcast:" dice "No tiene (punto a punto)"
    And la fila "Gateway Sugerido:" dice "No aplica (punto a punto)"
    And la fila "Capacidad:" dice "2 hosts útiles (enlace punto a punto)"
    And hay 1 fila "Broadcast:"

  Scenario: El selector de CIDR llega hasta /31
    Given la pestaña "Red" con la IP "10.0.0.5"
    Then el selector de CIDR va de "/1" a "/31"

  Scenario: /31 escrito como máscara decimal
    Given la pestaña "Red" con la IP "10.0.0.4" y la máscara "255.255.255.254"
    Then la fila "Máscara Decimal:" dice "255.255.255.254 (/31)"
    And la fila "Último Host:" dice "10.0.0.5"

  Scenario: /30 no cambia
    Given la pestaña "Red" con la IP "10.0.0.5" y el prefijo "/30"
    Then la fila "Broadcast:" dice "10.0.0.7"
    And la fila "Primer Host:" dice "10.0.0.5"
    And la fila "Último Host:" dice "10.0.0.6"
    And la fila "Gateway Sugerido:" dice "10.0.0.5"
    And la fila "Capacidad:" dice "2 hosts útiles"
    And hay 2 filas "Broadcast:"

  Scenario: /24 sigue con 254 hosts
    Given la pestaña "Red" con la IP "192.168.1.1" y el prefijo "/24"
    Then la fila "Capacidad:" dice "254 hosts útiles"

  Scenario: La máscara más corta (/1) también se reconoce
    Given la pestaña "Red" con la IP "10.0.0.5" y la máscara "128.0.0.0"
    Then la fila "Máscara Decimal:" dice "128.0.0.0 (/1)"

  Scenario: Una máscara no contigua avisa el rango válido
    Given la pestaña "Red" con la IP "10.0.0.5" y la máscara "255.0.255.0"
    Then la explicación menciona "Debe ser una máscara de subred contigua (/1 a /31)."

  Scenario: Conversión de /31
    Given la pestaña "Conversión" con la máscara "/31"
    Then la fila "Hosts útiles:" dice "2"
