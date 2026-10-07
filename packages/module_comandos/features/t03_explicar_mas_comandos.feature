Feature: Explicar la salida de los comandos de verificación de clase
  "Explicar salida" reconoce también show ip route, show interfaces trunk,
  show ip dhcp binding (Clases 16 y 17) y, del lado de la PC, ipconfig y
  arp -a (Clases 13 y 14). Cada hallazgo es: nivel | título | detalle.

  Scenario: show ip route con dos redes conectadas y sin ruta por defecto
    Given la salida pegada:
      """
      Gateway of last resort is not set

           192.168.20.0/24 is variably subnetted, 4 subnets, 2 masks
      C       192.168.20.0/25 is directly connected, GigabitEthernet0/0
      L       192.168.20.1/32 is directly connected, GigabitEthernet0/0
      C       192.168.20.128/25 is directly connected, GigabitEthernet0/1
      L       192.168.20.129/32 is directly connected, GigabitEthernet0/1
      """
    When la explico
    Then el comando es "show ip route"
    And el resumen es "2 redes conectadas, 0 aprendidas."
    And los hallazgos son:
      """
      aviso | Sin ruta por defecto | El router solo llega a las redes de la tabla. Si debe salir a otras redes o a Internet: ip route 0.0.0.0 0.0.0.0 <siguiente salto>.
      ok | Conectada: 192.168.20.0/25 | Por GigabitEthernet0/0.
      ok | Conectada: 192.168.20.128/25 | Por GigabitEthernet0/1.
      """

  Scenario: show ip route con rutas aprendidas
    Given la salida pegada:
      """
      Gateway of last resort is 10.0.0.1 to network 0.0.0.0

      C       10.0.0.0/30 is directly connected, Serial0/0/0
      O       172.16.1.0/24 [110/65] via 10.0.0.2, 00:01:10, Serial0/0/0
      S*      0.0.0.0/0 [1/0] via 10.0.0.1
      """
    When la explico
    Then el resumen es "1 redes conectadas, 2 aprendidas."
    And los hallazgos son:
      """
      ok | Conectada: 10.0.0.0/30 | Por Serial0/0/0.
      ok | OSPF: 172.16.1.0/24 | [110/65] via 10.0.0.2, 00:01:10, Serial0/0/0
      ok | Estática (por defecto): 0.0.0.0/0 | [1/0] via 10.0.0.1
      """

  Scenario: show ip route sin redes conectadas
    Given la salida pegada:
      """
      Gateway of last resort is not set
      """
    When la explico
    Then el comando es "show ip route"
    And hay un problema "Ninguna red conectada"

  Scenario: show interfaces trunk con una VLAN permitida que no existe
    Given la salida pegada:
      """
      Port        Mode         Encapsulation  Status        Native vlan
      Gig0/1      on           802.1q         trunking      1

      Port        Vlans allowed on trunk
      Gig0/1      10,20,30,40

      Port        Vlans allowed and active in management domain
      Gig0/1      10,20,30
      """
    When la explico
    Then el comando es "show interfaces trunk"
    And el resumen es "1 trunk activos de 1."
    And los hallazgos son:
      """
      aviso | Gig0/1: VLAN permitidas que no existen en el switch | 40. Créalas con vlan <número> o quítalas del trunk.
      ok | Gig0/1: trunk activo | Encapsulación 802.1q, VLAN nativa 1, permite 10,20,30,40.
      """

  Scenario: show interfaces trunk con un puerto que no negocia
    Given la salida pegada:
      """
      Port        Mode         Encapsulation  Status        Native vlan
      Fa0/24      auto         n-802.1q       not-trunking  1
      """
    When la explico
    Then hay un problema "Fa0/24: no está en trunk"

  Scenario: show ip dhcp binding con concesiones
    Given la salida pegada:
      """
      IP address       Client-ID/              Lease expiration        Type
                       Hardware address
      192.168.10.11    0001.4296.A5B1           --                     Automatic
      192.168.10.75    0060.2F84.1C23           --                     Automatic
      """
    When la explico
    Then el comando es "show ip dhcp binding"
    And el resumen es "2 direcciones entregadas por DHCP."
    And los hallazgos son:
      """
      ok | 192.168.10.11 | Entregada a 0001.4296.A5B1.
      ok | 192.168.10.75 | Entregada a 0060.2F84.1C23.
      """

  Scenario: show ip dhcp binding vacío
    Given la salida pegada:
      """
      IP address       Client-ID/              Lease expiration        Type
                       Hardware address
      """
    When la explico
    Then hay un problema "Nadie recibió IP por DHCP"

  Scenario: ipconfig con APIPA
    Given la salida pegada:
      """
      FastEthernet0 Connection:(default port)

         Link-local IPv6 Address.........: FE80::201:42FF:FE96:A5B1
         IP Address......................: 169.254.15.40
         Subnet Mask.....................: 255.255.0.0
         Default Gateway.................: 0.0.0.0
      """
    When la explico
    Then el comando es "ipconfig (PC)"
    And hay un problema "APIPA: la PC no obtuvo IP del DHCP"

  Scenario: ipconfig con el gateway fuera de la red
    Given la salida pegada:
      """
         IPv4 Address. . . . . . . . . . . : 192.168.20.10(Preferred)
         Subnet Mask . . . . . . . . . . . : 255.255.255.128
         Default Gateway . . . . . . . . . : 192.168.20.129
      """
    When la explico
    Then el resumen es "IP 192.168.20.10/25 en la red 192.168.20.0."
    And los hallazgos son:
      """
      problema | El gateway 192.168.20.129 está fuera de la red | La red de la PC es 192.168.20.0/25 (192.168.20.0 a 192.168.20.127). El gateway debe ser una IP de esa red, normalmente la primera.
      """

  Scenario: ipconfig correcto y sin gateway
    Given la salida pegada:
      """
         IP Address......................: 192.168.10.10
         Subnet Mask.....................: 255.255.255.0
         Default Gateway.................: 0.0.0.0
      """
    When la explico
    Then hay un aviso "Sin gateway"

  Scenario: ipconfig correcto con gateway en su red
    Given la salida pegada:
      """
         IP Address......................: 192.168.10.10
         Subnet Mask.....................: 255.255.255.0
         Default Gateway.................: 192.168.10.1
      """
    When la explico
    Then los hallazgos son:
      """
      ok | Gateway 192.168.10.1 dentro de la red | La PC puede salir de su red a través de él.
      """

  Scenario: arp -a con un vecino aprendido
    Given la salida pegada:
      """
        Internet Address      Physical Address      Type
        192.168.45.60         aa-bb-cc-44-55-66     dynamic
      """
    When la explico
    Then el comando es "arp -a (PC)"
    And el resumen es "1 vecinos en la tabla ARP. ARP solo resuelve vecinos de la misma red; para otra red se usa la MAC del gateway."
    And los hallazgos son:
      """
      ok | 192.168.45.60 → aa-bb-cc-44-55-66 | Aprendida con ARP (dynamic).
      """

  Scenario: arp -a vacío
    Given la salida pegada:
      """
      No ARP Entries Found
      """
    When la explico
    Then hay un aviso "La tabla ARP está vacía"
