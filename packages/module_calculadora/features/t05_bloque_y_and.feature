Feature: Bloque y AND del octeto interesante en la pestaña "Red"
  Como en las Clases 13 y 15: el bloque (256 − octeto de la máscara) y el
  AND del octeto donde la máscara corta, para no copiar el octeto del host.

  Scenario: 192.168.45.100/19
    Given la pestaña "Red" con la IP "192.168.45.100" y el prefijo "/19"
    Then la fila "Bloque (salto):" dice "32 en el 3.er octeto (256 − 224)"
    And la fila "AND del octeto:" dice "45 AND 224 = 32"

  Scenario: 10.10.10.70/27 en el 4.º octeto
    Given la pestaña "Red" con la IP "10.10.10.70" y el prefijo "/27"
    Then la fila "Bloque (salto):" dice "32 en el 4.º octeto (256 − 224)"
    And la fila "AND del octeto:" dice "70 AND 224 = 64"

  Scenario: Máscara que corta entre octetos
    Given la pestaña "Red" con la IP "172.16.5.20" y el prefijo "/16"
    Then no hay fila "AND del octeto:"
    And la fila "Bloque (salto):" dice "La máscara corta entre octetos"
