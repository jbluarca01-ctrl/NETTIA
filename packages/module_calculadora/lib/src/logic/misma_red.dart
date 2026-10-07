/// ¿Dos IPv4 están en la misma red con un prefijo dado? (Clase 16: el
/// gateway debe estar en la subred del host).
library;

import 'dart:math';

import 'clasificacion_ipv4.dart';

String _red(String ip, int cidr) {
  final v = ip.split('.').map(int.parse).fold(0, (a, o) => a * 256 + o);
  final r = v - v % pow(2, 32 - cidr).toInt();
  return '${r ~/ 16777216 % 256}.${r ~/ 65536 % 256}.${r ~/ 256 % 256}.${r % 256}';
}

/// "Sí: [otra] está en red/n" o "No: [otra] está en red/n"; `null` si [otra]
/// no es una IPv4 válida. [ip] debe ser válida.
String? compararRed(String ip, String otra, int cidr) {
  if (clasificarIpv4(otra) == null) return null;
  final suya = _red(otra, cidr);
  final respuesta = suya == _red(ip, cidr) ? 'Sí' : 'No';
  return '$respuesta: $otra está en $suya/$cidr';
}
