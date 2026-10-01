/// Lógica pura de subneteo IPv4 (sin Flutter): dividir una red en N subredes,
/// por hosts por subred y VLSM. Solo aritmética entera con `+`, `-`, `~/` y
/// `%` (sin operadores de bits), para no depender del ancho del entero.
library;

/// Una subred calculada.
class SubredIpv4 {
  const SubredIpv4({
    required this.indice,
    required this.red,
    required this.cidr,
    required this.mascara,
    required this.primerHost,
    required this.ultimoHost,
    required this.broadcast,
    required this.hostsUtiles,
    this.nombre,
  });

  /// Posición (1, 2, 3…) en la lista.
  final int indice;
  final String? nombre;
  final String red;
  final int cidr;
  final String mascara;
  final String primerHost;
  final String ultimoHost;
  final String broadcast;
  final int hostsUtiles;

  /// Gateway sugerido: el primer host útil, el mismo criterio de la pestaña
  /// "Red".
  String get gateway => primerHost;
}

/// Resultado de dividir una red: la lista de subredes y los pasos del cálculo
/// (para poder mostrar cómo se llegó a la respuesta, como en un examen).
class DivisionIpv4 {
  const DivisionIpv4({
    required this.redOriginal,
    required this.cidrOriginal,
    required this.nuevoCidr,
    required this.bitsPrestados,
    required this.subredes,
    required this.subredesPedidas,
    required this.pasos,
    this.avisos = const <String>[],
  });

  final String redOriginal;
  final int cidrOriginal;
  final int nuevoCidr;
  final int bitsPrestados;

  /// Todas las subredes que resultan del nuevo prefijo (puede haber más de
  /// las pedidas: siempre es una potencia de 2).
  final List<SubredIpv4> subredes;
  final int subredesPedidas;
  final List<String> pasos;
  final List<String> avisos;
}

/// Error de validación con un mensaje listo para mostrar al usuario.
class SubneteoException implements Exception {
  const SubneteoException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Un requerimiento de VLSM: nombre (p. ej. "LAN Ventas") y hosts necesarios.
class RequerimientoVlsm {
  const RequerimientoVlsm(this.nombre, this.hosts);
  final String nombre;
  final int hosts;
}

int _pow2(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 2;
  }
  return v;
}

/// Menor `b` tal que 2^b >= [n].
int _bitsPara(int n) {
  var b = 0;
  while (_pow2(b) < n) {
    b++;
  }
  return b;
}

int? _parseIp(String s) {
  final partes = s.trim().split('.');
  if (partes.length != 4) return null;
  var v = 0;
  for (final p in partes) {
    if (p.isEmpty || p.length > 3) return null;
    final o = int.tryParse(p);
    if (o == null || o < 0 || o > 255) return null;
    v = v * 256 + o;
  }
  return v;
}

String _ipTexto(int v) =>
    '${v ~/ 16777216 % 256}.${v ~/ 65536 % 256}.${v ~/ 256 % 256}.${v % 256}';

String _mascaraTexto(int cidr) => _ipTexto(4294967296 - _pow2(32 - cidr));

SubredIpv4 _subred(int indice, int red, int cidr, {String? nombre}) {
  final tam = _pow2(32 - cidr);
  return SubredIpv4(
    indice: indice,
    nombre: nombre,
    red: _ipTexto(red),
    cidr: cidr,
    mascara: _mascaraTexto(cidr),
    primerHost: _ipTexto(red + 1),
    ultimoHost: _ipTexto(red + tam - 2),
    broadcast: _ipTexto(red + tam - 1),
    hostsUtiles: tam - 2,
  );
}

/// Valida la red base y devuelve (dirección de red, avisos). Si la IP no es la
/// dirección de red del prefijo dado, se normaliza y se avisa.
(int, List<String>) _redBase(String ip, int cidr) {
  final v = _parseIp(ip);
  if (v == null) {
    throw const SubneteoException(
        'Dirección IPv4 inválida. Se esperan 4 octetos de 0 a 255.');
  }
  if (cidr < 1 || cidr > 30) {
    throw const SubneteoException('El prefijo debe estar entre /1 y /30.');
  }
  final tam = _pow2(32 - cidr);
  final red = v - v % tam;
  final avisos = <String>[];
  if (red != v) {
    avisos.add('${_ipTexto(v)} no es la dirección de red de /$cidr; se usó '
        '${_ipTexto(red)}/$cidr.');
  }
  return (red, avisos);
}

/// Divide [ip]/[cidr] en [cantidad] subredes del mismo tamaño (subneteo de
/// longitud fija). Si [cantidad] no es potencia de 2, se toma la siguiente y
/// sobran subredes libres.
DivisionIpv4 dividirEnSubredes(String ip, int cidr, int cantidad) {
  final (red, avisos) = _redBase(ip, cidr);
  if (cantidad < 2) {
    throw const SubneteoException('Pide al menos 2 subredes.');
  }
  final bits = _bitsPara(cantidad);
  final nuevo = cidr + bits;
  if (nuevo > 30) {
    throw SubneteoException(
        'No se puede: /$cidr + $bits bits = /$nuevo, y el máximo útil es /30 '
        '(una subred /31 o /32 no tiene hosts en el subneteo clásico).');
  }
  final total = _pow2(bits);
  final tam = _pow2(32 - nuevo);
  final subredes = <SubredIpv4>[
    for (var i = 0; i < total; i++) _subred(i + 1, red + i * tam, nuevo),
  ];
  final extra = <String>[...avisos];
  if (total != cantidad) {
    extra.add('Pediste $cantidad subredes; con $bits bits salen $total. '
        'Usa las primeras $cantidad y deja ${total - cantidad} libres.');
  }
  return DivisionIpv4(
    redOriginal: _ipTexto(red),
    cidrOriginal: cidr,
    nuevoCidr: nuevo,
    bitsPrestados: bits,
    subredes: subredes,
    subredesPedidas: cantidad,
    avisos: extra,
    pasos: <String>[
      '1. Bits a pedir prestados: el menor n con 2^n ≥ $cantidad → n = $bits '
          '(2^$bits = $total subredes).',
      '2. Nuevo prefijo: /$cidr + $bits = /$nuevo '
          '(máscara ${_mascaraTexto(nuevo)}).',
      '3. Tamaño de cada bloque (salto): 2^(32 − $nuevo) = $tam direcciones.',
      '4. Hosts útiles por subred: $tam − 2 = ${tam - 2}.',
      '5. Cada subred empieza $tam direcciones después de la anterior, '
          'desde ${_ipTexto(red)}.',
    ],
  );
}

