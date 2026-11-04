/// Aplicar a una running-config los comandos IOS de corrección que escribe
/// el estudiante en "Repara la red" nivel 2 (SPEC-002 T1), con los modos de
/// IOS: global, interfaz y pool DHCP. Solo se aceptan los comandos que
/// arreglan las fallas del ejercicio; el resto se informa sin aplicarse.
library;

import 'generador.dart';

/// La configuración con los comandos aplicados y los que no se reconocieron.
class ResultadoAplicar {
  const ResultadoAplicar(this.config, this.noReconocidos);
  final ConfigEquipo config;

  /// En orden, sin espacios de más.
  final List<String> noReconocidos;
}

/// Aplica cada línea de [comandos] a una copia de [config].
ResultadoAplicar aplicarComandos(ConfigEquipo config, String comandos) {
  final e = _Edicion([...config.lineas]);
  for (final cruda in comandos.split('\n')) {
    final c = cruda.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (c.isNotEmpty && !c.startsWith('!') && !e.aplicar(c)) e.noReconocidos.add(c);
  }
  return ResultadoAplicar(ConfigEquipo(config.hostname, e.lineas), e.noReconocidos);
}

const _sinCambios = {'enable', 'configure terminal', 'conf t', 'write memory', 'wr'};

enum _Modo { interfaz, pool }

/// Un comando de submodo: [prefijo] seguido de [argumentos] (una expresión
/// regular). Reemplaza las líneas del bloque que empiezan con [claves].
class _Regla {
  _Regla(this.modo, this.prefijo, {String argumentos = '', List<String>? claves, this.minusculas = false})
    : claves = claves ?? [prefijo],
      _patron = RegExp('^${RegExp.escape(prefijo)}($argumentos)\$', caseSensitive: false);

  final _Modo modo;
  final String prefijo;
  final List<String> claves;
  final bool minusculas;
  final RegExp _patron;

  /// La línea canónica de [c], o `null` si [c] no es este comando.
  String? linea(String c) {
    final a = _patron.firstMatch(c)?[1];
    if (a == null) return null;
    return '$prefijo${minusculas ? a.toLowerCase() : a}';
  }
}

const _apagado = ['shutdown', 'no shutdown'];
const _permitidas = 'switchport trunk allowed vlan ';

final _reglas = [
  _Regla(_Modo.interfaz, 'shutdown', claves: _apagado),
  _Regla(_Modo.interfaz, 'no shutdown', claves: _apagado),
  _Regla(_Modo.interfaz, 'ip address ', argumentos: r'\S+ \S+'),
  _Regla(_Modo.interfaz, 'encapsulation dot1Q ', argumentos: r'\d+(?: native)?', minusculas: true),
  _Regla(_Modo.interfaz, 'description ', argumentos: '.+'),
  _Regla(_Modo.interfaz, 'switchport mode ', argumentos: 'access|trunk', minusculas: true),
  _Regla(_Modo.interfaz, 'switchport access vlan ', argumentos: r'\d+'),
  _Regla(_Modo.interfaz, 'switchport trunk native vlan ', argumentos: r'\d+'),
  _Regla(_Modo.interfaz, _permitidas, argumentos: r'[\d,-]+'),
  _Regla(_Modo.pool, 'network ', argumentos: r'\S+ \S+'),
  _Regla(_Modo.pool, 'default-router ', argumentos: r'\S+'),
  _Regla(_Modo.pool, 'dns-server ', argumentos: '.+'),
  _Regla(_Modo.pool, 'domain-name ', argumentos: '.+'),
];

final _interfaz = RegExp(r'^(?:interface|int) (.+)$', caseSensitive: false);
final _pool = RegExp(r'^ip dhcp pool (\S+)$', caseSensitive: false);
final _exclusion = RegExp(r'^ip dhcp excluded-address (\S+(?: \S+)?)$', caseSensitive: false);
final _ampliacion = RegExp(r'^switchport trunk allowed vlan add ([\d,-]+)$', caseSensitive: false);
final _partes = RegExp(r'^(range )?([a-z]+)\s*(\S.*)$', caseSensitive: false);

/// (`range `, tipo, número sin espacios) de un nombre de interfaz, en
/// minúsculas; `null` si no empieza con un tipo.
(String?, String, String)? _clave(String nombre) {
  final m = _partes.firstMatch(nombre);
  if (m == null) return null;
  return (m[1]?.toLowerCase(), m[2]!.toLowerCase(), m[3]!.replaceAll(' ', ''));
}

/// [escrito] y [existente] son la misma interfaz ([escrito], abreviado).
bool _mismaInterfaz((String?, String, String) escrito, String existente) {
  final e = _clave(existente);
  return e != null && e.$1 == escrito.$1 && e.$2.startsWith(escrito.$2) && e.$3 == escrito.$3;
}

