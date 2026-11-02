/// Conversiones de bolsillo (sin Flutter): máscara ↔ wildcard ↔ prefijo,
/// binario ↔ decimal ↔ hexadecimal y sumarización de rutas. Solo aritmética
/// entera con `+`, `-`, `~/` y `%` (sin operadores de bits).
library;

import 'dart:math';

/// Error de validación con mensaje listo para mostrar.
class ConversionException implements Exception {
  const ConversionException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

int _pow2(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 2;
  }
  return v;
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

/// Prefijo (0 a 32) de una máscara contigua, o null si no lo es.
int? prefijoDeMascara(String mascara) {
  final m = _parseIp(mascara);
  if (m == null) return null;
  for (var p = 0; p <= 32; p++) {
    if (4294967296 - _pow2(32 - p) == m) return p;
  }
  return null;
}

/// Máscara decimal punteada de un prefijo (0 a 32).
String mascaraDePrefijo(int prefijo) {
  if (prefijo < 0 || prefijo > 32) {
    throw const ConversionException('El prefijo debe estar entre /0 y /32.');
  }
  return _ipTexto(4294967296 - _pow2(32 - prefijo));
}

/// Wildcard (inverso de la máscara) de un prefijo, p. ej. /24 → 0.0.0.255.
String wildcardDePrefijo(int prefijo) {
  if (prefijo < 0 || prefijo > 32) {
    throw const ConversionException('El prefijo debe estar entre /0 y /32.');
  }
  return _ipTexto(_pow2(32 - prefijo) - 1);
}

/// Resultado de convertir una máscara o wildcard en las otras formas.
class ConversionMascara {
  const ConversionMascara(this.prefijo, this.mascara, this.wildcard, this.hosts);
  final int prefijo;
  final String mascara;
  final String wildcard;

  /// Hosts útiles: dirección de red y broadcast descontadas; en /31 (enlace
  /// punto a punto, RFC 3021) se usan las 2; /32 no tiene hosts.
  final int hosts;
}

/// Acepta "/24", "24", una máscara ("255.255.255.0") o un wildcard
/// ("0.0.0.255") y devuelve las otras formas.
ConversionMascara convertirMascara(String entrada) {
  final t = entrada.trim();
  int? prefijo;
  if (RegExp(r'^/?\d{1,2}$').hasMatch(t)) {
    prefijo = int.parse(t.replaceAll('/', ''));
  } else if (t.contains('.')) {
    prefijo = prefijoDeMascara(t);
    if (prefijo == null) {
      // ¿Es un wildcard? Su inverso debe ser una máscara contigua.
      final v = _parseIp(t);
      if (v != null) prefijo = prefijoDeMascara(_ipTexto(4294967295 - v));
    }
  }
  if (prefijo == null || prefijo < 0 || prefijo > 32) {
    throw const ConversionException(
        'Escribe un prefijo (/24), una máscara contigua (255.255.255.0) o un '
        'wildcard (0.0.0.255).');
  }
  final tam = _pow2(32 - prefijo);
  return ConversionMascara(
    prefijo,
    mascaraDePrefijo(prefijo),
    wildcardDePrefijo(prefijo),
    tam >= 4 ? tam - 2 : (tam == 2 ? 2 : 0),
  );
}

/// Un número visto en varias bases.
class ConversionNumero {
  const ConversionNumero(this.decimal, this.binario, this.hexadecimal);
  final int decimal;
  final String binario;
  final String hexadecimal;
}

/// Convierte entre decimal, binario y hexadecimal. [base] es 10, 2 o 16.
ConversionNumero convertirNumero(String texto, int base) {
  var t = texto.trim().toLowerCase().replaceAll(RegExp(r'[\s_.]'), '');
  if (base == 16 && t.startsWith('0x')) t = t.substring(2);
  if (base == 2 && t.startsWith('0b')) t = t.substring(2);
  final v = t.isEmpty ? null : int.tryParse(t, radix: base);
  if (v == null || v < 0) {
    throw ConversionException(
        'Número inválido para base $base (${base == 2 ? 'solo 0 y 1' : base == 16 ? '0-9 y a-f' : 'solo dígitos'}).');
  }
  if (v > 4294967295) {
    throw const ConversionException('Máximo 32 bits (4 294 967 295).');
  }
  final bin = v.toRadixString(2);
  // En bloques de 8 bits (como un octeto de IPv4) para leerlo mejor.
  final relleno = bin.padLeft(((bin.length + 7) ~/ 8) * 8, '0');
  final bloques = <String>[
    for (var i = 0; i < relleno.length; i += 8) relleno.substring(i, i + 8),
  ];
  return ConversionNumero(v, bloques.join(' '), v.toRadixString(16).toUpperCase());
}

/// Resultado de sumarizar redes.
class ResultadoSumarizacion {
  const ResultadoSumarizacion({
    required this.red,
    required this.prefijo,
    required this.mascara,
    required this.exacta,
    required this.direccionesSobrantes,
    required this.pasos,
  });

