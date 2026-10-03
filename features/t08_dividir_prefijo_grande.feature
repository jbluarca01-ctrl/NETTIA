Feature: Dividir no se congela al cambiar a un prefijo grande
  En "Hosts por subred" la cantidad de subredes crece con 2^(nuevo − prefijo):
  con 16 hosts y un /8 salen 524 288 subredes, y con un /1 más de 67 millones.
  La app no puede construirlas todas: lista como máximo 24 y dice el total.

  Scenario: Hosts por subred y cambio el prefijo a /16
    Given la pestaña "Dividir" de la Calculadora abierta
    When elijo el modo "Hosts por subred"
    And cambio el prefijo a "/16"
    Then el resumen dice "Subredes:" "2048"
    And veo el aviso "Se listan solo las primeras 24 de 2048 subredes."
    And la tabla muestra 24 subredes

  Scenario: Paso por Tamaños personalizados, vuelvo a Hosts por subred y cambio a /1
    Given la pestaña "Dividir" de la Calculadora abierta
    When elijo el modo "Hosts por subred"
    And elijo el modo "Tamaños personalizados"
    And cambio el prefijo a "/1"
    And elijo el modo "Hosts por subred"
    Then el resumen dice "Subredes:" "67108864"
    And la tabla muestra 24 subredes
