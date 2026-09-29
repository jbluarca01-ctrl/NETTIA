# Manual de uso de Nettia (para el autor)

> Documento **solo para ti** (Jairo): no se empaqueta ni se muestra dentro de la app. Se amplía en cada bloque de trabajo y se cierra al final. Última actualización: 2026-09-21 (P, C, B, sanitizador, comentarios, conversiones, práctica y explicador de show).
> Lo marcado **[por documentar]** aún no está descrito porque ese módulo no se ha revisado a fondo en este manual.

## 1. Al abrir la app
1. **Pantalla "¿Cómo vas a usar Nettia?"** (solo si aún no elegiste perfil): eliges **Estudiante** o **Profesional**. Aparece **antes** que el logo animado y el menú.
   - *Estudiante:* el asistente explica el porqué de cada paso y da pistas antes de la solución; avisa qué no soporta Packet Tracer.
   - *Profesional:* el asistente responde directo (comando, verificación, riesgos).
   - Puedes cambiarlo después en **Configuración → Perfil de uso** (pide confirmación).
   - Qué se oculta al estudiante: **hoy nada**. Cuando existan funciones profesionales (plantillas de producción, auditoría, OT, automatización), el estudiante simplemente **no las verá** en el menú ni en los submenús.
2. **Logo animado** (1-2 segundos) y luego la app.

## 2. El menú lateral (☰ arriba a la izquierda)
- **Módulos:** Calculadora de Subredes, Comandos CLI & Plantillas, Asistente NETIA, Guía Metodológica.
- **Sistema:** Configuración & IA y "Acerca de Nettia".
- El punto verde/ámbar bajo el nombre indica si el asistente está **en línea** (con clave de IA) o en **modo offline**.
- **Acerca de Nettia:** resumen, licencia (PolyForm Noncommercial), aviso de que Cisco/CCNA/Packet Tracer son marcas de sus dueños y botón **Licencias de terceros** (pantalla estándar de Flutter con las licencias de las librerías).

## 3. Configuración & Sistema (⚙ arriba a la derecha)
- **Perfil de uso:** Estudiante / Profesional.
- **Apariencia:** Claro, Oscuro o Automático (sigue al teléfono).
- **Motor de IA (NETIA):** eliges el proveedor, pegas **tu propia API Key** (se guarda cifrada en el teléfono, nunca viaja dentro de la app), pulsas **Probar conexión y cargar modelos** y eliges un modelo de la lista. Sin clave o en modo Offline el asistente responde desde la base local.
- **Forzar modo Offline:** ignora internet y usa siempre la base local.
- **Ocultar datos sensibles antes de enviar a la IA** (activado por defecto): antes de mandar tu pregunta a un proveedor en la nube, la app enmascara contraseñas (`enable secret/password`, `username … secret/password`, `password` de líneas), comunidades SNMP, claves compartidas (TACACS/RADIUS/IPsec/`key-string`), claves privadas y de API, nombres de equipo (`hostname`, con marcadores `HOST-1`), dominios (`ip domain-name`) e **IPs públicas** (con marcadores `IP-PUBLICA-1`, siempre el mismo para la misma IP). Las IPs privadas, máscaras, wildcards y rangos de documentación quedan intactos. Cuando oculta algo, el chat empieza con "🔒 Antes de enviar a … se ocultaron: …". Límites: no reconoce IPv6 globales ni secretos en texto libre sin `clave:`/`password =`. Solo actúa hacia el proveedor: la búsqueda en la base local usa tu texto original y nunca sale del teléfono. Si tu laboratorio usa IPs públicas típicas (8.8.8.8, 1.1.1.1), se ocultarán también; puedes apagarlo.
- **Comentarios sobre las respuestas:** cuántos comentarios hay guardados en el teléfono; **Copiar reporte** (lo pegas en un mensaje al autor) y **Borrar comentarios**.

## 4. Calculadora de Subredes
Tiene seis pestañas (arriba, deslizables): Red, Dividir, VLSM, IPv6, Conversión y Práctica. Lo que escribes en una pestaña **se conserva** al cambiar de pestaña.

### 4.1 Pestaña "Red"
Calcula **una** red IPv4: escribes la IP (en decimal o binario con el botón Dec/Bin) y el prefijo, o la máscara (decimal o binaria). Muestra máscara, dirección de red, gateway sugerido (primer host), primer y último host, broadcast, hosts útiles y el **desglose en binario** (IP, máscara, red, broadcast).

