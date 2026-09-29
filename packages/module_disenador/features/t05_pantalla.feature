Feature: Pantalla del Diseñador de red
  En la pestaña Datos se escriben la red base, los segmentos y las opciones;
  al tocar Diseñar se llenan las pestañas Plan, Configuración y Verificación,
  y en Auditar se compara una running-config pegada contra ese plan.

  Scenario: Antes de diseñar, los resultados piden los datos
    Given la pantalla del Diseñador
    When abro la pestaña "Plan"
    Then veo "Completa los datos y toca Diseñar."

  Scenario: El ejemplo inicial se diseña con un toque
    Given la pantalla del Diseñador
    When toco "Diseñar"
    Then veo "VENTAS · VLAN 10"
    And veo "Red 192.168.10.0/26 · máscara 255.255.255.192"
    And veo "Gateway 192.168.10.1 · DHCP 192.168.10.2 – 192.168.10.62"
    And veo "50 hosts · uso del DHCP 81 %"
    And veo "TI · VLAN 20"
    And veo "Quedan 160 direcciones libres en la red base."

  Scenario: La configuración de cada equipo lista para copiar
    Given la pantalla del Diseñador
    When toco "Diseñar"
    And abro la pestaña "Configuración"
    Then veo "SW1"
    And veo "R1"
    And veo el texto que contiene "encapsulation dot1Q 10"
    When toco "Copiar R1"
    Then veo "Configuración de R1 copiada."

  Scenario: Con switch capa 3 sale un solo equipo con enrutamiento
    Given la pantalla del Diseñador
    Then veo "Router-on-a-stick"
    When elijo "Switch capa 3"
    And toco "Diseñar"
    And abro la pestaña "Configuración"
    Then veo el texto que contiene "ip routing"
    And no veo "R1"

  Scenario: Opciones de direccionamiento y servicios
    Given la pantalla del Diseñador
    When escribo "2" en "IPs reservadas por segmento"
    And escribo "8.8.8.8" en "DNS"
    And activo "Gateway en la última IP útil"
    And toco "Diseñar"
    Then veo "Gateway 192.168.10.62 · DHCP 192.168.10.3 – 192.168.10.61"
    And veo "Reservadas 192.168.10.1 – 192.168.10.2"
    When abro la pestaña "Configuración"
    Then veo el texto que contiene "dns-server 8.8.8.8"

  Scenario: Agregar y quitar segmentos
    Given la pantalla del Diseñador
    When toco "Agregar segmento"
    And escribo "LAB" en el nombre del segmento 3
    And escribo "10" en los hosts del segmento 3
    And quito el segmento 2
    And toco "Diseñar"
    Then veo "LAB · VLAN 20"
    And no veo "TI · VLAN 20"

  Scenario: Un dato mal escrito muestra el problema sin diseñar
    Given la pantalla del Diseñador
    When escribo "10.0.0.0" en "Red base"
    And toco "Diseñar"
    Then veo "Escribe la red base con su prefijo, p. ej. 192.168.10.0/24."

  Scenario: El plan de verificación
    Given la pantalla del Diseñador
    When toco "Diseñar"
    And abro la pestaña "Verificación"
    Then veo "R1 · show ip dhcp binding"
    And veo "Aparecen las PCs con direcciones de los pools"

  Scenario: Auditar una running-config contra el plan
    Given la pantalla del Diseñador
    When toco "Diseñar"
    And abro la pestaña "Auditar"
    Then veo "Pega el show running-config de un equipo de la red."
    And veo "running-config"
    When pego la running-config:
      """
      interface Vlan10
       ip address 192.168.10.1 255.255.255.0
      """
    And toco "Auditar"
    Then veo "CRÍTICO"
    And veo "VENTAS: el gateway 192.168.10.1 tiene máscara 255.255.255.0; el plan dice 255.255.255.192."
    And veo "ip address 192.168.10.1 255.255.255.192"

  Scenario: Una running-config que coincide con el plan
    Given la pantalla del Diseñador
    When toco "Diseñar"
    And abro la pestaña "Auditar"
    And pego la running-config:
      """
      interface Vlan10
       ip address 192.168.10.1 255.255.255.192
      interface Vlan20
       ip address 192.168.10.65 255.255.255.224
      """
    And toco "Auditar"
    Then veo "Sin diferencias con el plan."

  Scenario: Lo auditado se conserva al cambiar de pestaña y se borra al rediseñar
    Given la pantalla del Diseñador
    When toco "Diseñar"
    And abro la pestaña "Auditar"
    And pego la running-config:
      """
      interface Vlan10
       ip address 192.168.10.1 255.255.255.192
      interface Vlan20
       ip address 192.168.10.65 255.255.255.224
      """
    And toco "Auditar"
    And abro la pestaña "Plan"
    And abro la pestaña "Auditar"
    Then veo "Sin diferencias con el plan."
    When abro la pestaña "Datos"
    And toco "Diseñar"
    And abro la pestaña "Auditar"
    Then no veo "Sin diferencias con el plan."
