Feature: Pestaña "Repara la red"
  SPEC-001 T2. En el Diseñador, la pestaña "Repara la red" muestra el
  síntoma y la running-config de los equipos; el estudiante elige la causa
  y al comprobar ve si acertó y el diagnóstico del auditor.

  Scenario: La pestaña está en el Diseñador y arranca vacía (SPEC-001-RF4)
    Given la pantalla del Diseñador
    When abro la pestaña "Repara la red"
    Then veo "Toca Nuevo ejercicio para empezar."

  Scenario: Un ejercicio al azar muestra su síntoma y sus 4 causas (SPEC-001-RF4)
    Given la pantalla del Diseñador
    When abro la pestaña "Repara la red"
    And toco "Nuevo ejercicio"
    Then veo "Síntoma"
    And veo "¿Cuál es la causa?"
    And hay 4 causas para elegir

  Scenario: El ejercicio muestra el síntoma y la configuración de los equipos (SPEC-001-RF4)
    Given la pestaña con un ejercicio de la falla "sinPool" en "TI" de la red "192.168.10.0/24" con "VENTAS:50,TI:20"
    When toco "Nuevo ejercicio"
    Then veo "Los PC de TI quedan con 169.254.x.x; las demás VLAN reciben IP sin problema."
    And veo "show running-config de SW1"
    And veo "show running-config de R1"

  Scenario: Comprobar sin elegir pide una causa (SPEC-001-RF7)
    Given la pestaña con un ejercicio de la falla "sinPool" en "TI" de la red "192.168.10.0/24" con "VENTAS:50,TI:20"
    When toco "Nuevo ejercicio"
    And toco "Comprobar"
    Then veo "Elige una causa antes de comprobar."
    And no veo el resultado

  Scenario: Elegir la causa correcta (SPEC-001-RF5)
    Given la pestaña con un ejercicio de la falla "sinPool" en "TI" de la red "192.168.10.0/24" con "VENTAS:50,TI:20"
    When toco "Nuevo ejercicio"
    And elijo "No hay pool DHCP para el segmento."
    And toco "Comprobar"
    Then la única causa marcada es "No hay pool DHCP para el segmento."
    And veo el resultado "Correcto: No hay pool DHCP para el segmento."

  Scenario: Elegir otra causa muestra la correcta y el diagnóstico (SPEC-001-RF5, RF6)
    Given la pestaña con un ejercicio de la falla "sinPool" en "TI" de la red "192.168.10.0/24" con "VENTAS:50,TI:20"
    When toco "Nuevo ejercicio"
    And elijo una causa incorrecta
    And toco "Comprobar"
    Then veo "Incorrecto. La causa era: No hay pool DHCP para el segmento."
    And veo "TI: no hay pool DHCP para 192.168.10.64/27."
    And veo "default-router 192.168.10.65"

  Scenario: Un nuevo ejercicio borra la respuesta anterior
    Given la pestaña con un ejercicio de la falla "sinPool" en "TI" de la red "192.168.10.0/24" con "VENTAS:50,TI:20"
    When toco "Nuevo ejercicio"
    And toco "Comprobar"
    And elijo "No hay pool DHCP para el segmento."
    And toco "Comprobar"
    And toco "Nuevo ejercicio"
    Then no veo el resultado
    And no veo "Elige una causa antes de comprobar."
