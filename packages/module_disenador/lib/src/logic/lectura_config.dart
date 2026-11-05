/// Lectura de una running-config de IOS en bloques (SPEC-004 T1): la usan
/// el auditor de sede y el doctor de redes.
library;

/// La running-config dividida en bloques.
class ConfigLeida {
  final interfaces = <String, List<String>>{};
  final pools = <String, List<String>>{};
  final globales = <String>[];

  /// Líneas del bloque `router ospf`; `null` si no lo hay.
  List<String>? ospf;

  bool _alguna(String prefijo) =>
      interfaces.values.any((ls) => ls.any((l) => l.startsWith(prefijo)));
  bool get tieneIp => _alguna('ip address ');
  bool get tieneSwitch => _alguna('switchport ');
  bool get vacia => !tieneIp && pools.isEmpty && !tieneSwitch;

  /// Abre el bloque de [linea] (interfaz, pool o `router ospf`) o la guarda
  /// como global.
  List<String>? abrir(String linea) {
    if (linea.startsWith('interface ')) {
      return interfaces[linea.substring(10).trim()] = [];
    }
    if (linea.startsWith('ip dhcp pool ')) {
      return pools[linea.substring(13).trim()] = [];
    }
    if (linea.startsWith('router ospf ')) return ospf = [];
    globales.add(linea);
    return null;
  }
}

ConfigLeida leerConfig(String texto) {
  final c = ConfigLeida();
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

/// Lo que sigue a [prefijo] en la primera línea que empieza con él.
String? valorDe(List<String> lineas, String prefijo) {
  for (final l in lineas) {
    if (l.startsWith(prefijo)) return l.substring(prefijo.length).trim();
  }
  return null;
}

/// Valor numérico de la primera línea que empieza con [prefijo].
int? enteroDe(List<String> lineas, String prefijo) {
  final v = valorDe(lineas, prefijo);
  return v == null ? null : int.tryParse(v);
}
