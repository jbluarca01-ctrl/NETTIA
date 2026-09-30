Feature: El menú lateral de Nettia
  El menú muestra la marca, el estado de la IA, los módulos y la sección de
  sistema; cada entrada cierra el menú antes de abrir lo que corresponde.

  Scenario: El menú lista los módulos y la sección de sistema
    Given el menú lateral abierto con el módulo actual "Guía Metodológica"
    Then el menú muestra las entradas
      | titulo                    | subtitulo                                     |
      | Calculadora de Subredes   | IPv4, CIDR y desglose binario                 |
      | Comandos CLI & Plantillas | VLANs, Router-on-a-stick y pruebas            |
      | Asistente NETIA           | Diagnóstico IA & protocolos OT                |
      | Guía Metodológica         | Los 5 pasos de configuración                  |
      | Diseñador de Red          | Plan, configuración, verificación y auditoría |
      | Configuración & IA        | Motores IA, apariencia y modelos              |
      | Acerca de Nettia          | Versión 1.0.0                                 |
    And el menú muestra los rótulos "MÓDULOS" y "SISTEMA"
    And el pie del menú dice "v1.0.0" y "Nettia"
    And solo "Guía Metodológica" aparece seleccionado

  Scenario: Elegir un módulo cierra el menú y lo abre
    Given el menú lateral abierto con el módulo actual "Guía Metodológica"
    When toco "Diseñador de Red" en el menú
    Then el menú se cerró
    And se eligió el módulo "disenador"

  Scenario: Configuración cierra el menú y abre los ajustes
    Given el menú lateral abierto con el módulo actual "Guía Metodológica"
    When toco "Configuración & IA" en el menú
    Then el menú se cerró
    And se abrieron los ajustes

  Scenario: Acerca de cierra el menú y muestra la información de Nettia
    Given el menú lateral abierto con el módulo actual "Guía Metodológica"
    When toco "Acerca de Nettia" en el menú
    Then el menú se cerró
    And veo el diálogo con el botón "Entendido"
