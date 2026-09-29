/// Doctor de consola: diagnostica mensajes de IOS y de una PC pegados por el
/// usuario (sin red, por reglas). Cada línea se compara con un catálogo de
/// mensajes reales (syslog de IOS, errores del parser y salida de ping).
library;

/// Un problema detectado, con su causa y los pasos o comandos que lo corrigen.
class Diagnostico {
  const Diagnostico(this.titulo, this.causa, this.solucion);
  final String titulo;
  final String causa;
  final List<String> solucion;
}

class _Regla {
  const _Regla(this.patron, this.crear);
  final String patron;
  final Diagnostico Function(RegExpMatch m) crear;
}

final List<_Regla> _reglas = [
  _Regla(
    r'LINK-\d-CHANGED: Interface (\S+), changed state to administratively down',
    (m) => Diagnostico('Interfaz apagada', '${m[1]} está en shutdown.', [
      'interface ${m[1]}',
      'no shutdown',
    ]),
  ),
  _Regla(
    r'LINK-\d-UPDOWN: Interface (\S+), changed state to down',
    (m) => Diagnostico(
      'Enlace caído',
      '${m[1]} no detecta señal: cable desconectado, tipo de cable '
          'incorrecto o el otro extremo apagado.',
      [
        'Revisa el cable y que el otro extremo tenga no shutdown.',
        'show interfaces ${m[1]}',
      ],
    ),
  ),
  _Regla(
    r'Line protocol on Interface (\S+), changed state to down',
    (m) => Diagnostico(
      'Protocolo de línea caído',
      '${m[1]} tiene señal pero la capa 2 no sube: encapsulación distinta, '
          'falta clock rate en el extremo DCE o el otro lado está apagado.',
      [
        'show interfaces ${m[1]}',
        'En el extremo DCE de un serial: clock rate 64000',
        'Usa la misma encapsulación en ambos extremos.',
      ],
    ),
  ),
  _Regla(
    r'Native VLAN mismatch discovered on (\S+) \((\d+)\), with (.+) \((\d+)\)',
    (m) => Diagnostico(
      'VLAN nativa distinta en el troncal',
      '${m[1]} usa la nativa ${m[2]} y el otro extremo (${m[3]}) usa la ${m[4]}.',
      [
        'En ambos extremos del troncal:',
        'interface ${m[1]}',
        'switchport trunk native vlan ${m[2]}',
      ],
    ),
  ),
  _Regla(
    r'% (\S+) overlaps with (\S+)',
    (m) => Diagnostico(
      'Redes solapadas',
      'La red ${m[1]} ya está en ${m[2]}; dos interfaces de un router no '
          'pueden estar en la misma subred.',
      [
        'Usa otra subred (el Diseñador de red las calcula sin solaparse).',
        'show ip interface brief',
      ],
    ),
  ),
  _Regla(
    r'Bad mask (\S+) for address (\S+)',
    (m) => Diagnostico(
      'Máscara inválida',
      '${m[1]} no es una máscara válida para ${m[2]}.',
      [
        'Usa una máscara contigua, p. ej. 255.255.255.0 (/24).',
        'ip address ${m[2]} <máscara>',
      ],
    ),
  ),
  _Regla(
    r'Duplicate address (\S+) on (\S+), sourced by (\S+)',
    (m) => Diagnostico(
      'IP duplicada',
      'Otro equipo (MAC ${m[3]}) usa ${m[1]} en ${m[2]}.',
      [
        'Cambia la IP fija de uno de los dos equipos.',
        'Si la entrega el DHCP, exclúyela: ip dhcp excluded-address ${m[1]}',
      ],
    ),
  ),
  _Regla(
    r'DHCP address conflict:\s+server pinged (\d+\.\d+\.\d+\.\d+)',
    (m) => Diagnostico(
      'Conflicto de DHCP',
      '${m[1]} está en el pool pero ya la usa un equipo con IP fija.',
      ['ip dhcp excluded-address ${m[1]}', 'clear ip dhcp conflict *'],
    ),
  ),
  _Regla(
    r'psecure-violation error detected on (\S+), putting',
    (m) => Diagnostico(
      'Puerto bloqueado por port-security',
      '${m[1]} vio una MAC no permitida y quedó en err-disable.',
      [
        'show port-security interface ${m[1]}',
        'interface ${m[1]}',
        'shutdown',
        'no shutdown',
      ],
    ),
  ),
  _Regla(
    r'(\S+) error detected on (\S+), putting',
    (m) => Diagnostico(
      'Puerto en err-disable',
      '${m[2]} se desactivó por ${m[1]}.',
      [
        'Corrige la causa antes de reactivarlo.',
        'interface ${m[2]}',
        'shutdown',
        'no shutdown',
      ],
    ),
  ),
  _Regla(
    r'Host (\S+) in vlan (\d+) is flapping between port (\S+) and port (\S+)',
    (m) => Diagnostico(
      'Posible bucle de capa 2',
      'La MAC ${m[1]} salta entre ${m[3]} y ${m[4]} en la VLAN ${m[2]}.',
      [
        'Revisa enlaces redundantes entre switches.',
        'show spanning-tree vlan ${m[2]}',
      ],
    ),
  ),
  _Regla(
    r'Nbr (\S+) on (\S+) from \S+ to DOWN',
    (m) => Diagnostico(
      'Vecino OSPF perdido',
      'El vecino ${m[1]} dejó de enviar hellos por ${m[2]}.',
      [
        'show ip ospf neighbor',
        'Compara en ambos routers hello/dead, área y subred: '
            'show ip ospf interface ${m[2]}',
      ],
    ),
  ),
  _Regla(
    r'Translating "(.+?)"\.\.\.domain server',
    (m) => Diagnostico(
      'IOS intentó resolver un nombre',
      '"${m[1]}" no es un comando, así que IOS lo tomó como nombre de '
          'equipo y lo buscó por DNS.',
      [
        'Corrige el comando.',
        'Para no esperar la próxima vez: no ip domain-lookup',
      ],
    ),
  ),
  _Regla(
    r'% Incomplete command',
    (m) => const Diagnostico(
      'Comando incompleto',
      'Faltan parámetros al final del comando.',
      ['Repite el comando y escribe ? al final para ver qué falta.'],
    ),
  ),
  _Regla(
    r'% Ambiguous command:\s+"(.*)"',
    (m) => Diagnostico(
      'Comando ambiguo',
      'La abreviatura "${m[1]}" coincide con varios comandos.',
      ['Escribe más letras o usa ? para ver las opciones.'],
    ),
  ),
  _Regla(
    r'Request timed out',
    (m) => const Diagnostico(
      'Ping sin respuesta',
      'El paquete salió pero no volvió: revisa gateway, VLAN del puerto y '
          'ruta de regreso.',
      [
        '1) ping a tu gateway',
        '2) show vlan brief: ¿el puerto está en la VLAN correcta?',
        '3) show interfaces trunk: ¿el troncal permite la VLAN?',
        '4) show ip route en el router: ¿hay ruta de regreso?',
      ],
    ),
  ),
  _Regla(
    r'Destination host unreachable',
    (m) => const Diagnostico(
      'Destino inalcanzable',
      'Algún equipo no sabe cómo llegar: falta el gateway en la PC o una '
          'ruta en el router.',
      ['ipconfig: ¿la PC tiene default gateway?', 'show ip route en el router'],
    ),
  ),
];

