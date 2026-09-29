/// Configuración CLI de Cisco IOS generada a partir de un [PlanRed].
library;

import 'plan_red.dart';

/// Cómo se enrutan las VLAN entre sí.
enum Topologia { routerOnAStick, switchCapa3 }

/// Datos de los equipos que no salen del plan.
class OpcionesConfig {
  const OpcionesConfig({
    this.topologia = Topologia.routerOnAStick,
    this.hostnameSwitch = 'SW1',
    this.hostnameRouter = 'R1',
    this.troncalSwitch = 'GigabitEthernet0/1',
    this.interfazRouter = 'GigabitEthernet0/0/0',
    this.prefijoAcceso = 'FastEthernet0/',
    this.puertosAcceso = 24,
    this.dns = '',
    this.dominio = '',
    this.enableSecret = '',
  });

  final Topologia topologia;
  final String hostnameSwitch;
  final String hostnameRouter;
  final String troncalSwitch;
  final String interfazRouter;
  final String prefijoAcceso;
  final int puertosAcceso;
  final String dns;
  final String dominio;
  final String enableSecret;
}

/// La configuración de un equipo, línea por línea.
class ConfigEquipo {
  const ConfigEquipo(this.hostname, this.lineas);
  final String hostname;
  final List<String> lineas;
  String get texto => lineas.join('\n');
}

/// Rango de puertos de acceso de cada segmento, en el orden del plan.
List<String> rangosDeAcceso(PlanRed plan, OpcionesConfig o) {
  final n = plan.segmentos.length;
  final porSegmento = o.puertosAcceso ~/ n;
  if (porSegmento < 1) {
    throw DisenoException(
      'No alcanzan los ${o.puertosAcceso} puertos de '
      'acceso para $n segmentos.',
    );
  }
  return [
    for (var i = 0; i < n; i++)
      '${o.prefijoAcceso}${i * porSegmento + 1} - ${(i + 1) * porSegmento}',
  ];
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

/// Configuración de cada equipo: switch y router en router-on-a-stick, o un
/// único switch capa 3.
List<ConfigEquipo> generarConfiguracion(PlanRed plan, OpcionesConfig o) {
  final puertos = rangosDeAcceso(plan, o);
  final l3 = o.topologia == Topologia.switchCapa3;
  final sw = [
    ..._encabezado(o.hostnameSwitch, o),
    ..._vlans(plan, incluirNativa: !l3),
    for (var i = 0; i < plan.segmentos.length; i++)
      ..._acceso(puertos[i], plan.segmentos[i]),
    if (l3) ..._svis(plan) else ..._troncal(plan, o),
    if (l3) ..._dhcp(plan, o),
    ..._cierre,
  ];
  if (l3) return [ConfigEquipo(o.hostnameSwitch, sw)];
  final router = [
    ..._encabezado(o.hostnameRouter, o),
    ..._subinterfaces(plan, o),
    ..._dhcp(plan, o),
    ..._cierre,
  ];
  return [
    ConfigEquipo(o.hostnameSwitch, sw),
    ConfigEquipo(o.hostnameRouter, router),
  ];
}

/// VLAN que debe permitir el troncal: las del plan y la nativa, separadas
/// por comas.
String vlansPermitidas(PlanRed plan) => [
  for (final s in plan.segmentos) s.vlan,
  plan.opciones.vlanNativa,
].join(_coma);

const String _coma = ',';

const List<String> _cierre = ['end', 'write memory'];

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

List<String> _vlans(PlanRed plan, {required bool incluirNativa}) => [
  for (final s in plan.segmentos) ...[
    'vlan ${s.vlan}',
    ' name ${nombreIos(s.nombre)}',
  ],
  if (incluirNativa) ...['vlan ${plan.opciones.vlanNativa}', ' name NATIVA'],
];

List<String> _acceso(String puertos, SegmentoPlan s) => [
  'interface range $puertos',
  ' description ${s.nombre}',
  ' switchport mode access',
  ' switchport access vlan ${s.vlan}',
  ' spanning-tree portfast',
  ' no shutdown',
];

List<String> _troncal(PlanRed plan, OpcionesConfig o) {
  final nativa = plan.opciones.vlanNativa;
  final permitidas = vlansPermitidas(plan);
  return [
    'interface ${o.troncalSwitch}',
    ' description TRONCAL',
    ' switchport mode trunk',
    ' switchport trunk native vlan $nativa',
    ' switchport trunk allowed vlan $permitidas',
    ' no shutdown',
  ];
}

List<String> _svis(PlanRed plan) => [
  'ip routing',
  for (final s in plan.segmentos) ...[
    'interface Vlan${s.vlan}',
    ' description ${s.nombre}',
    ' ip address ${s.gateway} ${s.mascara}',
    ' no shutdown',
  ],
];

List<String> _subinterfaces(PlanRed plan, OpcionesConfig o) {
  final fisica = o.interfazRouter;
  final nativa = plan.opciones.vlanNativa;
  return [
    'interface $fisica',
    ' no shutdown',
    for (final s in plan.segmentos) ...[
      'interface $fisica.${s.vlan}',
      ' description ${s.nombre}',
      ' encapsulation dot1Q ${s.vlan}',
      ' ip address ${s.gateway} ${s.mascara}',
    ],
    'interface $fisica.$nativa',
    ' description NATIVA',
    ' encapsulation dot1Q $nativa native',
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
  ],
];
