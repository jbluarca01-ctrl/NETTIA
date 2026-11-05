/// Doctor de redes sobre la running-config (SPEC-004 T2): compara cada
/// router con el diseño de varios routers (enlaces, rutas estáticas u OSPF)
/// y revisa el camino de ida y vuelta entre sedes.
library;

import 'auditor.dart' show Gravedad, Hallazgo;
import 'ip.dart';
import 'lectura_config.dart';
import 'multisede.dart';
import 'plan_red.dart';
import 'tabla_rutas.dart';

/// Con qué enrutamiento se revisa.
enum ModoRutas { estatica, ospf }

/// El modo que corresponde a lo elegido en el Diseñador.
ModoRutas modoDe(Enrutamiento e) => e == Enrutamiento.ospf ? ModoRutas.ospf : ModoRutas.estatica;

/// Una red: dirección base y prefijo.
class _Red {
  const _Red(this.base, this.prefijo);
  final int base;
  final int prefijo;

  /// [otra] cae entera dentro de esta red.
  bool cubre(_Red otra) => prefijo <= otra.prefijo && (otra.base & _mascara(prefijo)) == base;

  @override
  String toString() => '${ipATexto(base)}/$prefijo';
}

int _mascara(int prefijo) => (0xFFFFFFFF << (32 - prefijo)) & 0xFFFFFFFF;

String _mascaraTexto(int prefijo) => ipATexto(_mascara(prefijo));

String _wildcard(int prefijo) => ipATexto(~_mascara(prefijo) & 0xFFFFFFFF);

/// Prefijo de una máscara (`255.255.255.0` → 24); `null` si no es máscara.
int? _prefijoDe(int mascara) {
  final prefijo = 32 - (~mascara & 0xFFFFFFFF).bitLength;
  return _mascara(prefijo) == mascara ? prefijo : null;
}

_Red _deSegmento(SegmentoPlan s) => _Red(ipANumero(s.red)!, s.cidr);

_Red _deEnlace(Enlace e) => _Red(ipANumero(e.red)!, 30);

/// El enlace entre dos routers vecinos (en cualquier orden).
Enlace _enlaceEntre(RedMultisede red, (int, int) vecinos) =>
    red.enlaces.singleWhere((e) => {e.desde, e.desde + 1}.containsAll([vecinos.$1, vecinos.$2]));

/// Lo que el diseño espera del router [i].
class _Router {
  const _Router(this.red, this.i);
  final RedMultisede red;
  final int i;

  String get nombre => 'R${i + 1}';

  /// Vecino de Ri en dirección a la sede [j] (distinta de la suya).
  int vecinoHacia(int j) => i + (j - i).sign;

  /// IP del router [k] en su enlace con el router vecino [otro].
  static String ipEn(RedMultisede red, int k, int otro) {
    final e = _enlaceEntre(red, (k, otro));
    return e.desde == k ? e.ipDesde : e.ipHasta;
  }

  /// Siguiente salto de Ri hacia la sede [j]: la IP del vecino.
  String saltoHacia(int j) => ipEn(red, vecinoHacia(j), i);

  /// Los vecinos de Ri (anterior y siguiente) que existen.
  List<int> get vecinos => [
    for (final v in [i - 1, i + 1])
      if (v >= 0 && v < red.sedes.length) v,
  ];
}

/// Interfaz de [c] con la IP [ip]: (nombre, máscara, líneas).
(String, String, List<String>)? _interfazCon(ConfigLeida c, String ip) {
  for (final MapEntry(key: nombre, value: lineas) in c.interfaces.entries) {
    if (valorDe(lineas, 'ip address ')?.split(' ') case [final dir, final mascara, ...] when dir == ip) {
      return (nombre, mascara, lineas);
    }
  }
  return null;
}

/// Revisa la running-config [real] del router [i] contra [red]; [esperada]
/// es la configuración que generó el Diseñador (para nombrar interfaces).
List<Hallazgo> diagnosticarRouter(ConfigLeida real, ConfigLeida esperada, int i, RedMultisede red, ModoRutas modo) {
  final r = _Router(red, i);
  return [
    for (final v in r.vecinos) ..._revisarEnlace(real, esperada, r, v),
    ...(modo == ModoRutas.ospf ? _revisarOspf(real, r) : _revisarEstaticas(real, r)),
    if (_otroModo(real, r, modo) case final aviso?) aviso,
  ];
}