### 4.2 Pestaña "Dividir" (partir una red en subredes iguales)
Para enunciados del tipo *"divide esta red en 16 subredes"*.
1. Escribe la **red** (por ejemplo `192.168.1.0`) y su **prefijo** (`/24`).
2. Elige **Nº de subredes** (por ejemplo 16) o **Hosts por subred** (cuántos hosts necesita cada una).
3. Resultado inmediato:
   - **Nuevo prefijo** y máscara (para 16 subredes desde /24: `/28`, `255.255.255.240`).
   - **Bits prestados** (4), cantidad de subredes (16) y hosts útiles por subred (14).
   - **Cómo se calcula (paso a paso)**: desplegable con el procedimiento que puedes copiar al examen.
   - **Tabla de subredes**: red, máscara, primer host, último host, broadcast y hosts de cada una. Se desliza a los lados. **Copiar tabla** la copia al portapapeles.
- Si pides un número que no es potencia de 2 (por ejemplo 10), salen 16 y las 6 sobrantes aparecen **atenuadas** y con aviso.
- Si escribes una IP que no es la dirección de red (por ejemplo `192.168.1.77/24`), la app usa `192.168.1.0/24` y te lo avisa.
- Errores típicos que la app te dice: pedir más subredes de las que caben (pasar de /30), o más hosts de los que tiene la red.

### 4.3 Pestaña "VLSM" (subredes de distinto tamaño)
Para *"la LAN A necesita 100 hosts, la B 50…"*.
1. Escribe la **red disponible** y su prefijo.
2. Llena una fila por red: **nombre** y **hosts** que necesita. **Agregar red** añade filas; la ✕ quita una.
3. La app ordena de **mayor a menor**, da a cada una el bloque más pequeño que le alcance y las coloca de forma contigua. Muestra la tabla, los pasos y cuántas **direcciones quedan libres**.
- Si no caben, dice cuál red provocó el desborde y cuánto espacio había.
- Filas con "Hosts" vacío se ignoran mientras las llenas.

### 4.4 Pestaña "IPv6"
Tres bloques:
- **Analizar una dirección:** la abrevia (regla RFC 5952), la expande y dice su **tipo** (loopback, link-local `fe80::/10`, local única `fc00::/7`, multicast `ff00::/8` con su ámbito, unicast global `2000::/3`, documentación `2001:db8::/32`, IPv4 mapeada…). No acepta sufijo IPv4 (`::ffff:1.2.3.4`) ni `/prefijo`.
- **EUI-64 desde una MAC:** escribes un prefijo /64 y la MAC; genera el identificador de interfaz (inserta `fffe` e invierte el 7.º bit) y la dirección completa.
- **Subnetear un prefijo:** eliges el prefijo actual y el nuevo (por ejemplo `/48` → `/64`); dice cuántas subredes salen (65 536) y lista las **primeras 16**. IPv6 no tiene broadcast.

### 4.5 Pestaña "Conversión"
Tres herramientas:
- **Prefijo, máscara y wildcard:** escribes `/24`, `255.255.255.0` o `0.0.0.255` (cualquiera de las tres) y ves las demás formas y los hosts útiles. El wildcard es el que se usa en ACL y en `network` de OSPF.
- **Decimal, binario y hexadecimal:** eliges la base en la que escribes y ves las otras dos (el binario sale en bloques de 8 bits). Máximo 32 bits.
- **Sumarizar rutas:** una red por línea (`192.168.0.0/24`); da la ruta resumen más específica, si es **exacta** (cubre justo esas redes) o cuántas direcciones sobran, y avisa si hay solapes o si escribiste algo que no es dirección de red.

### 4.6 Pestaña "Práctica"
Ejercicios al azar donde **tú escribes las respuestas** y la app las corrige campo por campo:
- Tipos: dividir en subredes, hosts/máscara/wildcard de un prefijo, VLSM, IPv6 abreviar y IPv6 EUI-64.
- **Corregir** marca cada campo (✔/⚠), muestra la respuesta correcta de los fallados y despliega el **procedimiento paso a paso**. **Otro ejercicio** genera uno nuevo. El contador de abajo cuenta ejercicios resueltos y sin errores (solo mientras la pestaña está abierta).
- El prefijo se acepta con o sin barra (`/28` o `28`). En IPv6 se exige la forma recomendada (minúsculas, `::` en la racha más larga).
- Las respuestas correctas salen de la misma lógica que las calculadoras (probada contra 100 ejercicios generados).

### 4.7 Ejemplo resuelto: el caso del parcial
*Dada una red /24, dividirla en 16 subredes:* pestaña **Dividir**, red `192.168.1.0`, `/24`, "Nº de subredes" = 16 → `/28`, salto de 16, 14 hosts útiles por subred; subred 1 = `192.168.1.0/28` (hosts .1 a .14, broadcast .15), subred 2 = `192.168.1.16/28`, …, subred 16 = `192.168.1.240/28` (broadcast .255). Los pasos aparecen en "Cómo se calcula".

