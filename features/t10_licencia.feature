Feature: Licencia firmada de Nettia
  Cada licencia vale solo para el teléfono y el nombre con que se firmó.
  La firma la hace el licenciador de Jairo con su clave privada; Nettia
  solo lleva la clave pública.

  Scenario: El mismo teléfono siempre muestra el mismo código
    Given un teléfono con ANDROID_ID "9774d56d682e549c"
    Then su código de teléfono es "706SD-81FDE"

  Scenario: Una licencia firmada para este teléfono se acepta con su nombre
    Given un teléfono con ANDROID_ID "9774d56d682e549c"
    And una licencia firmada para ese teléfono a nombre de "Ana Pérez"
    When la reviso
    Then la licencia es válida a nombre de "Ana Pérez"

  Scenario: La licencia pegada con espacios, saltos de línea y comillas se acepta
    Given un teléfono con ANDROID_ID "9774d56d682e549c"
    And una licencia firmada para ese teléfono a nombre de "Ana Pérez"
    And la pegaron entre comillas y partida en dos líneas
    When la reviso
    Then la licencia es válida a nombre de "Ana Pérez"

  Scenario: La licencia de otro teléfono se rechaza
    Given un teléfono con ANDROID_ID "9774d56d682e549c"
    And una licencia firmada para el ANDROID_ID "0123456789abcdef" a nombre de "Ana Pérez"
    When la reviso
    Then la licencia se rechaza por "firma"

  Scenario: Cambiar el nombre de la licencia la invalida
    Given un teléfono con ANDROID_ID "9774d56d682e549c"
    And una licencia firmada para ese teléfono a nombre de "Ana Pérez"
    And le cambiaron el nombre a "Luis Gómez"
    When la reviso
    Then la licencia se rechaza por "firma"

  Scenario: Una licencia firmada con otra clave se rechaza
    Given un teléfono con ANDROID_ID "9774d56d682e549c"
    And una licencia firmada con otra clave para ese teléfono a nombre de "Ana Pérez"
    When la reviso
    Then la licencia se rechaza por "firma"

  Scenario: Un texto que no es licencia se rechaza por formato
    Given un teléfono con ANDROID_ID "9774d56d682e549c"
    And el texto pegado "hola profe"
    When la reviso
    Then la licencia se rechaza por "formato"
