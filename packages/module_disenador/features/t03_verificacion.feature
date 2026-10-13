Feature: Plan de verificación personalizado
  Del plan y la topología sale la lista de comandos para comprobar que la
  red quedó como se diseñó, con el resultado esperado de cada uno.

  Scenario: Verificación de un router-on-a-stick
    Given la red base "192.168.10.0/24" con los segmentos "VENTAS:50,TI:20"
    And la topología router-on-a-stick
    When genero el plan de verificación
    Then los pasos de verificación son:
      """
      SW1 | show vlan brief | VLAN 10 VENTAS activa en FastEthernet0/1 - 12
      SW1 | show vlan brief | VLAN 20 TI activa en FastEthernet0/13 - 24
      SW1 | show interfaces trunk | GigabitEthernet0/1 en trunking, nativa 99, VLAN permitidas 10,20,99
      R1 | show ip interface brief | GigabitEthernet0/0/0.10 con 192.168.10.1, estado up/up
      R1 | show ip interface brief | GigabitEthernet0/0/0.20 con 192.168.10.65, estado up/up
      R1 | show ip dhcp pool VENTAS | Total addresses 62, el tamaño del bloque /26; otro número indica una máscara mal escrita en el pool
      R1 | show ip interface GigabitEthernet0/0/0.10 | Internet address is 192.168.10.1/26, la misma máscara que el pool VENTAS
      R1 | show ip dhcp pool TI | Total addresses 30, el tamaño del bloque /27; otro número indica una máscara mal escrita en el pool
      R1 | show ip interface GigabitEthernet0/0/0.20 | Internet address is 192.168.10.65/27, la misma máscara que el pool TI
      PC de VENTAS | ipconfig /renew | IP entre 192.168.10.2 y 192.168.10.62, máscara 255.255.255.192, gateway 192.168.10.1
      PC de VENTAS | ping 192.168.10.1 | Responde: la PC llega a su gateway
      PC de TI | ipconfig /renew | IP entre 192.168.10.66 y 192.168.10.94, máscara 255.255.255.224, gateway 192.168.10.65
      PC de TI | ping 192.168.10.65 | Responde: la PC llega a su gateway
      PC de VENTAS | ping 192.168.10.65 | Responde: el enrutamiento entre VLAN funciona
      R1 | show ip dhcp binding | Aparecen las PCs con direcciones de los pools
      """

  Scenario: Verificación de un switch capa 3 con un solo segmento
    Given la red base "10.0.0.0/24" con los segmentos "SERVIDORES:10"
    And la topología switch capa 3 con hostname "CORE"
    When genero el plan de verificación
    Then los pasos de verificación son:
      """
      CORE | show vlan brief | VLAN 10 SERVIDORES activa en FastEthernet0/1 - 24
      CORE | show ip interface brief | Vlan10 con 10.0.0.1, estado up/up
      CORE | show ip dhcp pool SERVIDORES | Total addresses 14, el tamaño del bloque /28; otro número indica una máscara mal escrita en el pool
      CORE | show ip interface Vlan10 | Internet address is 10.0.0.1/28, la misma máscara que el pool SERVIDORES
      PC de SERVIDORES | ipconfig /renew | IP entre 10.0.0.2 y 10.0.0.14, máscara 255.255.255.240, gateway 10.0.0.1
      PC de SERVIDORES | ping 10.0.0.1 | Responde: la PC llega a su gateway
      CORE | show ip dhcp binding | Aparecen las PCs con direcciones de los pools
      """
