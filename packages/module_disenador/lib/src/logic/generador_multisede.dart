/// Configuración de una red con varios routers (SPEC-003 T2): cada sede con
/// el generador de siempre (sus switches y su router Rk) y, en cada router,
/// sus enlaces y su enrutamiento antes del DHCP.
library;

import 'fisica.dart';
import 'generador.dart';
import 'multisede.dart';
import 'verificacion.dart';

/// Las [opciones] de cada sede con sus hostnames: Rk y los switches
/// numerados en orden de sede.
List<OpcionesConfig> opcionesDeSedes(List<OpcionesConfig> opciones) {
  final sedes = <OpcionesConfig>[];
  var primerSwitch = 1;
  for (var i = 0; i < opciones.length; i++) {
    sedes.add(opciones[i].paraSede(i + 1, primerSwitch));
    primerSwitch += opciones[i].switches;
  }
  return sedes;
}

/// Los equipos de [red] en orden de sede (switches y después el router);
/// [opciones] trae las de cada sede (switches, reparto, DNS…).
List<ConfigEquipo> generarMultisede(RedMultisede red, List<OpcionesConfig> opciones) {
  final sedes = opcionesDeSedes(opciones);
  return [
    for (var i = 0; i < red.sedes.length; i++) ..._equiposDeSede(red, i, sedes[i]),
  ];
}

List<ConfigEquipo> _equiposDeSede(RedMultisede red, int i, OpcionesConfig o) {
  final sede = generarConfiguracion(red.sedes[i], o);
  final interfaces = disenarFisica(red.sedes[i], o).router.length;
  return [
    ...sede.take(sede.length - 1),
    _conEnrutamiento(sede.last, red, i, interfazDesplazada(o.interfazRouter, interfaces)),
  ];
}

/// [router] con sus enlaces (desde la interfaz [primera]) y su enrutamiento
/// justo antes del DHCP (todo router de sede tiene al menos un pool).
ConfigEquipo _conEnrutamiento(ConfigEquipo router, RedMultisede red, int i, String primera) {
  final lineas = [...router.lineas];
  final antes = lineas.indexWhere((l) => l.startsWith('ip dhcp '));
  lineas.insertAll(antes, [..._enlaces(red, i, primera), ..._enrutamiento(red, i)]);
  return ConfigEquipo(router.hostname, lineas);
}

List<String> _enlaces(RedMultisede red, int i, String primera) {
  final enlaces = red.enlacesDe(i);
  return [
    for (var k = 0; k < enlaces.length; k++) ...[
      'interface ${interfazDesplazada(primera, k)}',
      ' description ENLACE a R${enlaces[k].desde == i ? i + 2 : i}',
      ' ip address ${enlaces[k].desde == i ? enlaces[k].ipDesde : enlaces[k].ipHasta} ${Enlace.mascara}',
      ' no shutdown',
      'exit',
    ],
  ];
}

List<String> _enrutamiento(RedMultisede red, int i) {
  if (red.enrutamiento != Enrutamiento.ospf) {
    return [for (final r in red.rutas[i]) 'ip route ${r.red} ${r.mascara} ${r.siguienteSalto}'];
  }
  return [
    'router ospf 1',
    ' router-id ${routerId(i)}',
    for (final n in red.redesOspf(i)) ' network $n area 0',
    'exit',
  ];
}

/// La verificación de cada sede y, al final, la de los enlaces y las rutas.
List<PasoVerificacion> verificacionMultisede(RedMultisede red, List<OpcionesConfig> opciones) {
  final sedes = opcionesDeSedes(opciones);
  final codigo = red.enrutamiento == Enrutamiento.ospf ? 'O (OSPF)' : 'S (estáticas)';
  return [
    for (var i = 0; i < red.sedes.length; i++) ...planVerificacion(red.sedes[i], sedes[i]),
    for (final e in red.enlaces)
      PasoVerificacion('R${e.desde + 1}', 'ping ${e.ipHasta}', 'Responde: el enlace con R${e.desde + 2} está arriba.'),
    for (var i = 0; i < red.sedes.length; i++)
      PasoVerificacion('R${i + 1}', 'show ip route', 'Las redes de las otras sedes aparecen con $codigo.'),
  ];
}
