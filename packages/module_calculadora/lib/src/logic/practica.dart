/// Ejercicios de práctica generados al azar, con corrección campo por campo y
/// el procedimiento resuelto (sin Flutter). Reutiliza la misma lógica que las
/// calculadoras, así que las respuestas correctas son las de la app.
library;

import 'dart:math';

import 'and_ipv4.dart';
import 'clasificacion_ipv4.dart';
import 'conversiones.dart';
import 'ipv4_subnetting.dart';
import 'ipv6.dart';

/// Tipos de ejercicio disponibles.
enum TipoEjercicio {
  dividirSubredes('Dividir en subredes'),
  hostsPorPrefijo('Hosts, máscara y wildcard'),
  vlsm('VLSM'),
  redDeIp('Red y broadcast de una IP'),
  clasificar('Clase y tipo de una IP'),
  asignable('¿Se puede asignar?'),
  ipv6Abreviar('IPv6: abreviar'),
  ipv6Eui64('IPv6: EUI-64');

  const TipoEjercicio(this.titulo);
  final String titulo;
}

/// Una pregunta con su respuesta correcta.
class CampoRespuesta {
  const CampoRespuesta(this.etiqueta, this.correcta, {this.ayuda = ''});

  final String etiqueta;
  final String correcta;

  /// Formato esperado (p. ej. "/28" o "192.168.1.16").
  final String ayuda;
}

class Ejercicio {
  const Ejercicio({
    required this.tipo,
    required this.enunciado,
    required this.campos,
    required this.pasos,
  });

  final TipoEjercicio tipo;
  final String enunciado;
  final List<CampoRespuesta> campos;

  /// Procedimiento resuelto, para mostrar después de corregir.
  final List<String> pasos;
}

/// Resultado de corregir un campo.
class ResultadoCampo {
  const ResultadoCampo(this.campo, this.respuesta, this.acierto);
  final CampoRespuesta campo;
  final String respuesta;
  final bool acierto;
}

const _sinTilde = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};

