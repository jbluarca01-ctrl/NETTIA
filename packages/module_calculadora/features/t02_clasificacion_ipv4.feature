Feature: Clase y tipo de una dirección IPv4
  En la pestaña "Red", además del cálculo, la app dice la clase de la IP
  (A–E, por el primer octeto) y si es pública, privada (RFC 1918) o
  especial, con una línea que lo justifica (Clase 14).

  Scenario Outline: Las direcciones de la guía de la Clase 14
    Given la pestaña "Red" con la IP "<ip>"
    Then la fila "Clase:" dice "<clase>"
    And la fila "Tipo:" dice "<tipo>"

    Examples:
      | ip              | clase                    | tipo                      |
      | 10.15.3.7       | A · /8 (255.0.0.0)       | Privada (RFC 1918)        |
      | 172.20.5.9      | B · /16 (255.255.0.0)    | Privada (RFC 1918)        |
      | 192.168.1.20    | C · /24 (255.255.255.0)  | Privada (RFC 1918)        |
      | 8.8.8.8         | A · /8 (255.0.0.0)       | Pública                   |
      | 172.15.1.1      | B · /16 (255.255.0.0)    | Pública                   |
      | 224.10.10.10    | D · sin máscara          | Multicast                 |
      | 240.0.0.1       | E · sin máscara          | Experimental (reservada)  |
      | 169.254.10.5    | B · /16 (255.255.0.0)    | APIPA (link-local)        |
      | 127.0.0.1       | A · /8 (255.0.0.0)       | Loopback                  |
      | 255.255.255.255 | E · sin máscara          | Broadcast limitado        |

  Scenario: La trampa de 172.15 se explica
    Given la pestaña "Red" con la IP "172.15.1.1"
    Then la explicación menciona "el bloque privado de clase B va de 172.16 a 172.31"

  Scenario: La clase la fija el primer octeto, no la máscara
    Given la pestaña "Red" con la IP "10.1.1.1" y el prefijo "/24"
    Then la fila "Clase:" dice "A · /8 (255.0.0.0)"
