/// Configuración CLI de Cisco IOS generada a partir de un [PlanRed].
library;

import 'fisica.dart';
import 'opciones.dart';
import 'plan_red.dart';

export 'fisica.dart' show rangosDeAcceso;
export 'opciones.dart';

/// La configuración de un equipo, línea por línea.
class ConfigEquipo {
  const ConfigEquipo(this.hostname, this.lineas);
  final String hostname;
  final List<String> lineas;
  String get texto => lineas.join('\n');
}

/// Nombre aceptado por IOS para VLAN y pools: mayúsculas, sin tildes y con
/// `_` en lugar de espacios y símbolos.
String nombreIos(String nombre) {
  const tildes = {
    'Á': 'A',
    'É': 'E',
    'Í': 'I',
    'Ó': 'O',
    'Ú': 'U',
    'Ü': 'U',
    'Ñ': 'N',
  };
  var s = nombre.toUpperCase();
  tildes.forEach((k, v) => s = s.replaceAll(k, v));
  return s
      .replaceAll(RegExp('[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Configuración de cada equipo: un switch por cada switch de acceso y el
/// router en router-on-a-stick, o un único switch capa 3.
List<ConfigEquipo> generarConfiguracion(PlanRed plan, OpcionesConfig o) {
  final f = disenarFisica(plan, o);
  if (o.topologia == Topologia.switchCapa3) {
    final sw = f.switches.single;
    return [
      ConfigEquipo(sw.hostname, [
        ..._encabezado(sw.hostname, o),
        ..._vlans(sw.vlans, null),
        ..._accesos(sw),
        ..._svis(plan),
        ..._dhcp(plan, o),
        ..._cierre,
      ]),
    ];
  }
  final nativa = plan.opciones.vlanNativa;
  return [
    for (final sw in f.switches)
      ConfigEquipo(sw.hostname, [
        ..._encabezado(sw.hostname, o),
        ..._vlans(sw.vlans, nativa),
        ..._accesos(sw),
        for (final t in sw.troncales) ..._troncal(t, nativa),
        ..._cierre,
      ]),
    ConfigEquipo(o.hostnameRouter, [
      ..._encabezado(o.hostnameRouter, o),
      for (final i in f.router) ..._subinterfaces(i, nativa),
      ..._dhcp(plan, o),
      ..._cierre,
    ]),
  ];
}

const List<String> _cierre = ['end', 'write memory'];

/// Cierra el submodo (VLAN, interfaz o pool) y vuelve a la configuración
/// global, para que lo pegado no quede atascado en un submodo.
const String _salir = 'exit';

List<String> _encabezado(String hostname, OpcionesConfig o) => [
  'enable',
  'configure terminal',
  'hostname $hostname',
  'no ip domain-lookup',
  'service password-encryption',
  if (o.enableSecret.isEmpty)
    '! Define la clave: enable secret <tu-clave>'
  else
    'enable secret ${o.enableSecret}',
  'banner motd #Acceso solo autorizado#',
];

/// VLAN del switch y, si hay troncal, la [nativa].
List<String> _vlans(List<SegmentoPlan> segmentos, int? nativa) => [
  for (final s in segmentos) ...[
    'vlan ${s.vlan}',
    ' name ${nombreIos(s.nombre)}',
    _salir,
  ],
  if (nativa != null) ...['vlan $nativa', ' name NATIVA', _salir],
];

List<String> _accesos(SwitchFisico sw) => [
  for (final (s, puertos) in sw.acceso) ...[
    'interface range $puertos',
    ' description ${s.nombre}',
    ' switchport mode access',
    ' switchport access vlan ${s.vlan}',
    ' spanning-tree portfast',
    ' no shutdown',
    _salir,
  ],
];

List<String> _troncal(Troncal t, int nativa) => [
  'interface ${t.puerto}',
  ' description TRONCAL a ${t.vecino}',
  ' switchport mode trunk',
  ' switchport trunk native vlan $nativa',
  ' switchport trunk allowed vlan ${t.vlans}',
  ' no shutdown',
  _salir,
];

List<String> _svis(PlanRed plan) => [
  'ip routing',
  for (final s in plan.segmentos) ...[
    'interface Vlan${s.vlan}',
    ' description ${s.nombre}',
    ' ip address ${s.gateway} ${s.mascara}',
    ' no shutdown',
    _salir,
  ],
];

List<String> _subinterfaces(InterfazRouter i, int nativa) {
  final fisica = i.nombre;
  return [
    'interface $fisica',
    ' no shutdown',
    _salir,
    for (final s in i.segmentos) ...[
      'interface $fisica.${s.vlan}',
      ' description ${s.nombre}',
      ' encapsulation dot1Q ${s.vlan}',
      ' ip address ${s.gateway} ${s.mascara}',
      _salir,
    ],
    'interface $fisica.$nativa',
    ' description NATIVA',
    ' encapsulation dot1Q $nativa native',
    _salir,
  ];
}

List<String> _dhcp(PlanRed plan, OpcionesConfig o) => [
  for (final s in plan.segmentos) ...[
    'ip dhcp excluded-address ${s.gateway}',
    if (s.reservadas case final r?)
      'ip dhcp excluded-address ${r.toString().replaceAll(' – ', ' ')}',
    'ip dhcp pool ${nombreIos(s.nombre)}',
    ' network ${s.red} ${s.mascara}',
    ' default-router ${s.gateway}',
    if (o.dns.isNotEmpty) ' dns-server ${o.dns}',
    if (o.dominio.isNotEmpty) ' domain-name ${o.dominio}',
    _salir,
  ],
];
