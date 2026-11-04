Feature: Formulario del Diseñador con varios routers
  SPEC-003 T3. Con sedes además de la primera, el formulario arma una red
  con un router por sede: la sede 1 con sus opciones de siempre y las demás
  con su red base y sus segmentos.

  Background:
    Given el formulario con la red "192.168.10.0/24" y los segmentos "A:50,B:25,C:12,D:5"

  Scenario: El parcial desde el formulario (SPEC-003-RF13)
    Given la sede 2 del formulario con la red "192.168.20.0/24" y los segmentos "A:50,B:25,C:12,D:5"
    And la red de enlaces del formulario es "10.0.0.0/30"
    When diseño
    Then los equipos del diseño son "SW1,R1,SW2,R2"
    And la verificación pide en "R1" el comando "ping 10.0.0.2" y espera "Responde: el enlace con R2 está arriba."
    And la verificación pide en "R2" el comando "show ip route" y espera "Las redes de las otras sedes aparecen con S (estáticas)."

  Scenario: Con OSPF la verificación espera rutas O (SPEC-003-RF13)
    Given la sede 2 del formulario con la red "192.168.20.0/24" y los segmentos "A:50"
    And la red de enlaces del formulario es "10.0.0.0/30"
    And el enrutamiento del formulario es "ospf"
    When diseño
    Then la verificación pide en "R1" el comando "show ip route" y espera "Las redes de las otras sedes aparecen con O (OSPF)."

  Scenario: Un error de otra sede dice de cuál es (SPEC-003-RF13)
    Given la sede 2 del formulario con la red "192.168.20.0" y los segmentos "A:50"
    And la red de enlaces del formulario es "10.0.0.0/30"
    When diseño
    Then el formulario dice "Sede 2: Escribe la red base con su prefijo, p. ej. 192.168.10.0/24."

  Scenario: Con varios routers cada sede es router-on-a-stick (SPEC-003-RF13)
    Given la topología del formulario es switch capa 3
    And la sede 2 del formulario con la red "192.168.20.0/24" y los segmentos "A:50"
    And la red de enlaces del formulario es "10.0.0.0/30"
    When diseño
    Then los equipos del diseño son "SW1,R1,SW2,R2"

  Scenario: Auditar usa el plan de la sede del equipo pegado (SPEC-003-RF13)
    Given la sede 2 del formulario con la red "192.168.20.0/24" y los segmentos "A:50"
    And la red de enlaces del formulario es "10.0.0.0/30"
    When diseño
    Then la configuración de "R1" auditada contra su plan no tiene hallazgos
    And la configuración de "R2" auditada contra su plan no tiene hallazgos
    And la configuración de "SW2" auditada contra su plan no tiene hallazgos
    And un texto sin hostname se audita contra la red "192.168.10.0"

  Scenario: Con un solo router todo sigue igual (SPEC-003-RF13)
    When diseño
    Then los equipos del diseño son "SW1,R1"
    And el diseño no tiene varios routers
