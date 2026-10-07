Feature: Rango libre al final de la VLSM
  La VLSM muestra no solo cuántas direcciones quedan libres sino desde dónde
  hasta dónde (Clase 17: "queda libre .120 – .255").

  Scenario: 50/25/12/5 en 192.168.10.0/24
    Given la VLSM de "192.168.10.0/24" con 50, 25, 12 y 5 hosts
    Then el rango libre es "192.168.10.120 – 192.168.10.255"

  Scenario: Sin espacio libre
    Given la VLSM de "192.168.10.0/24" con 126 y 126 hosts
    Then no hay rango libre

  Scenario: La pestaña VLSM muestra el rango libre
    Given la pestaña "VLSM" con las redes de ejemplo
    Then la fila "Rango libre:" dice "192.168.1.224 – 192.168.1.255"
