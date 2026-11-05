Feature: Activación de Nettia en el teléfono del comprador
  Sin una licencia válida para este teléfono Nettia no se usa: solo muestra
  la pantalla de activación. Un APK firmado por otro se bloquea sin explicar.

  Scenario: Sin licencia solo se ve la pantalla de activación
    Given un teléfono con ANDROID_ID "9774d56d682e549c" sin licencia guardada
    When abro Nettia
    Then veo "Activa tu Nettia"
    And veo el código del teléfono "706SD-81FDE"
    And no veo la selección de perfil

  Scenario: Copiar el código del teléfono
    Given un teléfono con ANDROID_ID "9774d56d682e549c" sin licencia guardada
    When abro Nettia
    And toco "Copiar código"
    Then el portapapeles tiene "706SD-81FDE"
    And veo "Código copiado"

  Scenario: Pegar una licencia válida activa Nettia
    Given un teléfono con ANDROID_ID "9774d56d682e549c" sin licencia guardada
    When abro Nettia
    And pego la licencia firmada para este teléfono a nombre de "Ana Pérez"
    And toco "Activar"
    Then veo la selección de perfil
    And la licencia quedó guardada

  Scenario: Una licencia de otro teléfono no activa
    Given un teléfono con ANDROID_ID "9774d56d682e549c" sin licencia guardada
    When abro Nettia
    And pego la licencia firmada para el ANDROID_ID "0123456789abcdef" a nombre de "Ana Pérez"
    And toco "Activar"
    Then veo "Ese código no corresponde a este teléfono. Revisa que lo copiaste completo."
    And no veo la selección de perfil
    And no hay licencia guardada

  Scenario: Con licencia guardada arranca normal y muestra el nombre
    Given un teléfono con ANDROID_ID "9774d56d682e549c" con licencia guardada a nombre de "Ana Pérez"
    When abro Nettia
    Then veo la selección de perfil
    And "Acerca de Nettia" dice "Licenciada a: Ana Pérez"

  Scenario: Una licencia guardada de otro teléfono se borra
    Given un teléfono con ANDROID_ID "9774d56d682e549c" con licencia guardada del ANDROID_ID "0123456789abcdef"
    When abro Nettia
    Then veo "Activa tu Nettia"
    And no hay licencia guardada

  Scenario: Si no se pueden leer los datos del teléfono no se activa
    Given un teléfono que no entrega sus datos
    When abro Nettia
    Then veo "No se pudo leer este teléfono. Cierra Nettia y vuelve a abrirla."
    And no veo la selección de perfil

  Scenario: Un APK firmado por otro se bloquea y borra la licencia
    Given un teléfono con ANDROID_ID "9774d56d682e549c" con licencia guardada a nombre de "Ana Pérez"
    And el APK está firmado con la huella "AA:BB" y se exige "CC:DD"
    When abro Nettia
    Then veo "Nettia no puede abrirse en este teléfono."
    And no veo la selección de perfil
    And no hay licencia guardada

  Scenario: Si la licencia deja de valer, cambiar de módulo bloquea
    Given un teléfono con ANDROID_ID "9774d56d682e549c" con licencia guardada a nombre de "Ana Pérez"
    And el perfil "estudiante" ya elegido
    When abro Nettia y llego al menú
    And la licencia guardada se reemplaza por una de otro teléfono
    And abro el módulo "Diseñador de Red" del menú
    Then veo "Activa tu Nettia"
