/// Fallas de "Repara la red" (SPEC-001 T1): cada una cambia una sola cosa en
/// un solo equipo de la configuración que genera el Diseñador (un switch SW1
/// y un router R1 en router-on-a-stick), con su síntoma y su causa.
library;

import 'generador.dart';
import 'ip.dart';
import 'plan_red.dart';

enum TipoFalla {
  fisicaApagada,
  subinterfazApagada,
  mascaraGateway,
  sinEncapsulacion,
  gatewayEquivocado,
  sinDefaultRouter,
  defaultRouterEquivocado,
  sinPool,
  gatewayNoExcluido,
  puertoOtraVlan,
  troncalSinVlan,
  nativaDistinta,
}

const _deSwitch = {TipoFalla.puertoOtraVlan, TipoFalla.troncalSinVlan, TipoFalla.nativaDistinta};

/// Hostname del equipo que cambia la falla.
String equipoDe(TipoFalla f) => _deSwitch.contains(f) ? 'SW1' : 'R1';

/// Qué está mal, como opción de respuesta.
String causaDe(TipoFalla f) => _causas[f]!;

const _causas = {
  TipoFalla.fisicaApagada: 'La interfaz física del router está apagada (shutdown).',
  TipoFalla.subinterfazApagada: 'La subinterfaz del segmento está apagada (shutdown).',
  TipoFalla.mascaraGateway: 'El gateway del router tiene la máscara equivocada.',
  TipoFalla.sinEncapsulacion: 'A la subinterfaz le falta encapsulation dot1Q.',
  TipoFalla.gatewayEquivocado: 'La subinterfaz tiene una IP distinta del gateway del plan.',
  TipoFalla.sinDefaultRouter: 'El pool DHCP no tiene default-router.',
  TipoFalla.defaultRouterEquivocado: 'El pool DHCP entrega un default-router equivocado.',
  TipoFalla.sinPool: 'No hay pool DHCP para el segmento.',
  TipoFalla.gatewayNoExcluido: 'El gateway no está excluido del DHCP.',
  TipoFalla.puertoOtraVlan: 'Los puertos de acceso del segmento están en otra VLAN.',
  TipoFalla.troncalSinVlan: 'El troncal no permite la VLAN del segmento.',
  TipoFalla.nativaDistinta: 'La VLAN nativa del troncal no coincide con la del router.',
};

/// Lo que vería el estudiante en el laboratorio con la falla [f] en [s].
String sintomaDe(TipoFalla f, SegmentoPlan s, PlanRed plan) => _sintomas[f]!(s, _otro(s, plan));

const _apipa = 'quedan con 169.254.x.x';

final Map<TipoFalla, String Function(SegmentoPlan, SegmentoPlan)> _sintomas = {
  TipoFalla.fisicaApagada: (_, _) =>
      'Ningún PC de ninguna VLAN recibe IP por DHCP: todos $_apipa y nadie llega a su gateway.',
  TipoFalla.subinterfazApagada: (s, _) =>
      'Los PC de ${s.nombre} $_apipa y no llegan a su gateway; las demás VLAN funcionan.',
  TipoFalla.mascaraGateway: (s, _) =>
      'Algunos PC de ${s.nombre} reciben IP pero no llegan al gateway ${s.gateway}; otros PC del mismo segmento sí.',
  TipoFalla.sinEncapsulacion: (s, _) =>
      'Los PC de ${s.nombre} $_apipa aunque sus puertos de acceso y el troncal están bien.',
  TipoFalla.gatewayEquivocado: (s, _) =>
      'Los PC de ${s.nombre} reciben IP y gateway ${s.gateway}, pero el ping al gateway falla.',
  TipoFalla.sinDefaultRouter: (s, _) =>
      'Los PC de ${s.nombre} reciben IP pero sin puerta de enlace: llegan a su red, no a las otras VLAN.',
  TipoFalla.defaultRouterEquivocado: (s, _) =>
      'Los PC de ${s.nombre} reciben como puerta de enlace ${_siguiente(s.gateway)} y no salen de su red.',
  TipoFalla.sinPool: (s, _) => 'Los PC de ${s.nombre} $_apipa; las demás VLAN reciben IP sin problema.',
  TipoFalla.gatewayNoExcluido: (s, _) =>
      'De vez en cuando un PC de ${s.nombre} recibe la IP ${s.gateway} y aparece un conflicto de IP con el router.',
  TipoFalla.puertoOtraVlan: (s, o) => 'Los PC de ${s.nombre} reciben una IP de la red de ${o.nombre} (${o.red}/${o.cidr}).',
  TipoFalla.troncalSinVlan: (s, _) =>
      'Los PC de ${s.nombre} $_apipa; en el switch sus puertos están en la VLAN ${s.vlan}.',
  TipoFalla.nativaDistinta: (_, _) => 'El switch avisa de native VLAN mismatch en el troncal hacia el router.',
};