## 5. Comandos CLI & Plantillas — [pestañas de plantillas por documentar]
Pestañas: Switch (VLANs), Router (dot1Q), Auditoría IOS (en realidad son comandos `show` para verificar), Pruebas CMD y **Explicar salida**.

### 5.1 Pestaña "Explicar salida"
Pegas la salida de un `show` (o usas **Pegar y explicar**, que toma el portapapeles) y la app explica cada línea y señala lo que hay que revisar. Se analiza **en el teléfono**, no se envía a ningún lado. Reconoce tres comandos por su fila de encabezados:
- **`show ip interface brief`:** por interfaz dice si está bien (up/up), apagada con `shutdown` (administratively down → `no shutdown`), sin señal física (down/down: cable, otro extremo), con el protocolo caído (up/down: encapsulación, keepalives, reloj en seriales; en una SVI, VLAN sin puertos activos) o con **IP duplicada**.
- **`show vlan brief`:** VLAN sin puertos de acceso, VLAN apagada (`act/lshut`), VLAN suspendida y cuántos puertos siguen en la VLAN 1; recuerda que los trunk no salen en esta lista.
- **`show ip ospf neighbor`:** FULL (bien), 2WAY/DROTHER (normal en redes de acceso múltiple), INIT (te ven pero no te listan), EXSTART/EXCHANGE (causa más común: **MTU distinto**, según el doc. 13684-12 de Cisco), LOADING y vecinos caídos; si no hay ninguno, lista qué revisar.
- Los hallazgos salen ordenados: problemas, avisos y lo que está bien. Son **causas frecuentes, no un diagnóstico definitivo**. Si el texto no se reconoce, pide copiar la salida completa con su encabezado.

## 6. Asistente NETIA — [pantalla de chat por documentar]
Cómo obtiene sus respuestas (Bloque B):
- **Base local de conocimiento:** cada pregunta se busca primero en el corpus del paquete `nettia_knowledge` (buscador FTS5 en memoria, sin internet). Hoy tiene **16 fragmentos** sobre IPv6 (formato, tipos, link-local, EUI-64, SLAAC/DHCPv6, NDP, configuración IOS, subneteo), VLAN/trunk/router-on-a-stick y OSPFv2 (conceptos, configuración, Router ID, vecinos, costo).
- **Con internet y clave de IA:** los fragmentos encontrados se envían al modelo junto con la pregunta (bloque `[FUENTES_LOCALES_RAG]`) para que responda apoyándose en ellos y **cite su id y fuente**. Si no hay fragmentos, se le indica que no invente (`[SIN_MANUALES_LOCALES]`).
- **Sin internet / modo Offline:** responde con el fragmento más relevante **tal cual** (respuesta extractiva), con su **fuente enlazada** y los títulos de otros fragmentos relacionados. Si el fragmento trae comandos, añade el aviso "no probados en un equipo ni en Packet Tracer". Si el corpus no tiene nada, cae a la base antigua (Modbus/OT, ping/fallas, etc.); si tampoco, muestra el menú de ayuda.
- **Perfil:** el estudiante no recibe fragmentos marcados solo para profesionales; el tono del asistente cambia según el perfil.
- **Insignia y comentarios:** cuando una respuesta se apoya en la base local, debajo aparece una línea de verificación ("Base local · verificado con documentación oficial · comandos NO probados en equipo") y tres botones: **Me funcionó**, **No funcionó** (pide una nota opcional) y **Lo probé en Packet Tracer y funciona**. Se guardan en el teléfono (con la pregunta sanitizada y recortada, nunca la conversación completa) y se ven/copian en Configuración → Comentarios. Sirven para que los compañeros verifiquen contenido por ti: cuando varios confirman "probado en PT", se puede subir el fragmento a `probado-en-equipo`.
- **Límites:** el corpus aún es pequeño (P0 parcial). Faltan, entre otros, qué es una VLAN (concepto), STP, ACL, NAT, DHCP, DNS, OSPFv3 y todo Packet Tracer.

### Cómo agregar o corregir conocimiento (para el autor)
1. Cada fragmento es un `.md` con encabezado de metadatos (ver cualquiera en `packages/nettia_knowledge/corpus/publicado/`). Los que no están verificados van en `corpus/borradores/` y **no entran a la app**.
2. Para publicar: cumplir las puertas (mínimo **2 fuentes** si es `fuentes-cruzadas`, fecha, `revisado_por`, palabras clave), moverlo a `corpus/publicado/<tema>/` y ejecutar, desde `packages/nettia_knowledge`: `dart run tool/build_corpus.dart`. Si falta algo, el comando y los tests fallan diciendo qué.
3. `flutter test` en `nettia_knowledge` mide el **golden set** (hoy 22/22 en los 3 primeros y 11/11 en 1.er lugar; ojo: las preguntas se escribieron conociendo el corpus, así que sobreestima).

## 7. Guía Metodológica — [por documentar]
