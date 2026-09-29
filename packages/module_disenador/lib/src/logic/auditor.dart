/// Auditoría de una running-config contra el plan: cada diferencia sale con
/// su gravedad y los comandos que la corrigen. Solo se revisa lo que aparece
/// en el texto (interfaces con IP, pools DHCP o puertos de switch).
library;

import 'generador.dart';
import 'ip.dart';
import 'plan_red.dart';

enum Gravedad { critico, aviso }

class Hallazgo {
  const Hallazgo(this.gravedad, this.mensaje, this.correccion);
  final Gravedad gravedad;
  final String mensaje;
  final List<String> correccion;
}

/// La running-config dividida en bloques.
class _Config {
  final interfaces = <String, List<String>>{};
  final pools = <String, List<String>>{};
  final globales = <String>[];

  bool _alguna(String prefijo) =>
      interfaces.values.any((ls) => ls.any((l) => l.startsWith(prefijo)));
  bool get tieneIp => _alguna('ip address ');
  bool get tieneSwitch => _alguna('switchport ');
  bool get vacia => !tieneIp && pools.isEmpty && !tieneSwitch;

  /// Abre el bloque de [linea] (interfaz o pool) o la guarda como global.
  List<String>? abrir(String linea) {
    if (linea.startsWith('interface ')) {
      return interfaces[linea.substring(10).trim()] = [];
    }
    if (linea.startsWith('ip dhcp pool ')) {
      return pools[linea.substring(13).trim()] = [];
    }
    globales.add(linea);
    return null;
  }
}

_Config _leer(String texto) {
  final c = _Config();
  List<String>? actual;
  for (final cruda in texto.split('\n')) {
    final linea = cruda.trimRight();
    if (_ignorada(linea)) continue;
    if (linea.startsWith(' ')) {
      actual?.add(linea.trim());
    } else {
      actual = c.abrir(linea.trim());
    }
  }
  return c;
}

bool _ignorada(String linea) => linea.trim().isEmpty || linea.startsWith('!');

String? _valor(List<String> lineas, String prefijo) {
  for (final l in lineas) {
    if (l.startsWith(prefijo)) return l.substring(prefijo.length).trim();
  }
  return null;
}

/// Valor numérico de la primera línea que empieza con [prefijo].
int? _entero(List<String> lineas, String prefijo) {
  final v = _valor(lineas, prefijo);
  return v == null ? null : int.tryParse(v);
}

/// Hallazgos de [runningConfig] frente a [plan]; vacío si todo coincide.
List<Hallazgo> auditarConfig(String runningConfig, PlanRed plan) {
  final c = _leer(runningConfig);
  if (c.vacia) {
    return const [
      Hallazgo(
        Gravedad.aviso,
        'No se reconoció ninguna interfaz con IP, pool DHCP ni puerto de '
        'switch. Pega la salida completa de show running-config.',
        ['show running-config'],
      ),
    ];
  }
  return [
    ..._fisicasApagadas(c),
    for (final s in plan.segmentos) ...[
      if (c.tieneIp) ..._gateway(c, s),
      if (c.pools.isNotEmpty) ..._dhcp(c, s),
    ],
    if (c.tieneSwitch) ..._switch(c, plan),
  ];
}

List<Hallazgo> _fisicasApagadas(_Config c) {
  final fisicas = {
    for (final n in c.interfaces.keys)
      if (n.contains('.')) n.split('.').first,
  };
  return [
    for (final f in fisicas)
      if (c.interfaces[f]?.contains('shutdown') ?? false)
        Hallazgo(
          Gravedad.critico,
          'La interfaz física $f está apagada; sus subinterfaces no pasan '
          'tráfico.',
          ['interface $f', 'no shutdown'],
        ),
  ];
}

List<Hallazgo> _gateway(_Config c, SegmentoPlan s) {
  for (final MapEntry(key: nombre, value: lineas) in c.interfaces.entries) {
    final ip = _valor(lineas, 'ip address ')?.split(' ');
    if (ip != null && ip.first == s.gateway) {
      return _revisarGateway(nombre, lineas, ip, s);
    }
  }
  return [
    Hallazgo(
      Gravedad.critico,
      '${s.nombre}: ninguna interfaz tiene el gateway ${s.gateway}.',
      _interfazFaltante(c, s),
    ),
  ];
}