List<Hallazgo> _revisarEnlace(ConfigLeida real, ConfigLeida esperada, _Router r, int v) {
  final ip = _Router.ipEn(r.red, r.i, v);
  final vecino = 'R${v + 1}';
  final encontrada = _interfazCon(real, ip);
  if (encontrada == null) {
    return [
      Hallazgo(Gravedad.critico, '${r.nombre}: ninguna interfaz tiene $ip (enlace con $vecino).', [
        'interface ${_interfazCon(esperada, ip)!.$1}',
        'ip address $ip ${Enlace.mascara}',
        'no shutdown',
      ]),
    ];
  }
  final (nombre, mascara, lineas) = encontrada;
  return [
    if (mascara != Enlace.mascara)
      Hallazgo(Gravedad.critico, '${r.nombre}: $nombre tiene máscara $mascara; el enlace con $vecino es /30.', [
        'interface $nombre',
        'ip address $ip ${Enlace.mascara}',
      ]),
    if (lineas.contains('shutdown'))
      Hallazgo(Gravedad.critico, '${r.nombre}: $nombre (enlace con $vecino) está apagada.', ['interface $nombre', 'no shutdown']),
  ];
}

// ------------------------------------------------------------ estáticas

final _reRuta = RegExp(r'^ip route (\S+) (\S+) (\S+)$');

/// Las `ip route` de [c]: (red, siguiente salto).
List<(_Red, String)> _rutas(ConfigLeida c) => [
  for (final g in c.globales)
    if (_ruta(g) case final r?) r,
];

(_Red, String)? _ruta(String linea) {
  final m = _reRuta.firstMatch(linea);
  if (m == null) return null;
  final red = _redDe(m[1]!, ipANumero(m[2]!));
  return red == null ? null : (red, m[3]!);
}

/// La red de [ip] con la máscara [mascara] (sus bits de host en 0); `null`
/// si alguna no sirve.
_Red? _redDe(String ip, int? mascara) {
  final base = ipANumero(ip);
  final prefijo = mascara == null ? null : _prefijoDe(mascara);
  return base == null || prefijo == null ? null : _Red(base & _mascara(prefijo), prefijo);
}

/// La ruta más específica de [rutas] que cubre [destino] (con dos iguales,
/// la primera).
(_Red, String)? _mejor(List<(_Red, String)> rutas, _Red destino) {
  (_Red, String)? mejor;
  for (final r in rutas) {
    if (r.$1.cubre(destino) && (mejor == null || r.$1.prefijo > mejor.$1.prefijo)) mejor = r;
  }
  return mejor;
}

String _comandoRuta(_Red red, String salto) => '${ipATexto(red.base)} ${_mascaraTexto(red.prefijo)} $salto';

List<Hallazgo> _revisarEstaticas(ConfigLeida c, _Router r) {
  final rutas = _rutas(c);
  final propios = [for (final s in r.red.sedes[r.i].segmentos) _deSegmento(s)];
  return [
    for (var j = 0; j < r.red.sedes.length; j++)
      if (j != r.i) ..._haciaSede(rutas, r, j, r.nombre),
    for (final (red, salto) in rutas)
      if (red.prefijo > 0 && propios.any(red.cubre))
        Hallazgo(Gravedad.aviso, '${r.nombre}: la ruta $red tapa redes de su propia sede.', ['no ip route ${_comandoRuta(red, salto)}']),
  ];
}

