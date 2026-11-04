/// Lectura del formulario del Diseñador: del texto escrito al diseño completo.
library;

import 'generador.dart';
import 'generador_multisede.dart';
import 'multisede.dart';
import 'plan_red.dart';
import 'verificacion.dart';

export 'multisede.dart' show Enrutamiento, RedMultisede;

/// Una sede más (la 2, la 3…) de una red con varios routers: su red base y
/// sus filas (nombre, hosts), con un switch (SPEC-003 T3).
class EntradaSede {
  const EntradaSede(this.redBase, this.segmentos);
  final String redBase;
  final List<(String, String)> segmentos;
}

/// Lo que se escribió en el formulario, tal cual.
class EntradaDiseno {
  const EntradaDiseno({
    required this.redBase,
    required this.segmentos,
    this.reservadas = '',
    this.crecimiento = '',
    this.gatewayAlFinal = false,
    this.topologia = Topologia.routerOnAStick,
    this.dns = '',
    this.dominio = '',
    this.clave = '',
    this.switches = 1,
    this.conexion = Conexion.alRouter,
    this.sedesExtra = const [],
    this.redEnlaces,
    this.enrutamiento = Enrutamiento.estaticaResumida,
  });

  final String redBase;

  /// Filas (nombre, hosts en SW1, SW2…); las filas vacías se ignoran.
  final List<(String, List<String>)> segmentos;
  final String reservadas;
  final String crecimiento;
  final bool gatewayAlFinal;
  final Topologia topologia;
  final String dns;
  final String dominio;
  final String clave;

  /// Switches de acceso; en capa 3 siempre hay uno.
  final int switches;
  final Conexion conexion;

  /// Sedes 2, 3…: con alguna, la red tiene un router por sede (SPEC-003).
  final List<EntradaSede> sedesExtra;
  /// `null`: no se escribió.
  final String? redEnlaces;
  final Enrutamiento enrutamiento;
}

/// Todo lo que sale de un diseño válido.
class Diseno {
  const Diseno(this.plan, this.equipos, this.verificacion, {this.red, this.sedeDe = const {}});

  /// El plan de la primera sede (la única si hay un solo router).
  final PlanRed plan;
  final List<ConfigEquipo> equipos;
  final List<PasoVerificacion> verificacion;

  /// La red con varios routers; `null` con uno solo.
  final RedMultisede? red;

  /// Índice de la sede de cada equipo, por hostname (vacío con un router).
  final Map<String, int> sedeDe;

  /// El plan de la sede del equipo cuyo `hostname` aparece en [config]; si
  /// no se reconoce (o hay un solo router), el de la primera sede.
  PlanRed planPara(String config) {
    const prefijo = 'hostname ';
    final linea = config.split('\n').map((l) => l.trim()).where((l) => l.startsWith(prefijo)).firstOrNull;
    final i = linea == null ? null : sedeDe[linea.substring(prefijo.length)];
    return i == null ? plan : red!.sedes[i];
  }
}

/// Diseña la red de [e]. Lanza [DisenoException] con un mensaje para
/// mostrar si algo de lo escrito no sirve.
Diseno disenar(EntradaDiseno e) {
  final multisede = e.sedesExtra.isNotEmpty;
  final topologia = multisede ? Topologia.routerOnAStick : e.topologia;
  final (red, cidr) = leerRedBase(e.redBase);
  final switches = topologia == Topologia.switchCapa3 ? 1 : e.switches;
  final plan = planificarRed(
    red,
    cidr,
    leerSegmentos(e.segmentos, switches: switches),
    OpcionesPlan(
      reservadas: leerEntero(e.reservadas, 'IPs reservadas'),
      crecimientoPct: leerEntero(e.crecimiento, 'crecimiento'),
      gatewayAlFinal: e.gatewayAlFinal,
    ),
  );
  final o = OpcionesConfig(
    topologia: topologia,
    dns: e.dns.trim(),
    dominio: e.dominio.trim(),
    enableSecret: e.clave.trim(),
    switches: switches,
    conexion: e.conexion,
    pcPorSwitch: leerReparto(e.segmentos, switches),
  );
  if (multisede) return _disenarMultisede(e, plan, o);
  return Diseno(plan, generarConfiguracion(plan, o), planVerificacion(plan, o));
}

