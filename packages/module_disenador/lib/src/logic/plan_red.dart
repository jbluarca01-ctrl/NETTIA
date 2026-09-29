/// Plan de direccionamiento de una red a partir de requisitos: VLSM con VLAN,
/// gateway, rango reservado, rango DHCP y utilización por segmento.
library;

import 'package:module_calculadora/logica_ipv4.dart';

import 'ip.dart';

/// Un requisito: un segmento de la red (p. ej. "VENTAS") con sus hosts y,
/// opcionalmente, la VLAN que debe usar.
class Segmento {
  const Segmento(this.nombre, this.hosts, {this.vlan});
  final String nombre;
  final int hosts;
  final int? vlan;
}

/// Opciones de diseño comunes a todos los segmentos.
class OpcionesPlan {
  const OpcionesPlan({
    this.gatewayAlFinal = false,
    this.reservadas = 0,
    this.crecimientoPct = 0,
    this.vlanNativa = 99,
  });

  /// `true`: gateway en la última IP útil; `false`: en la primera.
  final bool gatewayAlFinal;

  /// IPs fijas por segmento (servidores, impresoras, APs) fuera del DHCP.
  final int reservadas;

  /// Margen de crecimiento sobre los hosts pedidos, en porcentaje.
  final int crecimientoPct;

  /// VLAN nativa de los troncales; no puede llevar usuarios.
  final int vlanNativa;
}

/// Un segmento ya direccionado.
class SegmentoPlan {
  const SegmentoPlan({
    required this.nombre,
    required this.vlan,
    required this.red,
    required this.cidr,
    required this.mascara,
    required this.wildcard,
    required this.gateway,
    required this.reservadas,
    required this.dhcp,
    required this.broadcast,
    required this.hostsPedidos,
    required this.utilizacionPct,
  });

  final String nombre;
  final int vlan;
  final String red;
  final int cidr;
  final String mascara;
  final String wildcard;
  final String gateway;

  /// Rango de IPs fijas; `null` si no se reservó ninguna.
  final RangoIp? reservadas;
  final RangoIp dhcp;
  final String broadcast;
  final int hostsPedidos;

  /// Hosts pedidos sobre direcciones del DHCP, en porcentaje (truncado).
  final int utilizacionPct;
}

/// El plan completo: segmentos en orden de asignación (de mayor a menor).
class PlanRed {
  const PlanRed({
    required this.redBase,
    required this.cidrBase,
    required this.opciones,
    required this.segmentos,
    required this.direccionesLibres,
    required this.avisos,
  });

  final String redBase;
  final int cidrBase;
  final OpcionesPlan opciones;
  final List<SegmentoPlan> segmentos;
  final int direccionesLibres;
  final List<String> avisos;
}

