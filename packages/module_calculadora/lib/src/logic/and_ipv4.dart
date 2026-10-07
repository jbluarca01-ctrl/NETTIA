/// El octeto donde la máscara corta la porción de host y su AND, como se
/// resuelve a mano en clase ("45 AND 224 = 32"). Sin operadores de bits.
library;

/// Octeto "interesante" de una IP para un prefijo dado.
class OctetoInteresante {
  const OctetoInteresante(this.posicion, this.ip, this.mascara);

  /// 1 a 4, de izquierda a derecha.
  final int posicion;
  final int ip;
  final int mascara;

  /// Salto entre subredes en ese octeto: 256 − máscara.
  int get bloque => 256 - mascara;

  /// IP AND máscara en ese octeto (la máscara es contigua: basta con bajar
  /// al múltiplo del bloque).
  int get and => ip - ip % bloque;

  String get operacion => '$ip AND $mascara = $and';
}

/// Octeto interesante de [octetos] con /[cidr], o `null` si la máscara corta
/// justo entre octetos (/8, /16, /24…).
OctetoInteresante? octetoInteresante(List<int> octetos, int cidr) {
  if (cidr % 8 == 0) return null;
  final i = cidr ~/ 8;
  var bloque = 1;
  for (var b = 0; b < 8 - cidr % 8; b++) {
    bloque *= 2;
  }
  return OctetoInteresante(i + 1, octetos[i], 256 - bloque);
}