List<Hallazgo> _revisarGateway(
  String nombre,
  List<String> lineas,
  List<String> ip,
  SegmentoPlan s,
) {
  final mascara = ip.length < 2 ? '?' : ip[1];
  return [
    if (mascara != s.mascara)
      Hallazgo(
        Gravedad.critico,
        '${s.nombre}: el gateway ${s.gateway} tiene máscara $mascara; '
        'el plan dice ${s.mascara}.',
        ['interface $nombre', 'ip address ${s.gateway} ${s.mascara}'],
      ),
    if (nombre.contains('.') &&
        !lineas.contains('encapsulation dot1Q ${s.vlan}'))
      Hallazgo(
        Gravedad.critico,
        '${s.nombre}: $nombre no tiene encapsulation dot1Q ${s.vlan}.',
        ['interface $nombre', 'encapsulation dot1Q ${s.vlan}'],
      ),
    if (lineas.contains('shutdown'))
      Hallazgo(
        Gravedad.critico,
        '${s.nombre}: $nombre está apagada (shutdown).',
        ['interface $nombre', 'no shutdown'],
      ),
  ];
}

List<String> _interfazFaltante(_Config c, SegmentoPlan s) {
  final sub = c.interfaces.keys.where((n) => n.contains('.'));
  final ip = 'ip address ${s.gateway} ${s.mascara}';
  if (sub.isEmpty) return ['interface Vlan${s.vlan}', ip, 'no shutdown'];
  return [
    'interface ${sub.first.split('.').first}.${s.vlan}',
    'encapsulation dot1Q ${s.vlan}',
    ip,
    'no shutdown',
  ];
}

List<Hallazgo> _dhcp(_Config c, SegmentoPlan s) {
  final red = 'network ${s.red} ${s.mascara}';
  final pool = c.pools.entries.where((e) => e.value.contains(red)).firstOrNull;
  if (pool == null) {
    return [
      Hallazgo(
        Gravedad.aviso,
        '${s.nombre}: no hay pool DHCP para ${s.red}/${s.cidr}.',
        [
          'ip dhcp pool ${nombreIos(s.nombre)}',
          red,
          'default-router ${s.gateway}',
        ],
      ),
    ];
  }
  return [
    ..._defaultRouter(pool.key, pool.value, s),
    ..._exclusiones(_excluidas(c), s),
  ];
}

List<Hallazgo> _defaultRouter(
  String pool,
  List<String> lineas,
  SegmentoPlan s,
) {
  final router = _valor(lineas, 'default-router ');
  return [
    if (router != s.gateway)
      Hallazgo(
        Gravedad.critico,
        router == null
            ? '${s.nombre}: el pool DHCP no entrega gateway (default-router).'
            : '${s.nombre}: el pool DHCP entrega el gateway $router; '
                'debe ser ${s.gateway}.',
        ['ip dhcp pool $pool', 'default-router ${s.gateway}'],
      ),
  ];
}

List<Hallazgo> _exclusiones(List<RangoIp> excluidas, SegmentoPlan s) {
  final gw = ipANumero(s.gateway)!;
  final res = s.reservadas;
  return [
    if (!excluidas.any((r) => r.contiene(gw)))
      Hallazgo(
        Gravedad.aviso,
        '${s.nombre}: el gateway ${s.gateway} no está excluido del DHCP; '
        'el pool podría entregárselo a una PC.',
        ['ip dhcp excluded-address ${s.gateway}'],
      ),
    if (res != null && !_cubierto(res, excluidas))
      Hallazgo(
        Gravedad.aviso,
        '${s.nombre}: las IPs reservadas $res no están excluidas del DHCP.',
        [
          'ip dhcp excluded-address ${ipATexto(res.desde)} '
              '${ipATexto(res.hasta)}',
        ],
      ),
  ];
}

