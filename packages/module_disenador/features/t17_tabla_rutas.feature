Feature: Doctor de redes sobre show ip route
  SPEC-004 T3. Se lee la tabla de rutas de IOS (con y sin máscara en cada
  línea) y se compara con el diseño: las redes propias deben estar
  conectadas y las de las otras sedes, por el vecino correcto.

  Background:
    Given el diseño del parcial con el enrutamiento "estaticaResumida"

  Scenario: La tabla de R1 del parcial está bien (SPEC-004-RF8, RF9)
    When reviso la tabla de "R1":
      """
      R1#show ip route
      Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
             O - OSPF, IA - OSPF inter area
      Gateway of last resort is not set

           10.0.0.0/8 is variably subnetted, 2 subnets, 2 masks
      C       10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      L       10.0.0.1/32 is directly connected, GigabitEthernet0/0/1
           192.168.10.0/24 is variably subnetted, 8 subnets, 5 masks
      C       192.168.10.0/26 is directly connected, GigabitEthernet0/0/0.10
      L       192.168.10.1/32 is directly connected, GigabitEthernet0/0/0.10
      C       192.168.10.64/27 is directly connected, GigabitEthernet0/0/0.20
      C       192.168.10.96/28 is directly connected, GigabitEthernet0/0/0.30
      C       192.168.10.112/29 is directly connected, GigabitEthernet0/0/0.40
           192.168.20.0/25 is subnetted, 1 subnets
      S       192.168.20.0 [1/0] via 10.0.0.2
      """
    Then la tabla no tiene problemas

  Scenario: Sin la estática hacia la sede 2 (SPEC-004-RF9)
    When reviso la tabla de "R1":
      """
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      C    192.168.10.0/26 is directly connected, GigabitEthernet0/0/0.10
      C    192.168.10.64/27 is directly connected, GigabitEthernet0/0/0.20
      C    192.168.10.96/28 is directly connected, GigabitEthernet0/0/0.30
      C    192.168.10.112/29 is directly connected, GigabitEthernet0/0/0.40
      """
    Then la tabla dice solo "R1 (show ip route): no hay ruta hacia 192.168.20.0/26, 192.168.20.64/27, 192.168.20.96/28, 192.168.20.112/29 (sede 2)."

  Scenario: Una subinterfaz caída no aparece como conectada (SPEC-004-RF9)
    When reviso la tabla de "R1":
      """
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      C    192.168.10.0/26 is directly connected, GigabitEthernet0/0/0.10
      C    192.168.10.96/28 is directly connected, GigabitEthernet0/0/0.30
      C    192.168.10.112/29 is directly connected, GigabitEthernet0/0/0.40
      S    192.168.20.0/25 [1/0] via 10.0.0.2
      """
    Then la tabla dice solo "R1 (show ip route): 192.168.10.64/27 (B) no aparece como conectada; revisa la interfaz."

  Scenario: Rutas OSPF por un salto equivocado (SPEC-004-RF8, RF9)
    When reviso la tabla de "R1":
      """
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      C    192.168.10.0/26 is directly connected, GigabitEthernet0/0/0.10
      C    192.168.10.64/27 is directly connected, GigabitEthernet0/0/0.20
      C    192.168.10.96/28 is directly connected, GigabitEthernet0/0/0.30
      C    192.168.10.112/29 is directly connected, GigabitEthernet0/0/0.40
      O       192.168.20.0/26 [110/2] via 10.0.0.2, 00:01:23, GigabitEthernet0/0/1
      O       192.168.20.64/27 [110/2] via 10.0.0.2, 00:01:23, GigabitEthernet0/0/1
      O IA    192.168.20.96/28 [110/3] via 10.0.0.3, 00:01:23, GigabitEthernet0/0/1
      O       192.168.20.112/29 [110/2] via 10.0.0.2, 00:01:23, GigabitEthernet0/0/1
      """
    Then la tabla dice solo "R1 (show ip route): la ruta 192.168.20.96/28 sale por 10.0.0.3; hacia la sede 2 el vecino es 10.0.0.2."

  Scenario: Una ruta por defecto hacia el vecino también lleva a la otra sede (SPEC-004-RF8, RF9)
    When reviso la tabla de "R1":
      """
      Gateway of last resort is 10.0.0.2 to network 0.0.0.0
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      C    192.168.10.0/26 is directly connected, GigabitEthernet0/0/0.10
      C    192.168.10.64/27 is directly connected, GigabitEthernet0/0/0.20
      C    192.168.10.96/28 is directly connected, GigabitEthernet0/0/0.30
      C    192.168.10.112/29 is directly connected, GigabitEthernet0/0/0.40
      S*   0.0.0.0/0 [1/0] via 10.0.0.2
      """
    Then la tabla no tiene problemas

  Scenario: Una red propia que llega por OSPF no cuenta como conectada (SPEC-004-RF9)
    When reviso la tabla de "R1":
      """
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      C    192.168.10.0/26 is directly connected, GigabitEthernet0/0/0.10
      O    192.168.10.64/27 [110/2] via 10.0.0.2
      C    192.168.10.96/28 is directly connected, GigabitEthernet0/0/0.30
      C    192.168.10.112/29 is directly connected, GigabitEthernet0/0/0.40
      S    192.168.20.0/25 [1/0] via 10.0.0.2
      """
    Then la tabla dice solo "R1 (show ip route): 192.168.10.64/27 (B) no aparece como conectada; revisa la interfaz."
    And la corrección de la tabla es "show ip interface brief"

  Scenario: A la tabla de R2 le falta la ruta hacia la sede 1 (SPEC-004-RF9)
    When reviso la tabla de "R2":
      """
      C    10.0.0.0/30 is directly connected, GigabitEthernet0/0/1
      C    192.168.20.0/26 is directly connected, GigabitEthernet0/0/0.10
      C    192.168.20.64/27 is directly connected, GigabitEthernet0/0/0.20
      C    192.168.20.96/28 is directly connected, GigabitEthernet0/0/0.30
      C    192.168.20.112/29 is directly connected, GigabitEthernet0/0/0.40
      """
    Then la tabla dice solo "R2 (show ip route): no hay ruta hacia 192.168.10.0/26, 192.168.10.64/27, 192.168.10.96/28, 192.168.10.112/29 (sede 1)."
