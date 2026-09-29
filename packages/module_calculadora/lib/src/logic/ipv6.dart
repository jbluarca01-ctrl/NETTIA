/// Lógica pura de IPv6 (sin Flutter): expandir/abreviar, tipo de dirección,
/// EUI-64 y subneteo de un prefijo. Los tipos y formatos siguen RFC 4291
/// (direccionamiento) y RFC 5952 (representación textual recomendada).
library;

/// Error de validación con un mensaje listo para mostrar.
class Ipv6Exception implements Exception {
  const Ipv6Exception(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Una dirección IPv6 como 8 grupos de 16 bits.
class Ipv6 {
  Ipv6(List<int> grupos) : grupos = List<int>.unmodifiable(grupos) {
    assert(grupos.length == 8);
  }

  final List<int> grupos;

  /// Interpreta texto IPv6 (con `::` opcional; sin zona `%` ni sufijo IPv4).
  factory Ipv6.parse(String texto) {
    final t = texto.trim().toLowerCase();
    if (t.isEmpty) throw const Ipv6Exception('Escribe una dirección IPv6.');
    if (t.contains('%') || t.contains('/')) {
      throw const Ipv6Exception(
          'Escribe solo la dirección, sin "/prefijo" ni zona (%).');
    }
    if (t.contains('.')) {
      throw const Ipv6Exception(
          'Las direcciones con sufijo IPv4 (::ffff:1.2.3.4) no están '
          'soportadas; escríbela en hexadecimal.');
    }
    if (RegExp(r'[^0-9a-f:]').hasMatch(t)) {
      throw const Ipv6Exception(
          'Solo se permiten dígitos hexadecimales (0-9, a-f) y ":".');
    }
    if (t.contains(':::')) {
      throw const Ipv6Exception('Hay demasiados ":" seguidos.');
    }
    final dobles = '::'.allMatches(t).length;
    if (dobles > 1) {
      throw const Ipv6Exception('"::" solo puede aparecer una vez.');
    }

    List<String> partes(String s) =>
        s.isEmpty ? <String>[] : s.split(':');

    List<String> izq;
    List<String> der = <String>[];
    if (dobles == 1) {
      final i = t.indexOf('::');
      izq = partes(t.substring(0, i));
      der = partes(t.substring(i + 2));
      if (izq.length + der.length > 7) {
        throw const Ipv6Exception(
            'Demasiados grupos: con "::" caben como máximo 7 grupos escritos.');
      }
    } else {
      izq = partes(t);
      if (izq.length != 8) {
        throw Ipv6Exception(
            'Sin "::" se necesitan 8 grupos y hay ${izq.length}.');
      }
    }
    final relleno = 8 - izq.length - der.length;
    final todos = <String>[
      ...izq,
      ...List<String>.filled(dobles == 1 ? relleno : 0, '0'),
      ...der,
    ];
    final grupos = <int>[];
    for (final g in todos) {
      if (g.isEmpty || g.length > 4) {
        throw Ipv6Exception('Grupo inválido: "$g" (1 a 4 dígitos hex).');
      }
      grupos.add(int.parse(g, radix: 16));
    }
    return Ipv6(grupos);
  }

  BigInt toBigInt() {
    var v = BigInt.zero;
    for (final g in grupos) {
      v = (v << 16) | BigInt.from(g);
    }
    return v;
  }

  factory Ipv6.fromBigInt(BigInt v) {
    final g = List<int>.filled(8, 0);
    var r = v;
    for (var i = 7; i >= 0; i--) {
      g[i] = (r & BigInt.from(0xffff)).toInt();
      r = r >> 16;
    }
    return Ipv6(g);
  }

  /// Forma completa: 8 grupos de 4 dígitos.
  String get expandida => grupos.map((g) => g.toRadixString(16).padLeft(4, '0')).join(':');

  /// Forma abreviada recomendada (RFC 5952): sin ceros a la izquierda, `::`
  /// para la racha más larga de grupos en cero (de 2 o más; la primera si hay
  /// empate), minúsculas.
  String get abreviada {
    var mejorIni = -1;
    var mejorLen = 0;
    var i = 0;
    while (i < 8) {
      if (grupos[i] == 0) {
        var j = i;
        while (j < 8 && grupos[j] == 0) {
          j++;
        }
        if (j - i > mejorLen) {
          mejorIni = i;
          mejorLen = j - i;
        }
        i = j;
      } else {
        i++;
      }
    }
    String hex(int g) => g.toRadixString(16);
    if (mejorLen < 2) return grupos.map(hex).join(':');
    final izq = grupos.sublist(0, mejorIni).map(hex).join(':');
    final der = grupos.sublist(mejorIni + mejorLen).map(hex).join(':');
    return '$izq::$der';
  }

  @override
  String toString() => abreviada;
}

/// Clasificación de una dirección IPv6.
class TipoIpv6 {
  const TipoIpv6(this.nombre, this.prefijo, this.descripcion);
  final String nombre;
  final String prefijo;
  final String descripcion;
}

const Map<int, String> _ambitosMulticast = <int, String>{
  1: 'interfaz local',
  2: 'enlace local (link-local)',
  4: 'administrativo local',
  5: 'sitio local',
  8: 'organización local',
  14: 'global',
};

/// Tipo de una dirección según RFC 4291 / RFC 4193 / RFC 3849.
TipoIpv6 clasificarIpv6(Ipv6 a) {
  final g = a.grupos;
  final resto0 = g.sublist(0, 7).every((x) => x == 0);
  if (resto0 && g[7] == 0) {
    return const TipoIpv6('No especificada', '::/128',
        'Dirección sin asignar; un host la usa como origen mientras no tiene IP.');
  }
  if (resto0 && g[7] == 1) {
    return const TipoIpv6('Loopback', '::1/128',
        'Equivale a 127.0.0.1 en IPv4: el propio equipo.');
  }
  if (g.sublist(0, 5).every((x) => x == 0) && g[5] == 0xffff) {
    return const TipoIpv6('IPv4 mapeada', '::ffff:0:0/96',
        'Representa una dirección IPv4 dentro de IPv6.');
  }
  if (g[0] == 0x2001 && g[1] == 0x0db8) {
    return const TipoIpv6('Documentación', '2001:db8::/32',
        'Reservada para ejemplos y manuales; no se enruta en Internet.');
  }
  if (g[0] >= 0xff00) {
    final ambito = _ambitosMulticast[g[0] % 16] ?? 'otro';
    return TipoIpv6('Multicast', 'ff00::/8', 'Ámbito: $ambito.');
  }
  if (g[0] >= 0xfe80 && g[0] <= 0xfebf) {
    return const TipoIpv6('Link-local', 'fe80::/10',
        'Válida solo en el enlace local; no la enruta ningún router. '
        'Toda interfaz IPv6 activa tiene una.');
  }
  if (g[0] >= 0xfc00 && g[0] <= 0xfdff) {
    return const TipoIpv6('Local única (ULA)', 'fc00::/7',
        'Privada, equivalente a las redes privadas de IPv4; en la práctica '
        'se usa fd00::/8.');
  }
  if (g[0] >= 0x2000 && g[0] <= 0x3fff) {
    return const TipoIpv6('Unicast global (GUA)', '2000::/3',
        'Enrutable en Internet.');
  }
  return const TipoIpv6('Otra / reservada', '—',
      'No corresponde a un tipo de uso común.');
}

/// Identificador de interfaz EUI-64 a partir de una MAC (RFC 4291, apéndice A):
/// se inserta `fffe` en medio y se invierte el bit universal/local (el 7.º
/// bit del primer byte). Devuelve los 4 grupos de 16 bits.
List<int> eui64DesdeMac(String mac) {
  final limpia = mac.trim().toLowerCase().replaceAll(RegExp(r'[:\-.\s]'), '');
  if (!RegExp(r'^[0-9a-f]{12}$').hasMatch(limpia)) {
    throw const Ipv6Exception(
        'MAC inválida. Se esperan 12 dígitos hexadecimales '
        '(ej. 00:1A:2B:3C:4D:5E).');
  }
  final b = <int>[
    for (var i = 0; i < 12; i += 2) int.parse(limpia.substring(i, i + 2), radix: 16),
  ];
  // Invierte el bit U/L (0x02) sin usar operadores de bits.
  final primero = (b[0] ~/ 2) % 2 == 0 ? b[0] + 2 : b[0] - 2;
  return <int>[
    primero * 256 + b[1],
    b[2] * 256 + 0xff,
    0xfe * 256 + b[3],
    b[4] * 256 + b[5],
  ];
}

/// Dirección completa: [prefijo] (64 bits altos, ya alineado) + EUI-64.
Ipv6 direccionEui64(Ipv6 prefijo64, String mac) {
  final id = eui64DesdeMac(mac);
  return Ipv6(<int>[...prefijo64.grupos.sublist(0, 4), ...id]);
}

/// Subred IPv6 resultante.
class SubredIpv6 {
  const SubredIpv6(this.indice, this.red, this.prefijo);
  final BigInt indice;
  final Ipv6 red;
  final int prefijo;
}

/// Resultado de subnetear un prefijo.
class DivisionIpv6 {
  const DivisionIpv6({
    required this.redOriginal,
    required this.prefijoOriginal,
    required this.nuevoPrefijo,
    required this.totalSubredes,
    required this.primeras,
    required this.pasos,
    this.avisos = const <String>[],
  });
  final Ipv6 redOriginal;
  final int prefijoOriginal;
  final int nuevoPrefijo;
  final BigInt totalSubredes;
  final List<SubredIpv6> primeras;
  final List<String> pasos;
  final List<String> avisos;
}

/// Pasa de /[prefijo] a /[nuevoPrefijo] y lista las primeras [maxMostrar]
/// subredes. El total puede ser enorme (p. ej. 65 536 de /48 a /64), por eso
/// no se generan todas.
DivisionIpv6 subnetearIpv6(
  String direccion,
  int prefijo,
  int nuevoPrefijo, {
  int maxMostrar = 16,
}) {
  if (prefijo < 1 || prefijo > 127) {
    throw const Ipv6Exception('El prefijo debe estar entre /1 y /127.');
  }
  if (nuevoPrefijo <= prefijo || nuevoPrefijo > 128) {
    throw const Ipv6Exception(
        'El nuevo prefijo debe ser mayor que el original (y máximo /128).');
  }
  final a = Ipv6.parse(direccion);
  final bitsHostOrig = 128 - prefijo;
  final tamOrig = BigInt.one << bitsHostOrig;
  final red = (a.toBigInt() ~/ tamOrig) * tamOrig;
  final avisos = <String>[];
  if (red != a.toBigInt()) {
    avisos.add('${a.abreviada} no es la dirección de red de /$prefijo; se usó '
        '${Ipv6.fromBigInt(red).abreviada}/$prefijo.');
  }
  final bits = nuevoPrefijo - prefijo;
  final total = BigInt.one << bits;
  final salto = BigInt.one << (128 - nuevoPrefijo);
  final n = total < BigInt.from(maxMostrar) ? total.toInt() : maxMostrar;
  return DivisionIpv6(
    redOriginal: Ipv6.fromBigInt(red),
    prefijoOriginal: prefijo,
    nuevoPrefijo: nuevoPrefijo,
    totalSubredes: total,
    avisos: avisos,
    primeras: <SubredIpv6>[
      for (var i = 0; i < n; i++)
        SubredIpv6(BigInt.from(i + 1),
            Ipv6.fromBigInt(red + salto * BigInt.from(i)), nuevoPrefijo),
    ],
    pasos: <String>[
      '1. Bits para subredes: /$nuevoPrefijo − /$prefijo = $bits bits.',
      '2. Cantidad de subredes: 2^$bits = $total.',
      '3. Cada subred de /$nuevoPrefijo tiene 2^${128 - nuevoPrefijo} '
          'direcciones; IPv6 no tiene broadcast.',
    ],
  );
}
