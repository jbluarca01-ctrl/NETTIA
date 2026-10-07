Feature: ¿Misma red?
  En la pestaña "Red" se puede escribir otra IP (un vecino o el gateway) y
  la app dice si está en la misma red que la primera (Clase 16: el gateway
  debe estar en la subred del host; dos PC no se ven si la máscara las separa).

  Scenario: El gateway está en la misma red
    Given la pestaña "Red" con la IP "192.168.20.10" y el prefijo "/25"
    When escribo la otra IP "192.168.20.1"
    Then la fila "¿Misma red?:" dice "Sí: 192.168.20.1 está en 192.168.20.0/25"

  Scenario: El gateway está en otra red
    Given la pestaña "Red" con la IP "192.168.20.10" y el prefijo "/25"
    When escribo la otra IP "192.168.20.129"
    Then la fila "¿Misma red?:" dice "No: 192.168.20.129 está en 192.168.20.128/25"

  Scenario: Sin otra IP no se muestra nada
    Given la pestaña "Red" con la IP "192.168.20.10" y el prefijo "/25"
    Then no hay fila "¿Misma red?:"
