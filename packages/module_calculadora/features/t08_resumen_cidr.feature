Feature: Resumen de rutas CIDR
  En "Conversión" → "Sumarizar rutas" la app revisa la ruta resumen con las
  cinco preguntas de la Clase 18 (mismo salto, contiguas, potencia de dos,
  alineadas y rango cubierto), dice si se puede anunciar y arma el comando
  ip route hacia el siguiente salto.

  Scenario: Cuatro /24 contiguas y alineadas forman un /22 exacto
    Given la pestaña "Conversión" con las redes "192.168.0.0/24, 192.168.1.0/24, 192.168.2.0/24, 192.168.3.0/24"
    Then la fila "Ruta resumen:" dice "192.168.0.0/22"
    And la fila "Rango cubierto:" dice "192.168.0.0 – 192.168.3.255"
    And la fila "Veredicto:" dice "Válido: cubre exactamente las redes dadas."
    And la explicación menciona "4. Alineadas: sí, empiezan en 192.168.0.0, inicio del bloque /22."

  Scenario: Las subredes VLSM del parcial se resumen en un /25 con direcciones libres
    Given la pestaña "Conversión" con las redes "192.168.10.0/26, 192.168.10.64/27, 192.168.10.96/28, 192.168.10.112/29"
    Then la fila "Ruta resumen:" dice "192.168.10.0/25"
    And la fila "Rango cubierto:" dice "192.168.10.0 – 192.168.10.127"
    And la fila "Veredicto:" dice "Válido solo si estas direcciones también van a ese router o están libres: 192.168.10.120/29."
    And la explicación menciona "3. Potencia de dos: no, suman 120 direcciones."

  Scenario: Falta una red intermedia
    Given la pestaña "Conversión" con las redes "192.168.0.0/24, 192.168.2.0/24"
    Then la fila "Veredicto:" dice "No válido: falta 192.168.1.0/24 entre las redes; el resumen le enviaría ese tráfico al mismo salto."
    And la explicación menciona "2. Contiguas: no, falta 192.168.1.0/24."

  Scenario: Redes contiguas pero sin alinear
    Given la pestaña "Conversión" con las redes "192.168.1.0/24, 192.168.2.0/24"
    Then la fila "Ruta resumen:" dice "192.168.0.0/22"
    And la fila "Veredicto:" dice "Válido solo si estas direcciones también van a ese router o están libres: 192.168.0.0/24, 192.168.3.0/24."
    And la explicación menciona "4. Alineadas: no, empiezan en 192.168.1.0 pero el bloque /22 empieza en 192.168.0.0."

  Scenario: Comando ip route hacia el siguiente salto
    Given la pestaña "Conversión" con las redes "192.168.10.0/26, 192.168.10.64/27, 192.168.10.96/28, 192.168.10.112/29"
    When escribo el siguiente salto "10.0.0.2"
    Then la fila "Comando:" dice "ip route 192.168.10.0 255.255.255.128 10.0.0.2"

  Scenario: Sin siguiente salto el comando deja el marcador
    Given la pestaña "Conversión" con las redes "192.168.0.0/24, 192.168.1.0/24, 192.168.2.0/24, 192.168.3.0/24"
    Then la fila "Comando:" dice "ip route 192.168.0.0 255.255.252.0 [siguiente salto]"

  Scenario: Siguiente salto inválido
    Given la pestaña "Conversión" con las redes "192.168.0.0/24, 192.168.1.0/24"
    When escribo el siguiente salto "10.0.0.300"
    Then veo el error "Siguiente salto inválido: 10.0.0.300 (usa a.b.c.d)."