/// La configuración que se va editando y el submodo actual.
class _Edicion {
  _Edicion(this.lineas);

  final List<String> lineas;
  final noReconocidos = <String>[];
  String? _bloque;
  _Modo? _modo;

  /// Aplica [c]; `false` si no es un comando reconocido en este modo.
  bool aplicar(String c) {
    final minusculas = c.toLowerCase();
    if (_sinCambios.contains(minusculas)) return true;
    if (minusculas == 'exit' || minusculas == 'end') return _salir();
    return _abrir(c) || _excluir(c) || _enBloque(c);
  }

  bool _salir() {
    _bloque = null;
    _modo = null;
    return true;
  }

  bool _abrir(String c) {
    if (_interfaz.firstMatch(c) case final m?) return _entrar('interface ${_resolverInterfaz(m[1]!)}', _Modo.interfaz);
    if (_pool.firstMatch(c) case final m?) return _entrar('ip dhcp pool ${_resolverPool(m[1]!)}', _Modo.pool);
    return false;
  }

  /// Entra al bloque [encabezado]; si no existe, lo crea antes de `end`.
  bool _entrar(String encabezado, _Modo modo) {
    if (!lineas.contains(encabezado)) lineas.insertAll(_antesDeEnd(), [encabezado, 'exit']);
    _bloque = encabezado;
    _modo = modo;
    return true;
  }

  int _antesDeEnd() {
    final i = lineas.indexOf('end');
    return i < 0 ? lineas.length : i;
  }

  Iterable<String> _nombres(String prefijo) => [
    for (final l in lineas)
      if (l.startsWith(prefijo)) l.substring(prefijo.length),
  ];

  String _resolverInterfaz(String escrito) {
    final buscado = _clave(escrito);
    if (buscado == null) return escrito;
    return _nombres('interface ').firstWhere((n) => _mismaInterfaz(buscado, n), orElse: () => escrito);
  }

  String _resolverPool(String escrito) => _nombres(
    'ip dhcp pool ',
  ).firstWhere((n) => n.toLowerCase() == escrito.toLowerCase(), orElse: () => escrito);

  /// `ip dhcp excluded-address` (global: también sale del submodo).
  bool _excluir(String c) {
    final m = _exclusion.firstMatch(c);
    if (m == null) return false;
    final linea = 'ip dhcp excluded-address ${m[1]}';
    if (!lineas.contains(linea)) lineas.insert(_antesDeEnd(), linea);
    return _salir();
  }

  bool _enBloque(String c) {
    final bloque = _bloque;
    if (bloque == null) return false;
    if (_modo == _Modo.interfaz && _ampliar(bloque, c)) return true;
    for (final r in _reglas.where((r) => r.modo == _modo)) {
      if (r.linea(c) case final linea?) {
        _poner(bloque, linea, r.claves);
        return true;
      }
    }
    return false;
  }

  /// `switchport trunk allowed vlan add`: sin lista previa ya se permiten
  /// todas, así que no cambia nada.
  bool _ampliar(String bloque, String c) {
    final m = _ampliacion.firstMatch(c);
    if (m == null) return false;
    final actual = _sublineas(bloque).where((l) => l.startsWith(_permitidas)).firstOrNull;
    if (actual != null) {
      final vlans = {...actual.substring(_permitidas.length).split(','), ...m[1]!.split(',')};
      _poner(bloque, '$_permitidas${vlans.join(',')}', const [_permitidas]);
    }
    return true;
  }

  /// Las líneas del bloque [bloque], sin la sangría.
  List<String> _sublineas(String bloque) => [for (final l in _cuerpo(bloque).$2) l.trim()];

  /// Quita del bloque las líneas que empiezan con [claves] y agrega [linea]
  /// al final del bloque.
  void _poner(String bloque, String linea, List<String> claves) {
    final ((inicio, fin), cuerpo) = _cuerpo(bloque);
    lineas.replaceRange(inicio, fin, [
      for (final l in cuerpo)
        if (!claves.any(l.trim().startsWith)) l,
      ' $linea',
    ]);
  }

  /// El rango de las sublíneas del bloque (sin el encabezado) y esas líneas.
  ((int, int), List<String>) _cuerpo(String bloque) {
    final (inicio, fin) = _rango(bloque);
    return ((inicio + 1, fin), lineas.sublist(inicio + 1, fin));
  }

  /// Índice del encabezado y del primer renglón que ya no es del bloque.
  (int, int) _rango(String bloque) {
    final inicio = lineas.indexOf(bloque);
    var fin = inicio + 1;
    while (fin < lineas.length && lineas[fin].startsWith(' ')) {
      fin++;
    }
    return (inicio, fin);
  }
}