/// Divide [ip]/[cidr] en subredes del mismo tamaño que admitan al menos
/// [hostsPorSubred] hosts útiles cada una.
DivisionIpv4 dividirPorHosts(String ip, int cidr, int hostsPorSubred) {
  final (red, avisos) = _redBase(ip, cidr);
  if (hostsPorSubred < 1) {
    throw const SubneteoException('Indica al menos 1 host por subred.');
  }
  final bitsHost = _bitsPara(hostsPorSubred + 2);
  final nuevo = 32 - bitsHost;
  if (nuevo > 30) {
    throw const SubneteoException('Con tan pocos hosts la subred sería /31 o '
        '/32; el mínimo útil es 2 hosts (/30).');
  }
  if (nuevo < cidr) {
    throw SubneteoException(
        '$hostsPorSubred hosts por subred necesitan /$nuevo, '
        'que es más grande que la red original /$cidr.');
  }
  final bits = nuevo - cidr;
  final total = _pow2(bits);
  final tam = _pow2(bitsHost);
  return DivisionIpv4(
    redOriginal: _ipTexto(red),
    cidrOriginal: cidr,
    nuevoCidr: nuevo,
    bitsPrestados: bits,
    subredes: <SubredIpv4>[
      for (var i = 0; i < total; i++) _subred(i + 1, red + i * tam, nuevo),
    ],
    subredesPedidas: total,
    avisos: avisos,
    pasos: <String>[
      '1. Bits de host: el menor h con 2^h − 2 ≥ $hostsPorSubred → h = '
          '$bitsHost (2^$bitsHost − 2 = ${tam - 2} hosts útiles).',
      '2. Nuevo prefijo: 32 − $bitsHost = /$nuevo '
          '(máscara ${_mascaraTexto(nuevo)}).',
      '3. Bits prestados a la red original: $nuevo − $cidr = $bits '
          '→ 2^$bits = $total subredes.',
      '4. Salto entre subredes: $tam direcciones.',
    ],
  );
}

/// Resultado de VLSM: una subred por requerimiento, ordenadas de mayor a menor
/// (así se asignan), y el espacio que queda libre.
class ResultadoVlsm {
  const ResultadoVlsm({
    required this.subredes,
    required this.direccionesLibres,
    required this.pasos,
    this.avisos = const <String>[],
  });
  final List<SubredIpv4> subredes;
  final int direccionesLibres;
  final List<String> pasos;
  final List<String> avisos;
}

/// VLSM: asigna a cada requerimiento el bloque más pequeño que le alcance,
/// empezando por el mayor, de forma contigua desde el inicio de la red.
ResultadoVlsm calcularVlsm(
    String ip, int cidr, List<RequerimientoVlsm> requerimientos) {
  final (red, avisos) = _redBase(ip, cidr);
  if (requerimientos.isEmpty) {
    throw const SubneteoException('Agrega al menos una red con sus hosts.');
  }
  for (final r in requerimientos) {
    if (r.hosts < 1) {
      throw SubneteoException('"${r.nombre}" necesita al menos 1 host.');
    }
  }
  final ordenados = <RequerimientoVlsm>[...requerimientos]
    ..sort((a, b) => b.hosts.compareTo(a.hosts));
  final capacidad = _pow2(32 - cidr);
  final pasos = <String>[
    'Se ordenan de mayor a menor y a cada una se le da el bloque más '
        'pequeño con 2^h − 2 ≥ hosts.',
  ];
  var cursor = 0;
  final subredes = <SubredIpv4>[];
  for (var i = 0; i < ordenados.length; i++) {
    final r = ordenados[i];
    final bitsHost = _bitsPara(r.hosts + 2);
    final nuevo = 32 - bitsHost;
    final tam = _pow2(bitsHost);
    if (nuevo > 30) {
      throw SubneteoException('"${r.nombre}": con ${r.hosts} hosts el bloque '
          'sería /$nuevo; el mínimo útil es /30.');
    }
    if (cursor + tam > capacidad) {
      throw SubneteoException(
          'No caben: al asignar "${r.nombre}" (${r.hosts} hosts, bloque de '
          '$tam) se acaba el espacio de ${_ipTexto(red)}/$cidr '
          '($capacidad direcciones). Usa una red más grande.');
    }
    subredes.add(_subred(i + 1, red + cursor, nuevo, nombre: r.nombre));
    pasos.add('${i + 1}. ${r.nombre}: ${r.hosts} hosts → h = $bitsHost '
        '(${tam - 2} útiles) → /$nuevo, empieza en ${_ipTexto(red + cursor)}.');
    cursor += tam;
  }
  return ResultadoVlsm(
    subredes: subredes,
    direccionesLibres: capacidad - cursor,
    avisos: avisos,
    pasos: pasos,
  );
}
