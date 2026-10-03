Feature: El subneteo IPv6 lista como máximo 24 subredes
  De /48 a /64 salen 65 536 subredes. Como en Dividir (IPv4), la app da
  el total como número y lista solo las primeras 24.

  Scenario: Datos de ejemplo de /48 a /64
    Given la pestaña "IPv6" de la Calculadora abierta
    Then el resumen dice "Subredes /64:" "65536"
    And veo el título "Primeras 24 subredes:"
    And veo la subred "24.  2001:db8:acad:17::/64"
    And no veo la subred "25.  2001:db8:acad:18::/64"