/// Red con un router por sede: la primera con [plan] y [o]; las demás con un
/// switch y las mismas opciones de plan, DNS, dominio y clave.
Diseno _disenarMultisede(EntradaDiseno e, PlanRed plan, OpcionesConfig o) {
  final planes = [
    plan,
    for (var k = 0; k < e.sedesExtra.length; k++) _planSede(e.sedesExtra[k], k + 2, plan.opciones),
  ];
  final opciones = [
    o,
    for (final _ in e.sedesExtra) OpcionesConfig(dns: o.dns, dominio: o.dominio, enableSecret: o.enableSecret),
  ];
  final red = planificarMultisede(planes, e.redEnlaces, e.enrutamiento);
  final equipos = generarMultisede(red, opciones);
  return Diseno(plan, equipos, verificacionMultisede(red, opciones), red: red, sedeDe: _sedeDe(equipos));
}

/// La sede [k] (desde 2); sus errores dicen de qué sede son.
PlanRed _planSede(EntradaSede s, int k, OpcionesPlan opciones) {
  try {
    final (red, cidr) = leerRedBase(s.redBase);
    return planificarRed(red, cidr, leerSegmentos([for (final (n, h) in s.segmentos) (n, [h])]), opciones);
  } on DisenoException catch (e) {
    throw DisenoException('Sede $k: ${e.mensaje}');
  }
}

/// Sede de cada equipo: los switches y el router Rk que los cierra.
Map<String, int> _sedeDe(List<ConfigEquipo> equipos) {
  final sedes = <String, int>{};
  var k = 0;
  for (final c in equipos) {
    sedes[c.hostname] = k;
    if (c.hostname == 'R${k + 1}') k++;
  }
  return sedes;
}

/// Red base "192.168.10.0/24" → ("192.168.10.0", 24).
(String, int) leerRedBase(String texto) {
  final partes = texto.split('/');
  final cidr = partes.length == 2 ? int.tryParse(partes[1].trim()) : null;
  if (cidr == null) {
    throw const DisenoException(
      'Escribe la red base con su prefijo, p. ej. 192.168.10.0/24.',
    );
  }
  return (partes[0].trim(), cidr);
}

/// Segmentos de las filas no vacías del formulario: los hosts son la suma
/// de las PC en los primeros [switches].
List<Segmento> leerSegmentos(
  List<(String, List<String>)> filas, {
  int switches = 1,
}) => [
  for (final (nombre, pcs) in _filas(filas, switches))
    Segmento(nombre, pcs.reduce((a, b) => a + b)),
];

/// PC de cada segmento (por nombre) en SW1, SW2…; un campo vacío vale 0.
Map<String, List<int>> leerReparto(
  List<(String, List<String>)> filas,
  int switches,
) => {for (final (nombre, pcs) in _filas(filas, switches)) nombre: pcs};

List<(String, List<int>)> _filas(
  List<(String, List<String>)> filas,
  int switches,
) => [
  for (final (nombre, campos) in filas)
    if (_conDatos(nombre, campos.take(switches)))
      (nombre.trim(), _pcs(nombre.trim(), campos.take(switches))),
];

bool _conDatos(String nombre, Iterable<String> campos) =>
    nombre.trim().isNotEmpty || campos.any((c) => c.trim().isNotEmpty);

List<int> _pcs(String nombre, Iterable<String> campos) {
  final error = DisenoException('"$nombre": escribe los hosts como un número.');
  final textos = [for (final c in campos) c.trim()];
  if (textos.every((t) => t.isEmpty)) throw error;
  return [
    for (final t in textos) t.isEmpty ? 0 : int.tryParse(t) ?? (throw error),
  ];
}

/// Número de un campo opcional: vacío vale 0.
int leerEntero(String texto, String campo) {
  final t = texto.trim();
  if (t.isEmpty) return 0;
  final n = int.tryParse(t);
  if (n == null) {
    throw DisenoException('El campo "$campo" debe ser un número.');
  }
  return n;
}
