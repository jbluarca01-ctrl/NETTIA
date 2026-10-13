/// Plan de verificación: qué comandos correr, en qué equipo, y qué se debe
/// ver si la red quedó como se diseñó.
library;

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
  final l3 = o.topologia == Topologia.switchCapa3;
  final sw = o.hostnameSwitch;
  final enrutador = l3 ? sw : o.hostnameRouter;
  final puertos = rangosDeAcceso(plan, o);
  final segs = plan.segmentos;
  return [
    for (var i = 0; i < segs.length; i++)
      PasoVerificacion(
        sw,
        'show vlan brief',
        'VLAN ${segs[i].vlan} ${nombreIos(segs[i].nombre)} activa en ${puertos[i]}',
      ),
    if (!l3) _troncal(plan, o),
    for (final s in segs)
      PasoVerificacion(
        enrutador,
        'show ip interface brief',
        '${_interfaz(s, o)} con ${s.gateway}, estado up/up',
      ),
    for (final s in segs) ..._coherencia(enrutador, s, o),
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

PasoVerificacion _troncal(PlanRed plan, OpcionesConfig o) {
  final nativa = plan.opciones.vlanNativa;
  final permitidas = vlansPermitidas(plan);
  return PasoVerificacion(
    o.hostnameSwitch,
    'show interfaces trunk',
    '${o.troncalSwitch} en trunking, nativa $nativa, VLAN permitidas $permitidas',
  );
}

/// Interfaz que hace de gateway del segmento: la SVI en capa 3 o la
/// subinterfaz del router.
String _interfaz(SegmentoPlan s, OpcionesConfig o) =>
    o.topologia == Topologia.switchCapa3
        ? 'Vlan${s.vlan}'
        : '${o.interfazRouter}.${s.vlan}';

/// El pool DHCP y el gateway deben tener la misma máscara: si no, las PC no
/// reciben IP y no hay otro síntoma.
List<PasoVerificacion> _coherencia(
  String enrutador,
  SegmentoPlan s,
  OpcionesConfig o,
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
      'show ip interface ${_interfaz(s, o)}',
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