  final String red;
  final int prefijo;
  final String mascara;

  /// La ruta resumen cubre **exactamente** las redes dadas, sin direcciones de más.
  final bool exacta;
  final int direccionesSobrantes;
  final List<String> pasos;
}


/// Valor entero de una IPv4 "a.b.c.d", o null si no es válida.
int? ipDesdeTexto(String s) => _parseIp(s);

/// IPv4 "a.b.c.d" del valor entero [v].
String ipATexto(int v) => _ipTexto(v);

/// Prefijo de 0 a 32 escrito en [s], o null.
int? _prefijoValido(String s) {
  final n = int.tryParse(s);
  return n != null && n >= 0 && n <= 32 ? n : null;
}

/// IP y prefijo de "a.b.c.d/n"; lanza [ConversionException] si no lo es.
(int, int) _ipYPrefijo(String red) {
  final p = red.split('/');
  final ip = _parseIp(p.first);
  final pre = p.length == 2 ? _prefijoValido(p[1]) : null;
  if (ip == null || pre == null) {
    throw ConversionException('Red inválida: "$red" (usa a.b.c.d/n).');
  }
  return (ip, pre);
}

/// Primera y última dirección de la red "a.b.c.d/n"; la IP debe ser la
/// dirección de red.
(int, int) rangoDeRed(String red) {
  final t = red.trim();
  final (ip, pre) = _ipYPrefijo(t);
  final tam = _pow2(32 - pre);
  final ini = ip - ip % tam;
  if (ini != ip) {
    throw ConversionException(
        '"$t" no es una dirección de red (¿quisiste ${_ipTexto(ini)}/$pre?).');
  }
  return (ini, ini + tam - 1);
}

/// Prefijo más largo en el que [ini] y [fin] comparten la red (en /0 siempre
/// la comparten: ambos son menores que 2^32).
int _prefijoComun((int, int) extremos) {
  final (ini, fin) = extremos;
  var n = 32;
  while (ini ~/ _pow2(32 - n) != fin ~/ _pow2(32 - n)) {
    n--;
  }
  return n;
}

/// [rangos] ordenados por inicio: alguno empieza antes de que termine el
/// anterior.
bool _solapan(List<(int, int)> rangos) {
  for (var i = 1; i < rangos.length; i++) {
    if (rangos[i].$1 <= rangos[i - 1].$2) return true;
  }
  return false;
}

/// Datos de una sumarización ya calculada, para escribir sus pasos.
class _Sumario {
  _Sumario(List<(int, int)> rangos)
      : minIni = rangos.first.$1,
        maxFin = rangos.map((r) => r.$2).reduce(max),
        total = rangos.fold(0, (s, r) => s + r.$2 - r.$1 + 1),
        solapan = _solapan(rangos) {
    n = _prefijoComun((minIni, maxFin));
  }

  final int minIni;
  final int maxFin;
  final int total;
  final bool solapan;
  late final int n;

  int get bloque => _pow2(32 - n);
  int get red => minIni - minIni % bloque;
  bool get exacta => !solapan && total == bloque;

  List<String> get pasos => <String>[
        '1. Rango que cubren las redes: ${_ipTexto(minIni)} a ${_ipTexto(maxFin)}.',
        '2. Se busca el prefijo más largo en el que la primera y la última '
            'dirección comparten la red: /$n.',
        '3. La ruta resumen es ${_ipTexto(red)}/$n (máscara ${mascaraDePrefijo(n)}), '
            'que abarca $bloque direcciones.',
        _cierre,
      ];

  String get _cierre {
    if (solapan) return '4. Aviso: algunas redes se solapan entre sí.';
    if (exacta) {
      return '4. Las redes suman exactamente $bloque direcciones: el resumen es exacto.';
    }
    return '4. Las redes suman $total y el resumen abarca $bloque: sobran '
        '${bloque - total} direcciones que no pertenecen a ninguna de ellas.';
  }
}

/// Sumariza una lista de redes IPv4 en formato "a.b.c.d/n" en la ruta resumen
/// más específica que las cubre a todas.
ResultadoSumarizacion sumarizarRedes(List<String> redes) {
  if (redes.length < 2) {
    throw const ConversionException('Escribe al menos 2 redes para sumarizar.');
  }
  final s = _Sumario(
    redes.map(rangoDeRed).toList()..sort((a, b) => a.$1.compareTo(b.$1)),
  );
  return ResultadoSumarizacion(
    red: _ipTexto(s.red),
    prefijo: s.n,
    mascara: mascaraDePrefijo(s.n),
    exacta: s.exacta,
    direccionesSobrantes: s.solapan ? 0 : s.bloque - s.total,
    pasos: s.pasos,
  );
}
