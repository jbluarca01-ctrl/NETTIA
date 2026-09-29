Feature: Nettia lista para publicarse en Android
  La versión que se sube a Google Play no deja salir los datos del usuario
  (API keys, perfil, historial) por respaldos, se firma con la clave del
  autor y muestra en español los textos del sistema.

  Scenario: Los datos de la app no salen del teléfono por respaldos
    Given el manifiesto de Android
    Then el respaldo automático está desactivado
    And las reglas de extracción excluyen todos los datos del respaldo en la nube y de la transferencia entre dispositivos

  Scenario: La versión de publicación se firma con la clave del autor
    Given la configuración de compilación de Android
    Then la versión release se firma con la clave indicada en "key.properties"
    And las contraseñas pueden venir de variables de entorno en lugar del archivo
    And "key.properties" y los archivos de clave no se suben al repositorio

  Scenario: Los textos del sistema están en español
    Given la app arrancada con un perfil guardado
    Then el botón de cancelar del sistema dice "Cancelar"
