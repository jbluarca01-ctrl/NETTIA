Feature: Plantilla del troncal en la pestaña del switch
  La pestaña "Switch (VLANs)" de Comandos CLI trae los tres comandos del
  troncal hacia el router u otro switch: modo trunk, VLAN nativa y VLAN
  permitidas, cada uno con su parámetro.

  Scenario: El troncal completo con VLAN nativa y VLAN permitidas
    Given la pantalla de Comandos CLI
    When abro la pestaña "Switch (VLANs)"
    Then veo "Poner el puerto en modo trunk"
    And veo "switchport mode trunk"
    And veo "Definir la VLAN nativa del trunk"
    And veo "switchport trunk native vlan <id>"
    And veo "Ej.: switchport trunk native vlan 99. Debe ser la misma en ambos extremos del enlace; si no, IOS avisa Native VLAN mismatch."
    And veo "Permitir VLANs en el trunk"
    And veo "switchport trunk allowed vlan <lista>"
