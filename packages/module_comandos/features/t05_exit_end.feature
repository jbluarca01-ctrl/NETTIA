Feature: exit y end en las plantillas de Comandos CLI
  Las pestañas del switch y del router incluyen los pasos para salir de
  cada submodo (exit) y para volver al modo privilegiado antes de guardar
  (end), así lo copiado no se queda atascado en un submodo.

  Scenario: El switch sale de la VLAN y de la interfaz y vuelve con end
    Given la pantalla de Comandos CLI
    When abro la pestaña "Switch (VLANs)"
    Then veo "Salir del modo de la VLAN"
    And veo "Vuelve a Switch(config)# para crear la siguiente VLAN o entrar a una interfaz."
    And veo "Salir de la interfaz"
    And veo "Vuelve a Switch(config)# antes de entrar a otra interfaz."
    And veo 2 veces "exit"
    And veo "Volver al modo privilegiado"
    And veo "Sale de cualquier submodo directo a Switch#; copy running-config solo funciona ahí."
    And veo 1 vez "end"

  Scenario: El router sale de la interfaz física y de cada subinterfaz
    Given la pantalla de Comandos CLI
    When abro la pestaña "Router (dot1Q)"
    Then veo "Salir de la interfaz física"
    And veo "Vuelve a Router(config)# para crear las subinterfaces."
    And veo "Salir de la subinterfaz"
    And veo "Repite crear subinterfaz, encapsulation, ip address y exit por cada VLAN."
    And veo 2 veces "exit"
    And veo "Volver al modo privilegiado"
    And veo "Sale de cualquier submodo directo a Router#; copy running-config solo funciona ahí."
    And veo 1 vez "end"
