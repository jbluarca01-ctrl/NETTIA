/// Ejercicios de práctica generados al azar, con corrección campo por campo y
/// el procedimiento resuelto (sin Flutter). Reutiliza la misma lógica que las
/// calculadoras, así que las respuestas correctas son las de la app.
library;

import 'dart:math';

import 'conversiones.dart';
import 'ipv4_subnetting.dart';
import 'ipv6.dart';

/// Tipos de ejercicio disponibles.
enum TipoEjercicio {
  dividirSubredes('Dividir en subredes'),
  hostsPorPrefijo('Hosts, máscara y wildcard'),
  vlsm('VLSM'),
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

String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

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

Ejercicio _vlsm(Random rnd) {
  final base = '192.168.${rnd.nextInt(200) + 1}.0';
  final hosts = <int>[
    _elige(rnd, <int>[60, 80, 100, 110]),
    _elige(rnd, <int>[20, 30, 40, 50]),
    _elige(rnd, <int>[6, 10, 12, 14]),
  ]..sort((a, b) => b.compareTo(a));
  final r = calcularVlsm(base, 24, <RequerimientoVlsm>[
    for (var i = 0; i < hosts.length; i++)
      RequerimientoVlsm('Red ${String.fromCharCode(65 + i)}', hosts[i]),
  ]);
  return Ejercicio(
    tipo: TipoEjercicio.vlsm,
    enunciado: 'Con la red $base/24, asigna subredes VLSM (de mayor a menor) a: '
        '${[for (var i = 0; i < hosts.length; i++) 'Red ${String.fromCharCode(65 + i)} (${hosts[i]} hosts)'].join(', ')}.',
    campos: <CampoRespuesta>[
      for (final s in r.subredes) ...<CampoRespuesta>[
        CampoRespuesta('${s.nombre}: prefijo', '/${s.cidr}', ayuda: 'ej. /26'),
        CampoRespuesta('${s.nombre}: dirección de red', s.red, ayuda: 'a.b.c.d'),
      ],
    ],
    pasos: r.pasos,
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
