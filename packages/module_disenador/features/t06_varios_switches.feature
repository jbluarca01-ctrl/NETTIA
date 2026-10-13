Feature: Router-on-a-stick con varios switches
  Cada VLAN indica cuántas PC tiene en cada switch (hasta 3). Sale una
  configuración por switch y un único router. La subinterfaz de cada VLAN
  va una sola vez, en la interfaz física del primer switch que tiene PC de
  esa VLAN (en cadena, siempre la de SW1). Los troncales hacia el router
  llevan solo las VLAN que cuelgan de esa interfaz; los troncales entre
  switches llevan todas, con la misma nativa en ambos extremos.

  Scenario: Cuatro VLAN en dos switches, cada uno con su troncal al router
    Given la red base "192.168.10.0/24" con las PC por switch "ADMIN:6+0,VENTAS:10+0,BODEGA:0+5,TI:0+4"
    And 2 switches conectados "cada uno al router"
    When genero la configuración
    Then se generan los equipos "SW1,SW2,R1"
    And la configuración de "SW1" incluye:
      """
      banner motd #Acceso solo autorizado#
      vlan 20
       name VENTAS
      exit
      vlan 10
       name ADMIN
      exit
      vlan 99
       name NATIVA
      exit
      interface range FastEthernet0/1 - 12
       description VENTAS
       switchport mode access
       switchport access vlan 20
       spanning-tree portfast
       no shutdown
      exit
      interface range FastEthernet0/13 - 24
       description ADMIN
       switchport mode access
       switchport access vlan 10
       spanning-tree portfast
       no shutdown
      exit
      interface GigabitEthernet0/1
       description TRONCAL a R1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 20,10,99
       no shutdown
      exit
      end
      """
    And la configuración de "SW2" incluye:
      """
      banner motd #Acceso solo autorizado#
      vlan 30
       name BODEGA
      exit
      vlan 40
       name TI
      exit
      vlan 99
       name NATIVA
      exit
      interface range FastEthernet0/1 - 12
       description BODEGA
       switchport mode access
       switchport access vlan 30
       spanning-tree portfast
       no shutdown
      exit
      interface range FastEthernet0/13 - 24
       description TI
       switchport mode access
       switchport access vlan 40
       spanning-tree portfast
       no shutdown
      exit
      interface GigabitEthernet0/1
       description TRONCAL a R1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 30,40,99
       no shutdown
      exit
      end
      """
    And la configuración de "R1" incluye:
      """
      banner motd #Acceso solo autorizado#
      interface GigabitEthernet0/0/0
       no shutdown
      exit
      interface GigabitEthernet0/0/0.20
       description VENTAS
       encapsulation dot1Q 20
       ip address 192.168.10.1 255.255.255.240
      exit
      interface GigabitEthernet0/0/0.10
       description ADMIN
       encapsulation dot1Q 10
       ip address 192.168.10.17 255.255.255.240
      exit
      interface GigabitEthernet0/0/0.99
       description NATIVA
       encapsulation dot1Q 99 native
      exit
      interface GigabitEthernet0/0/1
       no shutdown
      exit
      interface GigabitEthernet0/0/1.30
       description BODEGA
       encapsulation dot1Q 30
       ip address 192.168.10.33 255.255.255.248
      exit
      interface GigabitEthernet0/0/1.40
       description TI
       encapsulation dot1Q 40
       ip address 192.168.10.41 255.255.255.248
      exit
      interface GigabitEthernet0/0/1.99
       description NATIVA
       encapsulation dot1Q 99 native
      exit
      ip dhcp excluded-address 192.168.10.1
      """

  Scenario: Una VLAN repartida entre dos switches enlazados
    Given la red base "192.168.10.0/24" con las PC por switch "ADMIN:6+0,VENTAS:6+2,BODEGA:0+5"
    And 2 switches conectados "ambos"
    When genero la configuración
    Then se generan los equipos "SW1,SW2,R1"
    And la configuración de "SW1" incluye:
      """
      interface GigabitEthernet0/1
       description TRONCAL a R1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 20,10,99
       no shutdown
      exit
      interface GigabitEthernet0/2
       description TRONCAL a SW2
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 20,10,30,99
       no shutdown
      exit
      end
      """
    And la configuración de "SW2" incluye:
      """
      banner motd #Acceso solo autorizado#
      vlan 20
       name VENTAS
      exit
      vlan 10
       name ADMIN
      exit
      vlan 30
       name BODEGA
      exit
      vlan 99
       name NATIVA
      exit
      interface range FastEthernet0/1 - 12
       description VENTAS
       switchport mode access
       switchport access vlan 20
       spanning-tree portfast
       no shutdown
      exit
      interface range FastEthernet0/13 - 24
       description BODEGA
       switchport mode access
       switchport access vlan 30
       spanning-tree portfast
       no shutdown
      exit
      interface GigabitEthernet0/1
       description TRONCAL a R1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 30,99
       no shutdown
      exit
      interface GigabitEthernet0/2
       description TRONCAL a SW1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 20,10,30,99
       no shutdown
      exit
      end
      """
    And la configuración de "R1" tiene 1 vez " encapsulation dot1Q 20"
    And la configuración de "R1" incluye:
      """
      interface GigabitEthernet0/0/1.30
       description BODEGA
       encapsulation dot1Q 30
       ip address 192.168.10.33 255.255.255.248
      exit
      """

  Scenario: Tres switches en cadena, solo SW1 llega al router
    Given la red base "192.168.10.0/24" con las PC por switch "A:5+0+0,B:0+5+0,C:0+0+5"
    And 3 switches conectados "en cadena"
    When genero la configuración
    Then se generan los equipos "SW1,SW2,SW3,R1"
    And la configuración de "R1" tiene 0 veces "GigabitEthernet0/0/1"
    And la configuración de "R1" incluye:
      """
      interface GigabitEthernet0/0/0
       no shutdown
      exit
      interface GigabitEthernet0/0/0.10
       description A
       encapsulation dot1Q 10
       ip address 192.168.10.1 255.255.255.248
      exit
      interface GigabitEthernet0/0/0.20
       description B
       encapsulation dot1Q 20
       ip address 192.168.10.9 255.255.255.248
      exit
      interface GigabitEthernet0/0/0.30
       description C
       encapsulation dot1Q 30
       ip address 192.168.10.17 255.255.255.248
      exit
      interface GigabitEthernet0/0/0.99
       description NATIVA
       encapsulation dot1Q 99 native
      exit
      """
    And la configuración de "SW1" incluye:
      """
      interface GigabitEthernet0/1
       description TRONCAL a R1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 10,20,30,99
       no shutdown
      exit
      interface GigabitEthernet0/2
       description TRONCAL a SW2
      """
    And la configuración de "SW2" incluye:
      """
      interface GigabitEthernet0/1
       description TRONCAL a SW1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 10,20,30,99
       no shutdown
      exit
      interface GigabitEthernet0/2
       description TRONCAL a SW3
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 10,20,30,99
       no shutdown
      exit
      end
      """
    And la configuración de "SW3" incluye:
      """
      interface range FastEthernet0/1 - 24
       description C
       switchport mode access
       switchport access vlan 30
       spanning-tree portfast
       no shutdown
      exit
      interface GigabitEthernet0/1
       description TRONCAL a SW2
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 10,20,30,99
       no shutdown
      exit
      end
      """

  Scenario: Tres switches al router y enlazados: el del medio usa un puerto FastEthernet
    Given la red base "192.168.10.0/24" con las PC por switch "A:5+0+0,B:0+5+0,C:0+0+5"
    And 3 switches conectados "ambos"
    When genero la configuración
    Then la configuración de "R1" incluye:
      """
      interface GigabitEthernet0/0/2.30
       description C
      """
    And la configuración de "SW2" incluye:
      """
      interface range FastEthernet0/1 - 23
       description B
       switchport mode access
       switchport access vlan 20
       spanning-tree portfast
       no shutdown
      exit
      interface GigabitEthernet0/1
       description TRONCAL a R1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 20,99
       no shutdown
      exit
      interface GigabitEthernet0/2
       description TRONCAL a SW1
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 10,20,30,99
       no shutdown
      exit
      interface FastEthernet0/24
       description TRONCAL a SW3
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 10,20,30,99
       no shutdown
      exit
      end
      """

  Scenario: Una VLAN repartida sin enlace entre switches no llega a su gateway
    Given la red base "192.168.10.0/24" con las PC por switch "ADMIN:6+0,VENTAS:6+2"
    And 2 switches conectados "cada uno al router"
    When genero la configuración
    Then la generación se rechaza con "VENTAS (VLAN 20) tiene PC en varios switches (SW1, SW2); con «Cada uno al router» no llegan a un mismo gateway. Elige «Ambos» o deja sus PC en un solo switch."

  Scenario: Un switch sin PC asignadas
    Given la red base "192.168.10.0/24" con las PC por switch "A:5+0"
    And 2 switches conectados "ambos"
    When genero la configuración
    Then la generación se rechaza con "SW2 no tiene PC asignadas: baja la cantidad de switches o reparte las PC."

  Scenario: La verificación revisa cada switch y cada troncal
    Given la red base "192.168.10.0/24" con las PC por switch "ADMIN:6+0,VENTAS:6+2,BODEGA:0+5"
    And 2 switches conectados "ambos"
    When genero el plan de verificación
    Then la verificación incluye los pasos:
      """
      SW1 | show vlan brief | VLAN 20 VENTAS activa en FastEthernet0/1 - 12
      SW2 | show vlan brief | VLAN 20 VENTAS activa en FastEthernet0/1 - 12
      SW2 | show vlan brief | VLAN 30 BODEGA activa en FastEthernet0/13 - 24
      SW1 | show interfaces trunk | GigabitEthernet0/2 en trunking, nativa 99, VLAN permitidas 20,10,30,99
      SW2 | show interfaces trunk | GigabitEthernet0/1 en trunking, nativa 99, VLAN permitidas 30,99
      SW2 | show interfaces trunk | GigabitEthernet0/2 en trunking, nativa 99, VLAN permitidas 20,10,30,99
      R1 | show ip interface brief | GigabitEthernet0/0/1.30 con 192.168.10.33, estado up/up
      R1 | show ip interface GigabitEthernet0/0/1.30 | Internet address is 192.168.10.33/29, la misma máscara que el pool BODEGA
      """
