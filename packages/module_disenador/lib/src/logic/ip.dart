/// Conversión entre texto IPv4 y número, y rangos de direcciones.
library;

/// Rango cerrado de direcciones IPv4.
class RangoIp {
  const RangoIp(this.desde, this.hasta);
  final int desde;
  final int hasta;

  int get cantidad => hasta - desde + 1;

  bool contiene(int ip) => ip >= desde && ip <= hasta;

  @override
  String toString() => desde == hasta
      ? ipATexto(desde)
      : '${ipATexto(desde)} – ${ipATexto(hasta)}';
}

/// `null` si [texto] no es una IPv4 con 4 octetos de 0 a 255.
int? ipANumero(String texto) {
  final partes = texto.trim().split('.');
  if (partes.length != 4) return null;
  var valor = 0;
  for (final parte in partes) {
    final octeto = int.tryParse(parte);
    if (octeto == null || octeto < 0 || octeto > 255) return null;
    valor = valor * 256 + octeto;
  }
  return valor;
}

String ipATexto(int v) =>
    '${v ~/ 16777216 % 256}.${v ~/ 65536 % 256}.${v ~/ 256 % 256}.${v % 256}';
