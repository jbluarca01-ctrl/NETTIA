Feature: El Diseñador de red en el menú de Nettia
  El Diseñador es para los dos perfiles: el estudiante lo usa en sus
  laboratorios y el profesional con equipos reales.

  Scenario: El estudiante abre el Diseñador desde el menú
    Given Nettia abierta con el perfil "estudiante"
    When abro el módulo "Diseñador de Red" del menú
    Then la barra superior dice "Diseñador de Red"
    And veo la pestaña "Datos" del Diseñador

  Scenario: El profesional también lo tiene
    Given Nettia abierta con el perfil "profesional"
    When abro el módulo "Diseñador de Red" del menú
    Then la barra superior dice "Diseñador de Red"
