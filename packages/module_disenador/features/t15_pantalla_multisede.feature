Feature: Pantalla del Diseñador con varios routers
  SPEC-003 T4. En Datos se eligen los routers (1 a 6); con 2 o más aparecen
  las sedes, la red de enlaces (sin valor por defecto) y el enrutamiento. El
  plan muestra cada sede con su resumen y los enlaces.

  Background:
    Given la pantalla del Diseñador

  Scenario: Con un router no hay sedes ni enlaces (SPEC-003-RF14)
    Then veo "Routers"
    And los routers que se pueden elegir son "1,2,3,4,5,6"
    And veo "Topología"
    And veo "Segmentos: nombre y hosts"
    And veo "Nombre"
    And no veo "Sede 1 (R1)"
    And no veo "Red de enlaces entre routers"

  Scenario: Con dos routers aparecen la sede 2, los enlaces y el enrutamiento (SPEC-003-RF14)
    When elijo "2"
    Then veo "Sede 1 (R1)"
    And veo "Sede 2 (R2)"
    And veo "Enrutamiento"
    And no veo "Topología"
    And el campo "red_enlaces" está vacío con la pista "0.0.0.0/0"
    And "Estática resumida" está elegido
    And no veo "Sede 3 (R3)"
    And la etiqueta del campo "red_enlaces" es "Red de enlaces entre routers"

  Scenario: Dos routers diseñados: plan por sede, enlaces y configuración (SPEC-003-RF14, RF15)
    When elijo "2"
    And escribo "192.168.20.0/24" en la clave "sede2_red"
    And escribo "A" en la clave "sede2_nombre_1"
    And escribo "50" en la clave "sede2_hosts_1"
    And escribo "10.0.0.0/30" en la clave "red_enlaces"
    And toco "Diseñar"
    Then veo "Sede 1 (R1) · 192.168.10.0/24 · resumen 192.168.10.0/25"
    And veo "Sede 2 (R2) · 192.168.20.0/24 · resumen 192.168.20.0/26"
    And veo "Enlaces entre routers"
    And veo "R1 10.0.0.1 ↔ R2 10.0.0.2 · red 10.0.0.0/30"
    And veo "Enrutamiento: Estática resumida"
    When abro la pestaña "Configuración"
    Then veo "Copiar R2"
    And la configuración de "R1" tiene la línea "ip route 192.168.20.0 255.255.255.192 10.0.0.2"

  Scenario: Con OSPF el plan lo dice (SPEC-003-RF14, RF15)
    When elijo "2"
    And escribo "192.168.20.0/24" en la clave "sede2_red"
    And escribo "A" en la clave "sede2_nombre_1"
    And escribo "50" en la clave "sede2_hosts_1"
    And escribo "10.0.0.0/30" en la clave "red_enlaces"
    And elijo "OSPF"
    And toco "Diseñar"
    Then veo "Enrutamiento: OSPF"

  Scenario: Sin red de enlaces el diseño la pide (SPEC-003-RF4, RF14)
    When elijo "2"
    And escribo "192.168.20.0/24" en la clave "sede2_red"
    And escribo "A" en la clave "sede2_nombre_1"
    And escribo "50" en la clave "sede2_hosts_1"
    And toco "Diseñar"
    Then veo "Escribe la red de los enlaces entre routers, p. ej. 10.0.0.0/30."

  Scenario: Auditar la configuración de R2 usa el plan de la sede 2 (SPEC-003-RF15, SPEC-004-RF12)
    When elijo "2"
    And escribo "192.168.20.0/24" en la clave "sede2_red"
    And escribo "A" en la clave "sede2_nombre_1"
    And escribo "50" en la clave "sede2_hosts_1"
    And escribo "10.0.0.0/30" en la clave "red_enlaces"
    And toco "Diseñar"
    And abro la pestaña "Configuración"
    And copio la configuración de "R2"
    And abro la pestaña "Auditar"
    And pego lo copiado
    And toco "Auditar"
    Then veo "R2 · running-config"
    And veo "Sin diferencias."

  Scenario: Con tres routers se avisa de G0/0/2 y al bajar a dos se va la sede 3 (SPEC-003-RF14)
    When elijo "3"
    Then veo "Sede 3 (R3)"
    And veo "Los routers del medio usan GigabitEthernet0/0/2 para el segundo enlace: si tu router no la trae, agrégale el módulo en Packet Tracer."
    When elijo "2"
    Then no veo "Sede 3 (R3)"
    And no veo el texto que contiene "GigabitEthernet0/0/2"

  Scenario: Agregar y quitar segmentos de otra sede (SPEC-003-RF14)
    When elijo "2"
    And toco "Agregar segmento a la sede 2"
    Then hay un campo con la clave "sede2_nombre_2"
    When en la sede 2 quito el segmento 1
    Then no hay un campo con la clave "sede2_nombre_2"

  Scenario: Con estáticas por subred el plan lo dice (SPEC-003-RF14, RF15)
    When elijo "2"
    And escribo "192.168.20.0/24" en la clave "sede2_red"
    And escribo "A" en la clave "sede2_nombre_1"
    And escribo "50" en la clave "sede2_hosts_1"
    And escribo "10.0.0.0/30" en la clave "red_enlaces"
    And elijo "Estática por subred"
    And toco "Diseñar"
    Then veo "Enrutamiento: Estática por subred"

  Scenario: Con varios routers la sede 1 puede tener varios switches aunque antes eligiera capa 3 (SPEC-003-RF14)
    When elijo "Switch capa 3"
    And elijo "2"
    Then veo "Switches"
    When elijo "2 switches"
    Then veo "Segmentos: nombre y PC por switch"
    And veo "SW2"

  Scenario: Con un router y capa 3 los segmentos van con hosts aunque se hayan pedido 2 switches (SPEC-003-RF14)
    When elijo "2 switches"
    And elijo "Switch capa 3"
    Then veo "Segmentos: nombre y hosts"
    And no veo "SW2"
    And veo "Hosts"

  Scenario: Al cambiar los routers, las sedes que quedan conservan lo escrito (SPEC-003-RF14)
    When elijo "2"
    And escribo "192.168.20.0/24" en la clave "sede2_red"
    And elijo "3"
    Then el campo "sede2_red" dice "192.168.20.0/24"
    When elijo "2"
    Then el campo "sede2_red" dice "192.168.20.0/24"
