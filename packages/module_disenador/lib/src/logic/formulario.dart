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
  });

  final String redBase;

  /// Filas (nombre, hosts); las filas vacías se ignoran.
  final List<(String, String)> segmentos;
  final String reservadas;
  final String crecimiento;
  final bool gatewayAlFinal;
  final Topologia topologia;
  final String dns;
  final String dominio;
  final String clave;
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
  final plan = planificarRed(
    red,
    cidr,
    leerSegmentos(e.segmentos),
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

/// Segmentos de las filas no vacías del formulario.
List<Segmento> leerSegmentos(List<(String, String)> filas) => [
  for (final (nombre, hosts) in filas)
    if (nombre.trim().isNotEmpty || hosts.trim().isNotEmpty)
      Segmento(nombre.trim(), _hosts(nombre.trim(), hosts)),
];

int _hosts(String nombre, String texto) {
  final n = int.tryParse(texto.trim());
  if (n == null) {
    throw DisenoException('"$nombre": escribe los hosts como un número.');
  }
  return n;
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
