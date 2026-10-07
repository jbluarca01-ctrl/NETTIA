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

  Scenario: El diálogo Acerca de describe Nettia, sus funciones y su licencia
    Given el menú lateral abierto con el módulo actual "Guía Metodológica"
    When toco "Acerca de Nettia" en el menú
    Then el diálogo Acerca de muestra los textos
      | texto                                                                                  |
      | Suite integral de ingeniería para conmutación, enrutamiento y redes industriales.      |
      | • Calculadoras: subredes, dividir, VLSM, IPv6, conversiones y práctica                 |
      | • Plantillas Cisco IOS para VLANs y Router-on-a-stick                                  |
      | • Asistente NETIA con base local con fuentes y multi-proveedor de IA                   |
      | • Guía metodológica de 5 capas                                                         |
    And el diálogo Acerca de muestra la licencia de Praxia Dynamic

  Scenario: Entendido cierra el diálogo Acerca de
    Given el menú lateral abierto con el módulo actual "Guía Metodológica"
    When toco "Acerca de Nettia" en el menú
    And toco el botón "Entendido" del diálogo
    Then el diálogo Acerca de se cerró

  Scenario: Licencias de terceros cierra el diálogo y abre la página de licencias
    Given el menú lateral abierto con el módulo actual "Guía Metodológica"
    When toco "Acerca de Nettia" en el menú
    And toco el botón "Licencias de terceros" del diálogo
    Then el diálogo Acerca de se cerró
    And veo la página de licencias de "Nettia" versión "1.0.0"