/// Sin espacios, en minúsculas y sin tildes ("Pública" = "publica").
String _norm(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAllMapped(RegExp('[áéíóú]'), (m) => _sinTilde[m[0]]!);

/// Compara ignorando espacios, mayúsculas y la barra inicial de un prefijo
/// ("/28" y "28" cuentan igual).
bool _iguales(String correcta, String dada) {
  var a = _norm(correcta);
  var b = _norm(dada);
  if (a.startsWith('/') && !b.startsWith('/')) b = '/$b';
  if (b.isEmpty) return false;
  return a == b;
}

/// Corrige [respuestas] (una por campo, en orden).
List<ResultadoCampo> corregir(Ejercicio e, List<String> respuestas) => [
      for (var i = 0; i < e.campos.length; i++)
        ResultadoCampo(
          e.campos[i],
          i < respuestas.length ? respuestas[i] : '',
          _iguales(e.campos[i].correcta, i < respuestas.length ? respuestas[i] : ''),
        ),
    ];

T _elige<T>(Random r, List<T> l) => l[r.nextInt(l.length)];

/// Genera un ejercicio de [tipo]. Pasar un [Random] con semilla lo hace
/// reproducible (pruebas).
Ejercicio generarEjercicio(TipoEjercicio tipo, Random rnd) {
  switch (tipo) {
    case TipoEjercicio.dividirSubredes:
      return _dividir(rnd);
    case TipoEjercicio.hostsPorPrefijo:
      return _hostsPorPrefijo(rnd);
    case TipoEjercicio.vlsm:
      return _vlsm(rnd);
    case TipoEjercicio.redDeIp:
      return _redDeIp(rnd);
    case TipoEjercicio.clasificar:
      return ejercicioClasificar(_elige(rnd, _ipsParaClasificar));
    case TipoEjercicio.asignable:
      return _asignable(rnd);
    case TipoEjercicio.ipv6Abreviar:
      return _ipv6Abreviar(rnd);
    case TipoEjercicio.ipv6Eui64:
      return _ipv6Eui64(rnd);
  }
}

Ejercicio _dividir(Random rnd) {
  final bases = <(String, int)>[
    ('192.168.${rnd.nextInt(200) + 1}.0', 24),
    ('10.${rnd.nextInt(200) + 1}.0.0', 16),
    ('172.16.0.0', 16),
    ('192.168.${rnd.nextInt(200) + 1}.0', 24),
  ];
  final (red, pre) = _elige(rnd, bases);
  final cantidad = _elige(rnd, <int>[2, 4, 5, 6, 8, 10, 12, 16, 20, 32]);
  final d = dividirEnSubredes(red, pre, cantidad);
  final k = 2 + rnd.nextInt(cantidad - 1); // 2..cantidad
  final s = subredNumero(d, k);
  return Ejercicio(
    tipo: TipoEjercicio.dividirSubredes,
    enunciado: 'Divide la red $red/$pre en $cantidad subredes del mismo tamaño.',
    campos: <CampoRespuesta>[
      CampoRespuesta('Nuevo prefijo', '/${d.nuevoCidr}', ayuda: 'ej. /28'),
      CampoRespuesta('Máscara de las subredes', s.mascara, ayuda: 'ej. 255.255.255.240'),
      CampoRespuesta('Hosts útiles por subred', '${s.hostsUtiles}'),
      CampoRespuesta('Dirección de red de la subred #$k', s.red, ayuda: 'a.b.c.d'),
      CampoRespuesta('Broadcast de la subred #$k', s.broadcast, ayuda: 'a.b.c.d'),
    ],
    pasos: d.pasos,
  );
}

Ejercicio _hostsPorPrefijo(Random rnd) {
  final p = 16 + rnd.nextInt(15); // /16 a /30
  final c = convertirMascara('/$p');
  return Ejercicio(
    tipo: TipoEjercicio.hostsPorPrefijo,
    enunciado: 'Para el prefijo /$p:',
    campos: <CampoRespuesta>[
      CampoRespuesta('Máscara decimal', c.mascara, ayuda: 'a.b.c.d'),
      CampoRespuesta('Wildcard', c.wildcard, ayuda: 'a.b.c.d'),
      CampoRespuesta('Hosts útiles', '${c.hosts}'),
    ],
    pasos: <String>[
      '1. Los ${32 - p} bits finales son de host: 2^${32 - p} = ${c.hosts + 2} direcciones.',
      '2. Hosts útiles = ${c.hosts + 2} − 2 = ${c.hosts}.',
      '3. Máscara: $p unos y ${32 - p} ceros = ${c.mascara}.',
      '4. Wildcard = inverso de la máscara = ${c.wildcard}.',
    ],
  );
}

Ejercicio _vlsm(Random rnd) => ejercicioVlsm(
      '192.168.${rnd.nextInt(200) + 1}.0',
      24,
      <int>[
        _elige(rnd, <int>[40, 45, 50, 55, 60]),
        _elige(rnd, <int>[18, 20, 25, 28, 30]),
        _elige(rnd, <int>[7, 10, 12, 14]),
        _elige(rnd, <int>[2, 3, 5, 6]),
      ],
    );

/// VLSM de [base]/[cidr] para [hosts] (se asignan de mayor a menor): pide
/// prefijo, red y broadcast de cada red, como la tabla de la Clase 17.
Ejercicio ejercicioVlsm(String base, int cidr, List<int> hosts) {
  final orden = <int>[...hosts]..sort((a, b) => b.compareTo(a));
  final nombres = <String>[
    for (var i = 0; i < orden.length; i++) 'Red ${String.fromCharCode(65 + i)}',
  ];
  final r = calcularVlsm(base, cidr, <RequerimientoVlsm>[
    for (var i = 0; i < orden.length; i++) RequerimientoVlsm(nombres[i], orden[i]),
  ]);
  final pedidas = [
    for (var i = 0; i < orden.length; i++) '${nombres[i]} (${orden[i]} hosts)',
  ].join(', ');
  return Ejercicio(
    tipo: TipoEjercicio.vlsm,
    enunciado: 'Con la red $base/$cidr, asigna subredes VLSM (de mayor a '
        'menor) a: $pedidas.',
    campos: <CampoRespuesta>[
      for (final s in r.subredes) ...<CampoRespuesta>[
        CampoRespuesta('${s.nombre}: prefijo', '/${s.cidr}', ayuda: 'ej. /26'),
        CampoRespuesta('${s.nombre}: dirección de red', s.red, ayuda: 'a.b.c.d'),
        CampoRespuesta('${s.nombre}: broadcast', s.broadcast, ayuda: 'a.b.c.d'),
      ],
    ],
    pasos: r.pasos,
  );
}

List<int> _octetos(String ip) => ip.split('.').map(int.parse).toList();

int _valor(List<int> o) => ((o[0] * 256 + o[1]) * 256 + o[2]) * 256 + o[3];

String _texto(int v) =>
    '${v ~/ 16777216 % 256}.${v ~/ 65536 % 256}.${v ~/ 256 % 256}.${v % 256}';

/// (red, broadcast) de [v] con /[cidr], como enteros.
(int, int) _extremos(int v, int cidr) {
  final tam = pow(2, 32 - cidr).toInt();
  final red = v - v % tam;
  return (red, red + tam - 1);
}

String _ipPrivadaAlAzar(Random rnd) {
  final primero = _elige(rnd, <int>[10, 172, 192]);
  final segundo = switch (primero) {
    10 => rnd.nextInt(256),
    172 => 16 + rnd.nextInt(16),
    _ => 168,
  };
  return '$primero.$segundo.${rnd.nextInt(256)}.${rnd.nextInt(256)}';
}

Ejercicio _redDeIp(Random rnd) =>
    ejercicioRedDeIp(_ipPrivadaAlAzar(rnd), 16 + rnd.nextInt(15));

/// "¿A qué red pertenece [ip]/[cidr]?": red, broadcast y rango útil con el
/// AND del octeto interesante (Clases 13 y 15).
Ejercicio ejercicioRedDeIp(String ip, int cidr) {
  final o = _octetos(ip);
  final (red, bc) = _extremos(_valor(o), cidr);
  return Ejercicio(
    tipo: TipoEjercicio.redDeIp,
    enunciado: 'La IP $ip/$cidr: ¿a qué red pertenece? Da su red, broadcast '
        'y rango útil.',
    campos: <CampoRespuesta>[
      CampoRespuesta('Dirección de red', _texto(red), ayuda: 'a.b.c.d'),
      CampoRespuesta('Broadcast', _texto(bc), ayuda: 'a.b.c.d'),
      CampoRespuesta('Primer host útil', _texto(red + 1), ayuda: 'a.b.c.d'),
      CampoRespuesta('Último host útil', _texto(bc - 1), ayuda: 'a.b.c.d'),
    ],
    pasos: _pasosAnd(o, cidr, _texto(red), _texto(bc)),
  );
}

List<String> _pasosAnd(List<int> o, int cidr, String red, String bc) {
  final mascara = mascaraDePrefijo(cidr);
  final oi = octetoInteresante(o, cidr);
  if (oi == null) {
    return <String>[
      '1. Máscara /$cidr = $mascara: corta justo entre octetos, los '
          '${cidr ~/ 8} primeros octetos son de red y el resto de host.',
      '2. Red: se copian los octetos de red y el resto va en 0 → $red.',
      '3. Broadcast: el resto va en 255 → $bc.',
      '4. Rango útil: red + 1 a broadcast − 1.',
    ];
  }
  final n = oi.posicion;
  return <String>[
    '1. Máscara /$cidr = $mascara: el octeto interesante es el $n.º '
        '(${oi.mascara}).',
    '2. Bloque = 256 − ${oi.mascara} = ${oi.bloque}.',
    '3. AND del $n.º octeto: ${oi.operacion} → red $red.',
    '4. Broadcast: la red + ${oi.bloque - 1} en ese octeto y 255 en los '
        'siguientes → $bc.',
    '5. Rango útil: red + 1 a broadcast − 1.',
  ];
}

/// Direcciones de la guía de la Clase 14, con sus trampas.
const _ipsParaClasificar = <String>[
  '10.15.3.7', '172.20.5.9', '192.168.1.20', '8.8.8.8', '172.15.1.1',
  '224.10.10.10', '240.0.0.1', '169.254.10.5', '127.0.0.1',
  '255.255.255.255', '172.32.0.9', '200.1.2.3', '130.5.6.7', '192.169.1.1',
];

/// Respuesta corta esperada para cada tipo.
const _respuestaTipo = <TipoIpv4, String>{
  TipoIpv4.publica: 'publica',
  TipoIpv4.privada: 'privada',
  TipoIpv4.loopback: 'loopback',
  TipoIpv4.apipa: 'apipa',
  TipoIpv4.multicast: 'multicast',
  TipoIpv4.experimental: 'experimental',
  TipoIpv4.broadcastLimitado: 'broadcast',
  TipoIpv4.noEspecificada: 'no especificada',
  TipoIpv4.reservada: 'reservada',
};

/// Clase (letra) y tipo de [ip] (Clase 14).
Ejercicio ejercicioClasificar(String ip) {
  final c = clasificarIpv4(ip)!;
  return Ejercicio(
    tipo: TipoEjercicio.clasificar,
    enunciado: '¿De qué clase es $ip y qué tipo de dirección es?',
    campos: <CampoRespuesta>[
      CampoRespuesta('Clase', c.clase.letra, ayuda: 'A, B, C, D o E'),
      CampoRespuesta('Tipo', _respuestaTipo[c.tipo]!,
          ayuda: 'publica, privada, loopback, apipa, multicast, '
              'experimental o broadcast'),
    ],
    pasos: <String>[c.explicacion],
  );
}

Ejercicio _asignable(Random rnd) {
  final cidr = 24 + rnd.nextInt(8); // /24 a /31
  final (red, bc) = _extremos(_valor(_octetos(_ipPrivadaAlAzar(rnd))), cidr);
  final ip = switch (rnd.nextInt(3)) {
    0 => red,
    1 => bc,
    _ => cidr == 31 ? red : red + 1 + rnd.nextInt(bc - red - 1),
  };
  return ejercicioAsignable(_texto(ip), cidr);
}

/// (respuesta, motivo) de si [v] se puede asignar en [red]–[bc] con /[cidr].
(String, String) _motivoAsignable(int v, int red, int bc, int cidr) {
  if (cidr == 31) {
    return ('si', '/31 es un enlace punto a punto: las 2 direcciones se '
        'usan, una por extremo.');
  }
  if (v == red) return ('no', 'es la dirección de red: identifica a la subred.');
  if (v == bc) return ('no', 'es el broadcast: va a todos los hosts de la subred.');
  return ('si', 'está entre la red y el broadcast: es un host válido.');
}

/// "¿Se puede asignar [ip]/[cidr] a un host?" (red, broadcast y /31).
Ejercicio ejercicioAsignable(String ip, int cidr) {
  final v = _valor(_octetos(ip));
  final (red, bc) = _extremos(v, cidr);
  final (respuesta, motivo) = _motivoAsignable(v, red, bc, cidr);
  return Ejercicio(
    tipo: TipoEjercicio.asignable,
    enunciado: '¿Se puede asignar $ip/$cidr a un host?',
    campos: <CampoRespuesta>[
      CampoRespuesta('¿Se puede asignar a un host? (si/no)', respuesta),
    ],
    pasos: <String>[
      '1. Red de $ip/$cidr: ${_texto(red)}; broadcast: ${_texto(bc)}.',
      '2. $ip: $motivo',
    ],
  );
}

Ejercicio _ipv6Abreviar(Random rnd) {
  final g = List<int>.generate(8, (_) => rnd.nextInt(0x10000));
  // Racha de ceros para que haya algo que abreviar.
  final ini = rnd.nextInt(5);
  final largo = 2 + rnd.nextInt(3);
  for (var i = ini; i < ini + largo && i < 8; i++) {
    g[i] = 0;
  }
  g[0] = 0x2001;
  // Algunos grupos con ceros a la izquierda visibles.
  final a = Ipv6(g);
  return Ejercicio(
    tipo: TipoEjercicio.ipv6Abreviar,
    enunciado: 'Escribe en su forma abreviada recomendada (RFC 5952): ${a.expandida}',
    campos: <CampoRespuesta>[
      CampoRespuesta('Dirección abreviada', a.abreviada, ayuda: 'minúsculas, :: en la racha más larga'),
    ],
    pasos: <String>[
      '1. Quita los ceros a la izquierda de cada grupo.',
      '2. Reemplaza con :: la racha más larga de grupos en cero (de 2 o más; si hay empate, la primera).',
      '3. Minúsculas. Resultado: ${a.abreviada}.',
    ],
  );
}

Ejercicio _ipv6Eui64(Random rnd) {
  String par() => rnd.nextInt(256).toRadixString(16).padLeft(2, '0');
  final mac = List<String>.generate(6, (_) => par()).join(':');
  final prefijo = Ipv6.parse('2001:db8:${rnd.nextInt(0xfff).toRadixString(16)}:${rnd.nextInt(16).toRadixString(16)}::');
  final dir = direccionEui64(prefijo, mac);
  final id = eui64DesdeMac(mac).map((x) => x.toRadixString(16).padLeft(4, '0')).join(':');
  return Ejercicio(
    tipo: TipoEjercicio.ipv6Eui64,
    enunciado: 'Con el prefijo ${prefijo.abreviada}/64 y la MAC $mac, ¿qué dirección IPv6 forma EUI-64?',
    campos: <CampoRespuesta>[
      CampoRespuesta('Dirección (abreviada)', dir.abreviada, ayuda: 'minúsculas'),
    ],
    pasos: <String>[
      '1. Inserta ff:fe en medio de la MAC.',
      '2. Invierte el 7.º bit del primer byte (el bit universal/local).',
      '3. Identificador: $id → dirección ${dir.abreviada}.',
    ],
  );
}
