Feature: Pegar varias salidas en Auditar
  SPEC-004 T4. En un solo cuadro se pegan varias running-config y tablas
  show ip route; Nettia las separa, reconoce de qué equipo es cada una (por
  hostname, prompt o sus IP) y las revisa contra el diseño.

  Background:
    Given el diseño del parcial desde el formulario

  Scenario: Dos running-config seguidas, sin prompt (SPEC-004-RF10, RF11, RF12)
    When pego la configuración de "R1,R2" y reviso como "estatica"
    Then los bloques son "R1 · running-config,R2 · running-config"
    And ningún bloque tiene hallazgos
    And el camino entre sedes queda sin problemas

  Scenario: Running-config con prompt y una tabla después (SPEC-004-RF10)
    When pego y reviso como "estatica":
      """
      R1#show running-config
      Building configuration...
      hostname R1
      interface GigabitEthernet0/0/1
       ip address 10.0.0.1 255.255.255.252
      !
      R1#show ip route
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      """
    Then los bloques son "R1 · running-config,R1 · show ip route"

  Scenario: Un router con otro hostname se reconoce por sus IP (SPEC-004-RF11)
    When pego y reviso como "estatica":
      """
      hostname Router
      interface GigabitEthernet0/0/1
       ip address 10.0.0.2 255.255.255.252
      """
    Then los bloques son "R2 · running-config"

  Scenario: Una tabla sin prompt se reconoce por sus redes conectadas (SPEC-004-RF11)
    When pego y reviso como "estatica":
      """
      C    192.168.20.0/26 is directly connected, GigabitEthernet0/0/0.10
      """
    Then los bloques son "R2 · show ip route"

  Scenario: Lo que no es de ningún equipo del diseño se dice (SPEC-004-RF11)
    When pego y reviso como "estatica":
      """
      hostname OTRO
      interface FastEthernet0/1
       ip address 172.16.0.1 255.255.255.0
      """
    Then los bloques son "Bloque 1"
    And el bloque "Bloque 1" dice "No se reconoció de qué equipo es este bloque."

  Scenario: Una tabla de un router que no es del diseño se dice (SPEC-004-RF11)
    When pego y reviso como "estatica":
      """
      C    172.16.0.0/24 is directly connected, FastEthernet0/1
      """
    Then los bloques son "Bloque 1"
    And el bloque "Bloque 1" dice "No se reconoció de qué equipo es este bloque."

  Scenario: Un switch pegado se audita contra su sede (SPEC-004-RF12)
    When pego la configuración de "SW2" y reviso como "estatica"
    Then los bloques son "SW2 · running-config"
    And ningún bloque tiene hallazgos
    And el camino entre sedes queda sin problemas

  Scenario: Las fallas de sede y del doctor salen en el mismo bloque (SPEC-004-RF12)
    When pego y reviso como "estatica":
      """
      hostname R1
      interface GigabitEthernet0/0/1
       ip address 10.0.0.1 255.255.255.252
       shutdown
      """
    Then el bloque "R1 · running-config" dice "R1: GigabitEthernet0/0/1 (enlace con R2) está apagada."
    And el bloque "R1 · running-config" dice "A: ninguna interfaz tiene el gateway 192.168.10.1."
    And el camino entre sedes dice solo "Para revisar el camino entre todas las sedes pega también: R2."

  Scenario: Una configuración sin hostname se reconoce por el gateway de la sede 1 (SPEC-004-RF11)
    When pego y reviso como "estatica":
      """
      interface GigabitEthernet0/0/0.10
       ip address 192.168.10.1 255.255.255.192
      """
    Then los bloques son "R1 · running-config"

  Scenario: Solo el hostname ya es una running-config (SPEC-004-RF10, RF11)
    When pego y reviso como "estatica":
      """
      hostname R1
      """
    Then los bloques son "R1 · running-config"

  Scenario: Building configuration separa dos configuraciones sin hostname (SPEC-004-RF10)
    When pego y reviso como "estatica":
      """
      interface GigabitEthernet0/0/1
       ip address 10.0.0.1 255.255.255.252
      Building configuration...
      interface GigabitEthernet0/0/1
       ip address 10.0.0.2 255.255.255.252
      """
    Then los bloques son "R1 · running-config,R2 · running-config"

  Scenario: El prompt se reconoce aunque esté en mayúsculas (SPEC-004-RF10)
    When pego y reviso como "estatica":
      """
      hostname R1
      interface GigabitEthernet0/0/1
       ip address 10.0.0.1 255.255.255.252
      R1#SHOW IP ROUTE
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      """
    Then los bloques son "R1 · running-config,R1 · show ip route"

  Scenario: Una tabla sin rutas pero con su prompt se reconoce (SPEC-004-RF10, RF11)
    When pego y reviso como "estatica":
      """
      R2#show ip route
      Gateway of last resort is not set
      """
    Then los bloques son "R2 · show ip route"

  Scenario: Una tabla sin prompt se reconoce por las redes conectadas de la sede 1 (SPEC-004-RF11)
    When pego y reviso como "estatica":
      """
      C    192.168.10.0/26 is directly connected, GigabitEthernet0/0/0.10
      """
    Then los bloques son "R1 · show ip route"

  Scenario: Una tabla sin redes conectadas no se puede reconocer (SPEC-004-RF11)
    When pego y reviso como "estatica":
      """
      S    192.168.10.0/26 [1/0] via 10.0.0.1
      """
    Then los bloques son "Bloque 1"
