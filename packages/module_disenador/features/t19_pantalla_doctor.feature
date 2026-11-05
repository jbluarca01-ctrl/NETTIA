Feature: Auditar con varios routers (doctor de redes)
  SPEC-004 T5. Con varios routers, Auditar acepta varias salidas pegadas,
  deja elegir si se revisa como Estática u OSPF (por defecto lo del
  diseño) y muestra los hallazgos por equipo y el camino entre sedes.

  Background:
    Given la pantalla del Diseñador
    When elijo "2"
    And escribo "192.168.20.0/24" en la clave "sede2_red"
    And escribo "A" en la clave "sede2_nombre_1"
    And escribo "50" en la clave "sede2_hosts_1"
    And escribo "10.0.0.0/30" en la clave "red_enlaces"

  Scenario: El modo empieza como el del diseño y las dos configuraciones pasan (SPEC-004-RF5, RF12)
    When toco "Diseñar"
    And abro la pestaña "Configuración"
    And copio la configuración de "R1"
    And copio también la configuración de "R2"
    And abro la pestaña "Auditar"
    Then "Estática" está elegido para revisar
    And veo "Revisar enrutamiento como"
    When pego lo copiado
    And toco "Auditar"
    Then veo "Sin diferencias con el diseño."
    And veo "R1 · running-config"
    And veo "R2 · running-config"
    And veo "Camino entre sedes"
    And veo "Llega de cada sede a cada otra, ida y vuelta."

  Scenario: Un enlace apagado y el pedido del otro router (SPEC-004-RF2, RF6, RF12)
    When toco "Diseñar"
    And abro la pestaña "Auditar"
    And pego la running-config:
      """
      hostname R1
      interface GigabitEthernet0/0/1
       ip address 10.0.0.1 255.255.255.252
       shutdown
      """
    And toco "Auditar"
    Then veo "R1: GigabitEthernet0/0/1 (enlace con R2) está apagada."
    And veo "Para revisar el camino entre todas las sedes pega también: R2."
    And no veo "Sin diferencias con el diseño."

  Scenario: Cambiar a OSPF revisa como OSPF (SPEC-004-RF4, RF5, RF12)
    When toco "Diseñar"
    And abro la pestaña "Configuración"
    And copio la configuración de "R1"
    And abro la pestaña "Auditar"
    And elijo "OSPF"
    And pego lo copiado
    And toco "Auditar"
    Then "OSPF" está elegido para revisar
    And veo "R1: no tiene router ospf."

  Scenario: Con OSPF en el diseño el modo empieza en OSPF (SPEC-004-RF5)
    When elijo "OSPF"
    And toco "Diseñar"
    And abro la pestaña "Auditar"
    Then "OSPF" está elegido para revisar

  Scenario: Diseñar de nuevo vuelve al modo del diseño y borra el resultado (SPEC-004-RF5)
    When toco "Diseñar"
    And abro la pestaña "Auditar"
    And elijo "OSPF"
    And pego la running-config:
      """
      hostname R1
      """
    And toco "Auditar"
    And abro la pestaña "Datos"
    And toco "Diseñar"
    And abro la pestaña "Auditar"
    Then "Estática" está elegido para revisar
    And no veo "R1 · running-config"

  Scenario: Si no se pegó nada reconocible se dice (SPEC-004-RF12)
    When toco "Diseñar"
    And abro la pestaña "Auditar"
    And pego la running-config:
      """
      nada que ver
      """
    And toco "Auditar"
    Then veo "No se encontró ninguna running-config ni show ip route."

  Scenario: Un switch solo: sin sección de camino (SPEC-004-RF12)
    When toco "Diseñar"
    And abro la pestaña "Configuración"
    And copio la configuración de "SW2"
    And abro la pestaña "Auditar"
    And pego lo copiado
    And toco "Auditar"
    Then veo "SW2 · running-config"
    And veo "Sin diferencias."
    And no veo "Camino entre sedes"
