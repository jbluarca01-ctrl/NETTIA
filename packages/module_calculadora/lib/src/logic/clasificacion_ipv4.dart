/// Clasificación de una dirección IPv4 (sin Flutter): clase A–E por el primer
/// octeto y tipo pública, privada (RFC 1918) o especial, con una explicación
/// lista para mostrar, como se pide en la Clase 14.
library;

/// Clase de la dirección según su primer octeto.
enum ClaseIpv4 {
  a('A', '1–126', '/8 (255.0.0.0)'),
  b('B', '128–191', '/16 (255.255.0.0)'),
  c('C', '192–223', '/24 (255.255.255.0)'),
  d('D', '224–239', null),
  e('E', '240–255', null);

  const ClaseIpv4(this.letra, this.rango, this.mascaraPorDefecto);
  final String letra;

  /// Rango del primer octeto que se enseña para la clase.
  final String rango;

  /// `null` en D y E: no tienen máscara por defecto.
  final String? mascaraPorDefecto;
}

/// Tipo de la dirección. Las especiales llevan su descripción fija.
enum TipoIpv4 {
  publica('Pública', ''),
  privada('Privada (RFC 1918)', ''),
  loopback(
    'Loopback',
    'Loopback: tráfico hacia el propio equipo (prueba la pila TCP/IP). '
        'No se asigna a un host.',
  ),
  apipa(
    'APIPA (link-local)',
    'APIPA: el equipo se la autoasignó porque falló el DHCP. '
        'Sin conectividad útil.',
  ),
  multicast(
    'Multicast',
    'Multicast: un origen hacia un grupo de destinos. No se asigna a un host.',
  ),
  experimental(
    'Experimental (reservada)',
    'Experimental: reservada, no se asigna a un host.',
  ),
  broadcastLimitado(
    'Broadcast limitado',
    'Broadcast limitado: a todos los equipos del segmento local.',
  ),
  noEspecificada(
    'No especificada',
    'No especificada: origen durante DHCP y ruta por defecto.',
  ),
  reservada(
    'Reservada (red 0)',
    'Reservada: la red 0 significa "esta red"; no se asigna a un host.',
  );

  const TipoIpv4(this.texto, this.descripcion);
  final String texto;
  final String descripcion;

  /// Solo las públicas y las privadas pueden ir en un host.
  bool get asignable => this == publica || this == privada;
}

/// Resultado de clasificar una dirección.
class ClasificacionIpv4 {
  const ClasificacionIpv4(this.clase, this.tipo, this.explicacion);
  final ClaseIpv4 clase;
  final TipoIpv4 tipo;
  final String explicacion;

  /// Ej.: "A · /8 (255.0.0.0)" o "D · sin máscara".
  String get claseTexto =>
      '${clase.letra} · ${clase.mascaraPorDefecto ?? 'sin máscara'}';
}

final _formato = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

/// Clasifica [ip] (decimal punteado, sin espacios); `null` si no es válida.
ClasificacionIpv4? clasificarIpv4(String ip) {
  final m = _formato.firstMatch(ip);
  if (m == null) return null;
  final o = [for (var i = 1; i <= 4; i++) int.parse(m[i]!)];
  if (o.any((x) => x > 255)) return null;
  final clase = _clase(o[0]);
  final tipo = _tipoEspecial(o) ?? _tipoComun(o[0], o[1]);
  return ClasificacionIpv4(
    clase,
    tipo,
    '${_explicarClase(clase, o[0])} ${_explicarTipo(tipo, o[0], o[1])}',
  );
}

ClaseIpv4 _clase(int a) {
  if (a < 128) return ClaseIpv4.a;
  if (a < 192) return ClaseIpv4.b;
  if (a < 224) return ClaseIpv4.c;
  if (a < 240) return ClaseIpv4.d;
  return ClaseIpv4.e;
}

TipoIpv4? _tipoEspecial(List<int> o) {
  if (o.every((x) => x == 255)) return TipoIpv4.broadcastLimitado;
  if (o.every((x) => x == 0)) return TipoIpv4.noEspecificada;
  return switch (o[0]) {
    0 => TipoIpv4.reservada,
    127 => TipoIpv4.loopback,
    169 when o[1] == 254 => TipoIpv4.apipa,
    >= 240 => TipoIpv4.experimental,
    >= 224 => TipoIpv4.multicast,
    _ => null,
  };
}

TipoIpv4 _tipoComun(int a, int b) =>
    _bloquePrivado(a, b) == null ? TipoIpv4.publica : TipoIpv4.privada;

/// Bloques RFC 1918: (primer octeto, segundo desde, segundo hasta, texto).
const _bloquesPrivados = <(int, int, int, String)>[
  (10, 0, 255, '10.0.0.0/8'),
  (172, 16, 31, '172.16.0.0/12 (172.16 a 172.31)'),
  (192, 168, 168, '192.168.0.0/16'),
];

/// Bloque RFC 1918 al que pertenece la dirección, o `null` si no es privada.
String? _bloquePrivado(int a, int b) {
  for (final (primero, desde, hasta, texto) in _bloquesPrivados) {
    if (a == primero && b >= desde && b <= hasta) return texto;
  }
  return null;
}

String _explicarClase(ClaseIpv4 clase, int a) {
  final rango = (a == 0 || a == 127)
      ? 'está reservado (los hosts de clase A van de 1 a 126)'
      : 'está en ${clase.rango}';
  final mascara = clase.mascaraPorDefecto;
  final cierre = mascara == null
      ? 'No tiene máscara por defecto.'
      : 'Máscara por defecto $mascara.';
  return 'Clase ${clase.letra}: el primer octeto ($a) $rango. $cierre';
}

String _explicarTipo(TipoIpv4 tipo, int a, int b) => switch (tipo) {
  TipoIpv4.privada =>
    'Privada: bloque RFC 1918 ${_bloquePrivado(a, b)}. Se reutiliza en '
        'otras redes y necesita NAT para salir a Internet.',
  TipoIpv4.publica =>
    'Pública: única y enrutable en Internet.'
        '${a == 172 ? ' Ojo: el bloque privado de clase B va de 172.16 a '
                  '172.31.' : ''}',
  _ => tipo.descripcion,
};
