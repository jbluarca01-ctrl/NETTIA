/// Plan de verificación: qué comandos correr, en qué equipo, y qué se debe
/// ver si la red quedó como se diseñó.
library;

import 'fisica.dart';
import 'generador.dart';
import 'ip.dart';
import 'plan_red.dart';

class PasoVerificacion {
  const PasoVerificacion(this.equipo, this.comando, this.esperado);
  final String equipo;
  final String comando;
  final String esperado;
}

List<PasoVerificacion> planVerificacion(PlanRed plan, OpcionesConfig o) {
  final f = disenarFisica(plan, o);
  final enrutador =
      o.topologia == Topologia.switchCapa3
          ? o.hostnameSwitch
          : o.hostnameRouter;
  final interfaz = _interfaces(f);
  final nativa = plan.opciones.vlanNativa;
  final segs = plan.segmentos;
  return [
    for (final sw in f.switches) ..._switch(sw, nativa),
    for (final s in segs)
      PasoVerificacion(
        enrutador,
        'show ip interface brief',
        '${interfaz(s)} con ${s.gateway}, estado up/up',
      ),
    for (final s in segs) ..._coherencia(enrutador, s, interfaz(s)),
    for (final s in segs) ..._pc(s),
    if (segs.length > 1)
      PasoVerificacion(
        'PC de ${segs[0].nombre}',
        'ping ${segs[1].gateway}',
        'Responde: el enrutamiento entre VLAN funciona',
      ),
    PasoVerificacion(
      enrutador,
      'show ip dhcp binding',
      'Aparecen las PCs con direcciones de los pools',
    ),
  ];
}

/// Pasos de un switch: sus VLAN con PC primero y luego sus troncales.
List<PasoVerificacion> _switch(SwitchFisico sw, int nativa) => [
  for (final (s, puertos) in sw.acceso)
    PasoVerificacion(
      sw.hostname,
      'show vlan brief',
      'VLAN ${s.vlan} ${nombreIos(s.nombre)} activa en $puertos',
    ),
  for (final t in sw.troncales)
    PasoVerificacion(
      sw.hostname,
      'show interfaces trunk',
      '${t.puerto} en trunking, nativa $nativa, VLAN permitidas ${t.vlans}',
    ),
];

/// Interfaz que hace de gateway de cada segmento: la subinterfaz del router
/// de la que cuelga o, en capa 3, la SVI.
String Function(SegmentoPlan) _interfaces(Fisica f) {
  final porVlan = {
    for (final i in f.router)
      for (final s in i.segmentos) s.vlan: '${i.nombre}.${s.vlan}',
  };
  return (s) => porVlan[s.vlan] ?? 'Vlan${s.vlan}';
}

/// El pool DHCP y el gateway deben tener la misma máscara: si no, las PC no
/// reciben IP y no hay otro síntoma.
List<PasoVerificacion> _coherencia(
  String enrutador,
  SegmentoPlan s,
  String interfaz,
) {
  final pool = nombreIos(s.nombre);
  return [
    PasoVerificacion(
      enrutador,
      'show ip dhcp pool $pool',
      'Total addresses ${(1 << (32 - s.cidr)) - 2}, el tamaño del bloque '
          '/${s.cidr}; otro número indica una máscara mal escrita en el pool',
    ),
    PasoVerificacion(
      enrutador,
      'show ip interface $interfaz',
      'Internet address is ${s.gateway}/${s.cidr}, la misma máscara que el '
          'pool $pool',
    ),
  ];
}

List<PasoVerificacion> _pc(SegmentoPlan s) => [
  PasoVerificacion(
    'PC de ${s.nombre}',
    'ipconfig /renew',
    'IP entre ${ipATexto(s.dhcp.desde)} y ${ipATexto(s.dhcp.hasta)}, '
        'máscara ${s.mascara}, gateway ${s.gateway}',
  ),
  PasoVerificacion(
    'PC de ${s.nombre}',
    'ping ${s.gateway}',
    'Responde: la PC llega a su gateway',
  ),
];