/// El segmento que sigue a [s] en el plan (el último usa el primero).
SegmentoPlan _otro(SegmentoPlan s, PlanRed plan) {
  final i = plan.segmentos.indexOf(s);
  return plan.segmentos[(i + 1) % plan.segmentos.length];
}

String _siguiente(String ip) => ipATexto(ipANumero(ip)! + 1);

String _mascara(int cidr) => ipATexto((0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF);

/// Copia de [configs] con la falla [f] en el segmento [s].
List<ConfigEquipo> inyectarFalla(List<ConfigEquipo> configs, PlanRed plan, TipoFalla f, SegmentoPlan s) => [
  for (final c in configs)
    c.hostname == equipoDe(f) ? ConfigEquipo(c.hostname, _cambios[f]!([...c.lineas], s, _otro(s, plan))) : c,
];

typedef _Cambio = List<String> Function(List<String> l, SegmentoPlan s, SegmentoPlan otro);

String _ip(SegmentoPlan s) => ' ip address ${s.gateway} ${s.mascara}';

final Map<TipoFalla, _Cambio> _cambios = {
  TipoFalla.fisicaApagada: (l, _, _) => _reemplazar(l, ' no shutdown', ' shutdown'),
  TipoFalla.subinterfazApagada: (l, s, _) => l..insert(_indice(l, _ip(s)) + 1, ' shutdown'),
  TipoFalla.mascaraGateway: (l, s, _) =>
      _reemplazar(l, _ip(s), ' ip address ${s.gateway} ${_mascara(s.cidr + 1)}'),
  TipoFalla.sinEncapsulacion: (l, s, _) => l..removeAt(_indice(l, ' encapsulation dot1Q ${s.vlan}')),
  TipoFalla.gatewayEquivocado: (l, s, _) =>
      _reemplazar(l, _ip(s), ' ip address ${_siguiente(s.gateway)} ${s.mascara}'),
  TipoFalla.sinDefaultRouter: (l, s, _) => l..removeAt(_indice(l, ' default-router ${s.gateway}')),
  TipoFalla.defaultRouterEquivocado: (l, s, _) =>
      _reemplazar(l, ' default-router ${s.gateway}', ' default-router ${_siguiente(s.gateway)}'),
  TipoFalla.sinPool: (l, s, _) {
    final i = _indice(l, 'ip dhcp pool ${nombreIos(s.nombre)}');
    return l..removeRange(i, l.indexOf('exit', i) + 1);
  },
  TipoFalla.gatewayNoExcluido: (l, s, _) => l..removeAt(_indice(l, 'ip dhcp excluded-address ${s.gateway}')),
  TipoFalla.puertoOtraVlan: (l, s, o) {
    final i = l.indexOf(' switchport access vlan ${s.vlan}', _indice(l, ' description ${s.nombre}'));
    return l..[i] = ' switchport access vlan ${o.vlan}';
  },
  TipoFalla.troncalSinVlan: (l, s, _) {
    const base = ' switchport trunk allowed vlan ';
    final i = l.indexWhere((x) => x.startsWith(base));
    final vlans = l[i].substring(base.length).split(',')..remove('${s.vlan}');
    return l..[i] = '$base${vlans.join(',')}';
  },
  TipoFalla.nativaDistinta: (l, _, _) {
    final i = l.indexWhere((x) => x.startsWith(' switchport trunk native vlan '));
    return l..[i] = ' switchport trunk native vlan 1';
  },
};

/// Índice de la primera línea igual a [linea]; si no está, la configuración
/// no es la que genera el Diseñador.
int _indice(List<String> l, String linea) {
  final i = l.indexOf(linea);
  if (i < 0) throw StateError('no se encontró "$linea"');
  return i;
}

List<String> _reemplazar(List<String> l, String de, String a) => l..[_indice(l, de)] = a;
