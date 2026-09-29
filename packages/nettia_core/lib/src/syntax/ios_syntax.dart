import 'package:flutter/material.dart';

/// Paleta "One Dark Pro" para los bloques de código de Nettia.
abstract final class OneDark {
  static const Color fg = Color(0xFFABB2BF);
  static const Color comment = Color(0xFF5C6370);
  static const Color keyword = Color(0xFFC678DD); // púrpura: configuración
  static const Color command = Color(0xFF61AFEF); // azul: comandos de exec
  static const Color number = Color(0xFFD19A66); // naranja: números, IPs
  static const Color iface = Color(0xFF56B6C2); // cian: interfaces
  static const Color string = Color(0xFF98C379); // verde
  static const Color placeholder = Color(0xFFE5C07B); // amarillo: <valores>
  static const Color operator = Color(0xFFE06C75); // rojo: "no"
}

/// Colores de sangría al estilo "indent-rainbow": cada nivel de sangría se
/// pinta con un fondo translúcido distinto.
const List<Color> kIndentRainbow = <Color>[
  Color(0x24FFFF40),
  Color(0x247FFF7F),
  Color(0x24FF7FFF),
  Color(0x244FECEC),
];

const Set<String> _comandosExec = <String>{
  'show', 'ping', 'traceroute', 'copy', 'write', 'debug', 'clear', 'reload',
  'enable', 'disable', 'configure', 'conf', 'exit', 'end', 'erase', 'terminal',
  'telnet', 'ssh', 'ipconfig', 'arp', 'tracert', 'netstat', 'nslookup',
};

const Set<String> _palabrasConfig = <String>{
  'interface', 'vlan', 'switchport', 'mode', 'access', 'trunk', 'allowed',
  'add', 'remove', 'encapsulation', 'dot1q', 'ip', 'address', 'route',
  'shutdown', 'hostname', 'name', 'range', 'native', 'description',
  'default-gateway', 'ospf', 'router', 'network', 'line', 'password',
  'secret', 'service', 'banner', 'spanning-tree', 'channel-group', 'duplex',
  'speed', 'brief', 'running-config', 'startup-config', 'interfaces',
  'domain-name', 'crypto', 'key', 'generate', 'rsa', 'transport', 'input',
  'login', 'local', 'username', 'privilege', 'exec-timeout', 'logging',
  'synchronous', 'dhcp', 'pool', 'excluded-address', 'default-router',
  'dns-server', 'access-list', 'permit', 'deny', 'any', 'host', 'nat',
  'inside', 'outside', 'source', 'overload', 'trunking', 'portfast',
};

final RegExp _token = RegExp(
  r'(!.*$)' // 1 comentario
  r'|("[^"]*")' // 2 cadena
  r'|(<[^>\n]+>)' // 3 placeholder
  r'|(\b\d{1,3}(?:\.\d{1,3}){3}(?:/\d{1,2})?\b)' // 4 IP
  r'|(\b(?:fa|gi|te|eth|fastethernet|gigabitethernet|tengigabitethernet|'
  r'loopback|port-channel|po)\s?\d+(?:/\d+)*(?:\.\d+)?)' // 5 interfaz
  r'|(\b\d+(?:-\d+)?\b)' // 6 número / rango
  r'|([A-Za-z][\w-]*)', // 7 palabra
  caseSensitive: false,
);

typedef _Colorear = TextSpan Function(String t, Color c, {FontStyle? estilo});

/// Sangría inicial de [linea] pintada nivel a nivel (estilo indent-rainbow).
/// Devuelve los spans de sangría y el índice donde termina.
(List<InlineSpan>, int) _spansSangria(String linea, TextStyle base) {
  final spans = <InlineSpan>[];
  final sangria = RegExp(r'^[ \t]+').firstMatch(linea);
  if (sangria == null) return (spans, 0);

  final ws = sangria.group(0)!.replaceAll('\t', '    ');
  var nivel = 0;
  for (var i = 0; i < ws.length; i += 2) {
    final trozo = ws.substring(i, i + 2 > ws.length ? ws.length : i + 2);
    spans.add(TextSpan(
      text: trozo,
      style: base.copyWith(
        backgroundColor: kIndentRainbow[nivel % kIndentRainbow.length],
      ),
    ));
    nivel++;
  }
  return (spans, sangria.end);
}

/// Palabra suelta (grupo 7 de [_token]): comando exec, palabra de
/// configuración, el operador "no" o texto plano.
TextSpan _spanPalabra(String t, _Colorear color, {required bool primerPalabra}) {
  final w = t.toLowerCase();
  if (w == 'no') return color(t, OneDark.operator);
  if (_comandosExec.contains(w) && primerPalabra) return color(t, OneDark.command);
  if (_palabrasConfig.contains(w) || _comandosExec.contains(w)) {
    return color(t, OneDark.keyword);
  }
  return color(t, OneDark.fg);
}

/// Color y estilo de cada grupo "simple" de [_token] (todos menos la palabra
/// suelta, grupo 7): comentario, cadena, placeholder, IP, interfaz, número.
const _estiloPorGrupo = <int, (Color, FontStyle?)>{
  1: (OneDark.comment, FontStyle.italic),
  2: (OneDark.string, null),
  3: (OneDark.placeholder, FontStyle.italic),
  4: (OneDark.number, null),
  5: (OneDark.iface, null),
  6: (OneDark.number, null),
};

/// Un token ya identificado por [_token]: comentario, cadena, placeholder,
/// IP, interfaz, número/rango o palabra suelta.
TextSpan _spanToken(RegExpMatch m, _Colorear color, {required bool primerPalabra}) {
  final t = m.group(0)!;
  for (final entry in _estiloPorGrupo.entries) {
    if (m.group(entry.key) != null) {
      final (c, estilo) = entry.value;
      return color(t, c, estilo: estilo);
    }
  }
  return _spanPalabra(t, color, primerPalabra: primerPalabra);
}

/// Resalta una línea de comandos (Cisco IOS / consola) con la paleta One Dark.
/// Solo colorea; no altera el texto.
List<InlineSpan> resaltarIos(String linea, TextStyle base) {
  TextSpan color(String t, Color c, {FontStyle? estilo}) => TextSpan(
        text: t,
        style: base.copyWith(color: c, fontStyle: estilo),
      );

  final (spans, inicio) = _spansSangria(linea, base);
  var desde = inicio;

  var primerPalabra = true;
  for (final m in _token.allMatches(linea, desde)) {
    if (m.start > desde) {
      spans.add(color(linea.substring(desde, m.start), OneDark.fg));
    }
    spans.add(_spanToken(m, color, primerPalabra: primerPalabra));
    if (m.group(7) != null) primerPalabra = false;
    desde = m.end;
  }
  if (desde < linea.length) {
    spans.add(color(linea.substring(desde), OneDark.fg));
  }
  return spans;
}
