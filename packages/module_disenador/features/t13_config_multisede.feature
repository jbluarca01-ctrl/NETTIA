Feature: Configuración de una red con varios routers
  SPEC-003 T2. Cada sede genera su switch y su router con el generador de
  siempre; el router suma sus enlaces (después de las interfaces hacia sus
  switches) y su enrutamiento, antes del DHCP. Los switches se numeran en
  orden de sede.

  Background:
    Given la sede 1 "192.168.10.0/24" con "A:50,B:25,C:12,D:5"
    And la sede 2 "192.168.20.0/24" con "A:50,B:25,C:12,D:5"

  Scenario: El parcial: equipos, enlace y rutas resumidas (SPEC-003-RF10, RF11, RF12)
    When genero la red con los enlaces "10.0.0.0/30" y el enrutamiento "estaticaResumida"
    Then los equipos son "SW1,R1,SW2,R2"
    And "R1" tiene seguidas las líneas "interface GigabitEthernet0/0/1;description ENLACE a R2;ip address 10.0.0.1 255.255.255.252;no shutdown;exit;ip route 192.168.20.0 255.255.255.128 10.0.0.2;ip dhcp excluded-address 192.168.10.1"
    And "R2" tiene seguidas las líneas "interface GigabitEthernet0/0/1;description ENLACE a R1;ip address 10.0.0.2 255.255.255.252;no shutdown;exit;ip route 192.168.10.0 255.255.255.128 10.0.0.1;ip dhcp excluded-address 192.168.20.1"
    And "SW2" tiene seguidas las líneas "interface GigabitEthernet0/1;description TRONCAL a R2"
    And "R2" tiene seguidas las líneas "hostname R2"

  Scenario: Con OSPF el router anuncia sus redes en el área 0 (SPEC-003-RF8, RF12)
    When genero la red con los enlaces "10.0.0.0/30" y el enrutamiento "ospf"
    Then "R1" tiene seguidas las líneas "no shutdown;exit;router ospf 1;router-id 1.1.1.1;network 192.168.10.0 0.0.0.63 area 0;network 192.168.10.64 0.0.0.31 area 0;network 192.168.10.96 0.0.0.15 area 0;network 192.168.10.112 0.0.0.7 area 0;network 10.0.0.0 0.0.0.3 area 0;exit;ip dhcp excluded-address 192.168.10.1"
    And "R2" no tiene ninguna línea que empiece con "ip route"

  Scenario: El router del medio usa G0/0/1 hacia el anterior y G0/0/2 hacia el siguiente (SPEC-003-RF11)
    Given la sede 3 "192.168.30.0/24" con "A:50"
    When genero la red con los enlaces "10.0.0.0/29" y el enrutamiento "estaticaResumida"
    Then los equipos son "SW1,R1,SW2,R2,SW3,R3"
    And "R2" tiene seguidas las líneas "interface GigabitEthernet0/0/1;description ENLACE a R1;ip address 10.0.0.2 255.255.255.252;no shutdown;exit;interface GigabitEthernet0/0/2;description ENLACE a R3;ip address 10.0.0.5 255.255.255.252;no shutdown;exit"

  Scenario: Con dos switches en una sede, los enlaces van después de sus interfaces (SPEC-003-RF10, RF11)
    Given la sede 1 tiene 2 switches con "A:50+0,B:0+25,C:12+0,D:0+5"
    When genero la red con los enlaces "10.0.0.0/30" y el enrutamiento "estaticaResumida"
    Then los equipos son "SW1,SW2,R1,SW3,R2"
    And "R1" tiene seguidas las líneas "interface GigabitEthernet0/0/2;description ENLACE a R2;ip address 10.0.0.1 255.255.255.252"
