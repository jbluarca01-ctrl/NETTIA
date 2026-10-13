/// Lectura del formulario del Diseñador: del texto escrito al diseño completo.
library;

import 'generador.dart';
import 'plan_red.dart';
import 'verificacion.dart';

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
}

/// Todo lo que sale de un diseño válido.
class Diseno {
  const Diseno(this.plan, this.equipos, this.verificacion);
  final PlanRed plan;
  final List<ConfigEquipo> equipos;
  final List<PasoVerificacion> verificacion;
}

/// Diseña la red de [e]. Lanza [DisenoException] con un mensaje para
/// mostrar si algo de lo escrito no sirve.
Diseno disenar(EntradaDiseno e) {
  final (red, cidr) = leerRedBase(e.redBase);
  final switches = e.topologia == Topologia.switchCapa3 ? 1 : e.switches;
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
    topologia: e.topologia,
    dns: e.dns.trim(),
    dominio: e.dominio.trim(),
    enableSecret: e.clave.trim(),
    switches: switches,
    conexion: e.conexion,
    pcPorSwitch: leerReparto(e.segmentos, switches),
  );
  return Diseno(plan, generarConfiguracion(plan, o), planVerificacion(plan, o));
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
