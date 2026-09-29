Feature: Pestaña "Doctor" en Comandos CLI
  Se pegan los mensajes tal como salieron en la consola (errores de IOS,
  syslog o el ping de una PC) y la pestaña muestra cada problema con su
  causa y los pasos o comandos que lo corrigen.

  Scenario: Un error de IOS muestra la causa y la corrección
    Given la pestaña Doctor abierta
    When pego y diagnostico:
      """
      Router>configure terminal
             ^
      % Invalid input detected at '^' marker.
      """
    Then veo "1 problema encontrado"
    And veo "Comando no reconocido"
    And veo el texto que contiene "en el modo usuario (Router>)"
    And veo "Estás en modo usuario: entra primero con enable."
    And no veo el texto que contiene "No reconozco"

  Scenario: Varios mensajes de syslog muestran cada corrección
    Given la pestaña Doctor abierta
    When pego y diagnostico:
      """
      %LINK-5-CHANGED: Interface GigabitEthernet0/0, changed state to administratively down
      %LINK-3-UPDOWN: Interface FastEthernet0/5, changed state to down
      """
    Then veo "2 problemas encontrados"
    And veo "Interfaz apagada"
    And veo "interface GigabitEthernet0/0"
    And veo "Enlace caído"

  Scenario: Texto sin mensajes conocidos
    Given la pestaña Doctor abierta
    When pego y diagnostico:
      """
      Router#show clock
      """
    Then veo "No reconozco ningún mensaje de IOS, syslog ni ping. Pega el texto tal como salió en la consola."
    And no veo el texto que contiene "problema"

  Scenario: Antes de diagnosticar no hay resultados
    Given la pestaña Doctor abierta
    Then no veo el texto que contiene "No reconozco"
    And no veo el texto que contiene "problema"

  Scenario: Es la sexta pestaña de Comandos CLI
    Given la pantalla de Comandos CLI
    When abro la pestaña "Doctor"
    Then veo "Doctor de consola"

  Scenario: El diagnóstico se conserva al cambiar de pestaña
    Given la pantalla de Comandos CLI
    When abro la pestaña "Doctor"
    And pego y diagnostico:
      """
      Request timed out.
      """
    And abro la pestaña "Switch (VLANs)"
    And abro la pestaña "Doctor"
    Then veo "1 problema encontrado"
    And veo "Ping sin respuesta"