/// Las rutas de [r] hacia cada segmento de la sede [j]: los que no tienen
/// ruta y las rutas que salen por otro vecino.
List<Hallazgo> _haciaSede(List<(_Red, String)> rutas, _Router r, int j, String quien) {
  final salto = r.saltoHacia(j);
  final mejores = [
    for (final s in r.red.sedes[j].segmentos) (_deSegmento(s), _mejor(rutas, _deSegmento(s))),
  ];
  final faltan = [
    for (final (s, m) in mejores)
      if (m == null) s,
  ];
  final malas = {
    for (final (_, m) in mejores)
      if (m != null && m.$2 != salto) m.$1.toString(): m,
  };
  final (resumen, prefijo) = resumenDe(r.red.sedes[j]);
  return [
    if (faltan.isNotEmpty)
      Hallazgo(Gravedad.critico, '$quien: no hay ruta hacia ${faltan.join(', ')} (sede ${j + 1}).', [
        'ip route $resumen ${_mascaraTexto(prefijo)} $salto',
      ]),
    for (final (red, malo) in malas.values)
      Hallazgo(Gravedad.critico, '$quien: la ruta $red sale por $malo; hacia la sede ${j + 1} el vecino es $salto.', [
        'no ip route ${_comandoRuta(red, malo)}',
        'ip route ${_comandoRuta(red, salto)}',
      ]),
  ];
}

// ------------------------------------------------------------------ OSPF

final _reNetwork = RegExp(r'^network (\S+) (\S+) area 0$');

/// Las redes que [c] anuncia en el área 0; `null` sin `router ospf`.
List<_Red>? _redesOspf(ConfigLeida c) => c.ospf == null
    ? null
    : [
        for (final l in c.ospf!)
          if (_network(l) case final r?) r,
      ];

_Red? _network(String linea) {
  final m = _reNetwork.firstMatch(linea);
  if (m == null) return null;
  final wildcard = ipANumero(m[2]!);
  return _redDe(m[1]!, wildcard == null ? null : ~wildcard & 0xFFFFFFFF);
}

/// Redes propias de [r] con lo que son: sus segmentos y sus enlaces.
List<(_Red, String)> _propias(_Router r) => [
  for (final s in r.red.sedes[r.i].segmentos) (_deSegmento(s), s.nombre),
  for (final v in r.vecinos) (_deEnlace(_enlaceEntre(r.red, (r.i, v))), 'enlace con R${v + 1}'),
];

List<Hallazgo> _revisarOspf(ConfigLeida c, _Router r) {
  final redes = _redesOspf(c);
  if (redes == null) {
    return [
      Hallazgo(Gravedad.critico, '${r.nombre}: no tiene router ospf.', [
        'router ospf 1',
        'router-id ${routerId(r.i)}',
        for (final n in r.red.redesOspf(r.i)) 'network $n area 0',
      ]),
    ];
  }
  return [
    for (final (red, que) in _propias(r))
      if (!redes.any((n) => n.cubre(red)))
        Hallazgo(Gravedad.critico, '${r.nombre}: OSPF no anuncia $red ($que).', [
          'router ospf 1',
          'network ${ipATexto(red.base)} ${_wildcard(red.prefijo)} area 0',
        ]),
  ];
}

/// Aviso si el router usa el otro tipo de enrutamiento.
Hallazgo? _otroModo(ConfigLeida c, _Router r, ModoRutas modo) {
  final usa = c.ospf != null ? 'OSPF' : (_rutas(c).isNotEmpty ? 'rutas estáticas' : null);
  final reviso = modo == ModoRutas.ospf ? 'OSPF' : 'rutas estáticas';
  return usa == null || usa == reviso ? null : Hallazgo(Gravedad.aviso, '${r.nombre} usa $usa; estás revisando $reviso.', const []);
}

// ---------------------------------------------------------------- camino

/// Ida y vuelta entre cada par de sedes, con todos los routers en
/// [pegados] (por índice).
List<Hallazgo> diagnosticarCamino(Map<int, ConfigLeida> pegados, RedMultisede red, ModoRutas modo) {
  final faltan = [
    for (var k = 0; k < red.sedes.length; k++)
      if (!pegados.containsKey(k)) 'R${k + 1}',
  ];
  if (faltan.isNotEmpty) {
    return [Hallazgo(Gravedad.aviso, 'Para revisar el camino entre todas las sedes pega también: ${faltan.join(', ')}.', const [])];
  }
  return [
    for (var a = 0; a < red.sedes.length; a++)
      for (var b = 0; b < red.sedes.length; b++)
        if (a != b)
          if (_corte(pegados, red, modo, a, b) case final motivo?)
            Hallazgo(Gravedad.critico, 'Sede ${a + 1} → sede ${b + 1} no llega: $motivo.', const []),
  ];
}