/// Error de diseño con un mensaje listo para mostrar.
class DisenoException implements Exception {
  const DisenoException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Diseña el direccionamiento de [segmentos] dentro de [redBase]/[cidr].
/// Lanza [DisenoException] si los requisitos son inválidos o no caben.
PlanRed planificarRed(
  String redBase,
  int cidr,
  List<Segmento> segmentos,
  OpcionesPlan opciones,
) {
  _validarOpciones(opciones);
  final nombres = _nombres(segmentos);
  final vlans = _vlans(segmentos, nombres, opciones.vlanNativa);
  final ResultadoVlsm vlsm;
  try {
    vlsm = calcularVlsm(redBase, cidr, [
      for (var i = 0; i < segmentos.length; i++)
        RequerimientoVlsm(nombres[i], _necesarias(segmentos[i].hosts, opciones)),
    ]);
  } on SubneteoException catch (e) {
    throw DisenoException(e.mensaje);
  }
  final indice = {for (var i = 0; i < nombres.length; i++) nombres[i]: i};
  return PlanRed(
    redBase: vlsm.subredes.first.red,
    cidrBase: cidr,
    opciones: opciones,
    segmentos: [
      for (final sub in vlsm.subredes)
        _segmentoPlan(sub, vlans[indice[sub.nombre]!],
            segmentos[indice[sub.nombre]!].hosts, opciones),
    ],
    direccionesLibres: vlsm.direccionesLibres,
    avisos: vlsm.avisos,
  );
}

void _validarOpciones(OpcionesPlan o) {
  if (o.reservadas < 0) {
    throw const DisenoException('Las IPs reservadas no pueden ser negativas.');
  }
  if (o.crecimientoPct < 0) {
    throw const DisenoException('El crecimiento no puede ser negativo.');
  }
  if (o.vlanNativa != 1 && !_vlanValida(o.vlanNativa)) {
    throw DisenoException('La VLAN nativa ${o.vlanNativa} no es válida: '
        'usa 2–1001 o 1006–4094.');
  }
}

List<String> _nombres(List<Segmento> segmentos) {
  if (segmentos.isEmpty) {
    throw const DisenoException('Agrega al menos un segmento con sus hosts.');
  }
  final vistos = <String>{};
  final nombres = <String>[];
  for (final s in segmentos) {
    final nombre = s.nombre.trim();
    if (nombre.isEmpty) {
      throw const DisenoException('Cada segmento necesita un nombre.');
    }
    if (s.hosts < 1) {
      throw DisenoException('"$nombre" necesita al menos 1 host.');
    }
    if (!vistos.add(nombre.toUpperCase())) {
      throw DisenoException('El nombre "$nombre" está repetido.');
    }
    nombres.add(nombre);
  }
  return nombres;
}

bool _vlanValida(int v) => (v >= 2 && v <= 1001) || (v >= 1006 && v <= 4094);

List<int> _vlans(List<Segmento> segmentos, List<String> nombres, int nativa) {
  final usadas = _vlansExplicitas(segmentos, nombres, nativa);
  final vlans = <int>[];
  var automatica = 0;
  for (final s in segmentos) {
    final explicita = s.vlan;
    if (explicita == null) {
      automatica = _siguienteLibre(automatica, usadas, nativa);
    }
    vlans.add(explicita ?? automatica);
  }
  return vlans;
}

/// Valida las VLAN pedidas explícitamente y las devuelve con su segmento.
Map<int, String> _vlansExplicitas(
    List<Segmento> segmentos, List<String> nombres, int nativa) {
  final usadas = <int, String>{};
  for (var i = 0; i < segmentos.length; i++) {
    final v = segmentos[i].vlan;
    if (v == null) continue;
    if (!_vlanValida(v)) {
      throw DisenoException('La VLAN $v no es válida para "${nombres[i]}": '
          'usa 2–1001 o 1006–4094 (la 1 y la 1002–1005 están reservadas).');
    }
    if (v == nativa) {
      throw DisenoException('La VLAN $v de "${nombres[i]}" es la VLAN nativa; '
          'la nativa no debe llevar usuarios.');
    }
    final previo = usadas[v];
    if (previo != null) {
      throw DisenoException(
          'La VLAN $v está repetida ("$previo" y "${nombres[i]}").');
    }
    usadas[v] = nombres[i];
  }
  return usadas;
}

int _siguienteLibre(int anterior, Map<int, String> usadas, int nativa) {
  var v = anterior + 10;
  while (usadas.containsKey(v) || v == nativa) {
    v += 10;
  }
  return v;
}

/// Direcciones útiles que necesita un segmento: hosts con el crecimiento
/// (redondeado hacia arriba), más las reservadas, más el gateway.
int _necesarias(int hosts, OpcionesPlan o) =>
    (hosts * (100 + o.crecimientoPct) + 99) ~/ 100 + o.reservadas + 1;

SegmentoPlan _segmentoPlan(
    SubredIpv4 sub, int vlan, int hostsPedidos, OpcionesPlan o) {
  final red = ipANumero(sub.red)!;
  final broadcast = ipANumero(sub.broadcast)!;
  final alFinal = o.gatewayAlFinal;
  final libreDesde = alFinal ? red + 1 : red + 2;
  final dhcp = RangoIp(
      libreDesde + o.reservadas, alFinal ? broadcast - 2 : broadcast - 1);
  return SegmentoPlan(
    nombre: sub.nombre!,
    vlan: vlan,
    red: sub.red,
    cidr: sub.cidr,
    mascara: sub.mascara,
    wildcard: ipATexto(broadcast - red),
    gateway: ipATexto(alFinal ? broadcast - 1 : red + 1),
    reservadas: o.reservadas == 0
        ? null
        : RangoIp(libreDesde, libreDesde + o.reservadas - 1),
    dhcp: dhcp,
    broadcast: sub.broadcast,
    hostsPedidos: hostsPedidos,
    utilizacionPct: hostsPedidos * 100 ~/ dhcp.cantidad,
  );
}