const String _marcaInvalida = "% Invalid input detected at '^' marker.";

/// Diagnósticos de [salida], en el orden en que aparecen y sin repetir.
List<Diagnostico> diagnosticarConsola(String salida) {
  final lineas = salida.split('\n');
  final resultado = <Diagnostico>[];
  final vistos = <String>{};
  for (var i = 0; i < lineas.length; i++) {
    final d =
        lineas[i].contains(_marcaInvalida)
            ? _entradaInvalida(lineas, i)
            : _porRegla(lineas[i]);
    if (d != null && vistos.add('${d.titulo}|${d.causa}')) resultado.add(d);
  }
  return resultado;
}

Diagnostico? _porRegla(String linea) {
  for (final regla in _reglas) {
    final m = RegExp(regla.patron).firstMatch(linea);
    if (m != null) return regla.crear(m);
  }
  return null;
}

/// IOS marca con ^ la columna donde dejó de entender el comando de la línea
/// anterior a la marca.
Diagnostico _entradaInvalida(List<String> lineas, int i) {
  final caret = i >= 2 ? lineas[i - 1].indexOf('^') : -1;
  final comando = i >= 2 ? lineas[i - 2] : '';
  final prompt = RegExp(r'^\S+?[>#]').firstMatch(comando)?[0];
  if (caret < 0 || prompt == null || caret >= comando.length) {
    return const Diagnostico(
      'Comando no reconocido',
      'IOS no entiende una parte del comando (la marca ^ señala dónde).',
      ['Escribe ? en ese punto para ver las opciones válidas.'],
    );
  }
  final token = comando.substring(caret).split(' ').first;
  final (modo, consejo) = _modo(prompt);
  return Diagnostico(
    'Comando no reconocido',
    'IOS no entiende "$token" en el modo $modo ($prompt).',
    [
      'Revisa cómo escribiste "$token".',
      'Escribe ? en ese punto para ver las opciones válidas.',
      consejo,
    ],
  );
}

(String, String) _modo(String prompt) {
  if (prompt.endsWith('>')) {
    return ('usuario', 'Estás en modo usuario: entra primero con enable.');
  }
  if (prompt.endsWith('(config)#')) {
    return (
      'de configuración global',
      'Si es un comando de interfaz, entra primero con interface <nombre>.',
    );
  }
  if (prompt.contains('(config-')) {
    return ('de subconfiguración', 'Si es un comando global, sal con exit.');
  }
  return (
    'privilegiado',
    'Si es un comando de configuración, entra con configure terminal.',
  );
}