/// Dónde se corta el camino de la sede [a] a la [b]; `null` si llega.
String? _corte(Map<int, ConfigLeida> p, RedMultisede red, ModoRutas modo, int a, int b) {
  final paso = (b - a).sign;
  for (var k = a; k != b; k += paso) {
    final motivo = _paso(p, red, modo, k, k + paso, b);
    if (motivo != null) return motivo;
  }
  return modo == ModoRutas.ospf ? _anunciaSegmentos(p[b]!, red, b) : null;
}

/// Por qué el router [k] no pasa el tráfico hacia la sede [destino] a su
/// vecino [siguiente]; `null` si lo pasa.
String? _paso(Map<int, ConfigLeida> p, RedMultisede red, ModoRutas modo, int k, int siguiente, int destino) =>
    _enlace(p[k]!, red, k, siguiente) ??
    _enlace(p[siguiente]!, red, siguiente, k) ??
    (modo == ModoRutas.ospf ? _ospfEnlace(p, red, k, siguiente) : _estatica(p[k]!, red, k, destino));

/// El enlace del router [k] con [otro] no está o está apagado.
String? _enlace(ConfigLeida c, RedMultisede red, int k, int otro) {
  final encontrada = _interfazCon(c, _Router.ipEn(red, k, otro));
  final vecino = 'R${otro + 1}';
  if (encontrada == null) return 'R${k + 1} no tiene configurado el enlace con $vecino';
  return encontrada.$3.contains('shutdown') ? 'R${k + 1} tiene apagado el enlace con $vecino' : null;
}

/// Por qué el router [k] no manda a la sede [destino] con sus estáticas.
String? _estatica(ConfigLeida c, RedMultisede red, int k, int destino) {
  final rutas = _rutas(c);
  final mejores = [for (final s in red.sedes[destino].segmentos) _mejor(rutas, _deSegmento(s))];
  if (mejores.contains(null)) return 'R${k + 1} no tiene ruta hacia la sede ${destino + 1}';
  final salto = _Router(red, k).saltoHacia(destino);
  return mejores.every((m) => m!.$2 == salto)
      ? null
      : 'R${k + 1} manda a la sede ${destino + 1} por un siguiente salto equivocado';
}

String? _ospfEnlace(Map<int, ConfigLeida> p, RedMultisede red, int k, int siguiente) {
  final enlace = _deEnlace(_enlaceEntre(red, (k, siguiente)));
  for (final (x, y) in [(k, siguiente), (siguiente, k)]) {
    if (!(_redesOspf(p[x]!) ?? const []).any((n) => n.cubre(enlace))) {
      return 'R${x + 1} no anuncia en OSPF el enlace con R${y + 1}';
    }
  }
  return null;
}

String? _anunciaSegmentos(ConfigLeida c, RedMultisede red, int b) {
  final redes = _redesOspf(c) ?? const [];
  final todos = red.sedes[b].segmentos.every((s) => redes.any((n) => n.cubre(_deSegmento(s))));
  return todos ? null : 'R${b + 1} no anuncia en OSPF todos sus segmentos';
}

// ------------------------------------------------------- show ip route

/// Revisa la [tabla] (`show ip route`) del router [i] contra [red]: sus
/// redes conectadas y las rutas hacia las otras sedes (SPEC-004 T3).
List<Hallazgo> diagnosticarTabla(List<EntradaTabla> tabla, int i, RedMultisede red) {
  final r = _Router(red, i);
  final quien = '${r.nombre} (show ip route)';
  final conectadas = {
    for (final e in tabla)
      if (e.codigo == 'C') '${_Red(e.base, e.prefijo)}',
  };
  final rutas = [
    for (final e in tabla)
      if (e.via case final via?) (_Red(e.base, e.prefijo), via),
  ];
  return [
    for (final (propia, que) in _propias(r))
      if (!conectadas.contains('$propia'))
        Hallazgo(Gravedad.critico, '$quien: $propia ($que) no aparece como conectada; revisa la interfaz.', const [
          'show ip interface brief',
        ]),
    for (var j = 0; j < red.sedes.length; j++)
      if (j != i) ..._haciaSede(rutas, r, j, quien),
  ];
}