List<RangoIp> _excluidas(_Config c) {
  const prefijo = 'ip dhcp excluded-address ';
  return [
    for (final g in c.globales)
      if (g.startsWith(prefijo)) _rango(g.substring(prefijo.length).split(' ')),
  ].nonNulls.toList();
}

RangoIp? _rango(List<String> partes) {
  final desde = ipANumero(partes.first);
  if (desde == null) return null;
  final hasta = partes.length > 1 ? ipANumero(partes[1]) : desde;
  return RangoIp(desde, hasta ?? desde);
}

bool _cubierto(RangoIp r, List<RangoIp> excluidas) {
  for (var ip = r.desde; ip <= r.hasta; ip++) {
    if (!excluidas.any((e) => e.contiene(ip))) return false;
  }
  return true;
}

List<Hallazgo> _switch(_Config c, PlanRed plan) {
  final vlans = {for (final s in plan.segmentos) s.vlan};
  final acceso = <String, int>{
    for (final MapEntry(key: nombre, value: lineas) in c.interfaces.entries)
      if (!_esTroncal(lineas))
        if (_vlanAcceso(lineas) case final v?) nombre: v,
  };
  return [
    for (final MapEntry(key: nombre, value: lineas) in c.interfaces.entries)
      if (_esTroncal(lineas)) ..._troncal(nombre, lineas, plan),
    for (final MapEntry(key: nombre, value: v) in acceso.entries)
      if (!vlans.contains(v))
        Hallazgo(
          Gravedad.aviso,
          '$nombre está en la VLAN $v, que no está en el plan.',
          ['interface $nombre', 'switchport access vlan <${vlans.join('|')}>'],
        ),
    for (final s in plan.segmentos)
      if (!acceso.containsValue(s.vlan))
        Hallazgo(
          Gravedad.aviso,
          '${s.nombre}: ningún puerto de acceso está en la VLAN ${s.vlan}.',
          [
            'interface range FastEthernet0/X - Y',
            'switchport mode access',
            'switchport access vlan ${s.vlan}',
          ],
        ),
  ];
}

bool _esTroncal(List<String> lineas) =>
    lineas.contains('switchport mode trunk');

int? _vlanAcceso(List<String> lineas) =>
    _entero(lineas, 'switchport access vlan ');

List<Hallazgo> _troncal(String nombre, List<String> lineas, PlanRed plan) {
  final nativaPlan = plan.opciones.vlanNativa;
  final nativa = _entero(lineas, 'switchport trunk native vlan ') ?? 1;
  final permitidas = _permitidas(lineas);
  return [
    if (nativa != nativaPlan)
      Hallazgo(
        Gravedad.aviso,
        '$nombre: la VLAN nativa es $nativa; el plan usa $nativaPlan y debe '
        'coincidir en ambos extremos.',
        ['interface $nombre', 'switchport trunk native vlan $nativaPlan'],
      ),
    for (final s in plan.segmentos)
      if (permitidas != null && !permitidas.contains(s.vlan))
        Hallazgo(
          Gravedad.critico,
          '$nombre: el troncal no permite la VLAN ${s.vlan} (${s.nombre}).',
          ['interface $nombre', 'switchport trunk allowed vlan add ${s.vlan}'],
        ),
  ];
}

/// VLAN permitidas en el troncal; `null` si no hay lista (se permiten todas).
Set<int>? _permitidas(List<String> lineas) {
  const base = 'switchport trunk allowed vlan ';
  Set<int>? resultado;
  for (final l in lineas.where((l) => l.startsWith(base))) {
    final lista = l.substring(base.length).trim();
    if (lista == 'all') return null;
    (resultado ??= <int>{}).addAll(_listaVlans(lista));
  }
  return resultado;
}

Set<int> _listaVlans(String lista) {
  final limpia = lista.startsWith('add ') ? lista.substring(4) : lista;
  return {for (final parte in limpia.split(',')) ..._rangoVlans(parte)};
}

List<int> _rangoVlans(String parte) {
  final r = parte.split('-').map(int.tryParse).toList();
  final desde = r.first;
  final hasta = r.length > 1 ? r[1] : desde;
  if (desde == null || hasta == null) return const [];
  return [for (var v = desde; v <= hasta; v++) v];
}
