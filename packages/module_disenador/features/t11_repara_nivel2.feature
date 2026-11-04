Feature: Nivel 2 de "Repara la red": escribir la corrección
  SPEC-002 T2. En el nivel 2 el estudiante no elige la causa: escribe los
  comandos en el equipo que elija y Nettia los aplica y vuelve a auditar.

  Background:
    Given la pestaña con un ejercicio de la falla "subinterfazApagada" en "TI" de la red "192.168.10.0/24" con "VENTAS:50,TI:20"
    When toco "Nuevo ejercicio"
    And elijo el nivel "Nivel 2: escribir la corrección"

  Scenario: El nivel 2 no muestra las causas (SPEC-002-RF6, RF7)
    Then no veo "¿Cuál es la causa?"
    And veo "Síntoma"
    And veo "show running-config de R1"
    And veo "Escribe la corrección"

  Scenario: Los comandos correctos reparan la red (SPEC-002-RF7, RF8)
    When en el equipo "R1" escribo "int g0/0/0.20;no shutdown"
    And toco "Aplicar y auditar"
    Then veo "¡Red reparada! El auditor ya no encuentra problemas."

  Scenario: Sin reparar se ven los problemas sin la solución (SPEC-002-RF8, RF9, RF10)
    When en el equipo "SW1" escribo "int g0/1;router rip"
    And toco "Aplicar y auditar"
    Then veo "Todavía hay problemas:"
    And veo "TI: GigabitEthernet0/0/0.20 está apagada (shutdown)."
    And veo "No reconocido: router rip"
    And no veo la solución
    When toco "Ver la solución"
    Then veo la solución

  Scenario: Lo aplicado se acumula y se ve en la configuración (SPEC-002-RF7)
    When en el equipo "R1" escribo "int g0/0/0.20;description PRUEBA"
    And toco "Aplicar y auditar"
    And en el equipo "R1" escribo "int g0/0/0.20;no shutdown"
    And toco "Aplicar y auditar"
    Then veo "¡Red reparada! El auditor ya no encuentra problemas."
    And la configuración de "R1" muestra " description PRUEBA"

  Scenario: Volver al nivel 1 muestra las causas (SPEC-002-RF6)
    When elijo el nivel "Nivel 1: elegir la causa"
    Then veo "¿Cuál es la causa?"
