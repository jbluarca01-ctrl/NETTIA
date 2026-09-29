Feature: Configuración CLI generada a partir del plan
  Del plan de direccionamiento sale la configuración completa de cada
  equipo, lista para pegar en Packet Tracer o en un equipo real.

  Scenario: Router-on-a-stick con DNS, dominio y clave
    Given la red base "192.168.10.0/24" con los segmentos "VENTAS:50,TI:20"
    And la topología router-on-a-stick
    And el DNS "8.8.8.8" y el dominio "empresa.local"
    And la clave de enable "Cl4ve"
    When genero la configuración
    Then se generan 2 equipos
    And la configuración de "SW1" es:
      """
      enable
      configure terminal
      hostname SW1
      no ip domain-lookup
      service password-encryption
      enable secret Cl4ve
      banner motd #Acceso solo autorizado#
      vlan 10
       name VENTAS
      vlan 20
       name TI
      vlan 99
       name NATIVA
      interface range FastEthernet0/1 - 12
       description VENTAS
       switchport mode access
       switchport access vlan 10
       spanning-tree portfast
       no shutdown
      interface range FastEthernet0/13 - 24
       description TI
       switchport mode access
       switchport access vlan 20
       spanning-tree portfast
       no shutdown
      interface GigabitEthernet0/1
       description TRONCAL
       switchport mode trunk
       switchport trunk native vlan 99
       switchport trunk allowed vlan 10,20,99
       no shutdown
      end
      write memory
      """
    And la configuración de "R1" es:
      """
      enable
      configure terminal
      hostname R1
      no ip domain-lookup
      service password-encryption
      enable secret Cl4ve
      banner motd #Acceso solo autorizado#
      interface GigabitEthernet0/0/0
       no shutdown
      interface GigabitEthernet0/0/0.10
       description VENTAS
       encapsulation dot1Q 10
       ip address 192.168.10.1 255.255.255.192
      interface GigabitEthernet0/0/0.20
       description TI
       encapsulation dot1Q 20
       ip address 192.168.10.65 255.255.255.224
      interface GigabitEthernet0/0/0.99
       description NATIVA
       encapsulation dot1Q 99 native
      ip dhcp excluded-address 192.168.10.1
      ip dhcp pool VENTAS
       network 192.168.10.0 255.255.255.192
       default-router 192.168.10.1
       dns-server 8.8.8.8
       domain-name empresa.local
      ip dhcp excluded-address 192.168.10.65
      ip dhcp pool TI
       network 192.168.10.64 255.255.255.224
       default-router 192.168.10.65
       dns-server 8.8.8.8
       domain-name empresa.local
      end
      write memory
      """

  Scenario: Switch capa 3 con IPs reservadas y sin clave definida
    Given la red base "10.0.0.0/24" con los segmentos "SERVIDORES:10"
    And 5 IPs reservadas y el gateway al final
    And la topología switch capa 3 con hostname "CORE"
    When genero la configuración
    Then se generan 1 equipos
    And la configuración de "CORE" es:
      """
      enable
      configure terminal
      hostname CORE
      no ip domain-lookup
      service password-encryption
      ! Define la clave: enable secret <tu-clave>
      banner motd #Acceso solo autorizado#
      vlan 10
       name SERVIDORES
      interface range FastEthernet0/1 - 24
       description SERVIDORES
       switchport mode access
       switchport access vlan 10
       spanning-tree portfast
       no shutdown
      ip routing
      interface Vlan10
       description SERVIDORES
       ip address 10.0.0.30 255.255.255.224
       no shutdown
      ip dhcp excluded-address 10.0.0.30
      ip dhcp excluded-address 10.0.0.1 10.0.0.5
      ip dhcp pool SERVIDORES
       network 10.0.0.0 255.255.255.224
       default-router 10.0.0.30
      end
      write memory
      """

  Scenario: Los nombres se adaptan a lo que acepta IOS
    Given la red base "192.168.0.0/24" con los segmentos "Sala de profesores:10,Dirección #2:5"
    And la topología router-on-a-stick
    When genero la configuración
    Then la configuración de "SW1" contiene " name SALA_DE_PROFESORES"
    And la configuración de "SW1" contiene " name DIRECCION_2"
    And la configuración de "SW1" contiene " description Sala de profesores"
    And la configuración de "R1" contiene "ip dhcp pool DIRECCION_2"

  Scenario: No alcanzan los puertos de acceso
    Given la red base "192.168.0.0/24" con los segmentos "A:5,B:5,C:5"
    And 2 puertos de acceso en el switch
    When genero la configuración
    Then la generación se rechaza con "No alcanzan los 2 puertos de acceso para 3 segmentos."
