/// Explica la salida de algunos comandos `show` de Cisco IOS pegada por el
/// usuario (sin Flutter, por reglas y sin red). Las causas que propone son las
/// **frecuentes**, no un diagnóstico definitivo.
///
/// Fuentes de las interpretaciones: guías de Cisco sobre estados de interfaz
/// (show ip interface), VLAN de los Catalyst 2960 y "Troubleshoot OSPF
/// Neighbors Stuck in Exstart/Exchange State" (Cisco doc 13684-12).
library;

import 'explicador_pc.dart';
import 'explicador_router.dart';
import 'modelo_show.dart';

export 'modelo_show.dart';

/// Palabras que deben aparecer todas para reconocer cada comando (en orden:
/// gana la primera firma que calce).
const _firmas = <(TipoShow, List<String>)>[
  (TipoShow.ipInterfaceBrief, ['interface', 'ip-address', 'protocol']),
  (TipoShow.vlanBrief, ['vlan name', 'status', 'ports']),
  (TipoShow.ospfNeighbor, ['neighbor id', 'state', 'dead time']),
  (TipoShow.ipRoute, ['gateway of last resort']),
  (TipoShow.ipRoute, ['is directly connected']),
  (TipoShow.interfacesTrunk, ['port', 'encapsulation', 'native vlan']),
  (TipoShow.dhcpBinding, ['lease expiration']),
  (TipoShow.ipconfig, ['subnet mask']),
  (TipoShow.arp, ['physical address']),
  (TipoShow.arp, ['no arp entries']),
];

/// Adivina de qué comando es la salida, o null si no la reconoce.
TipoShow? detectarTipoShow(String texto) {
  final t = texto.toLowerCase();
  for (final (tipo, claves) in _firmas) {
    if (claves.every(t.contains)) return tipo;
  }
  return null;
}

const _explicadores = <TipoShow, ExplicacionShow Function(String)>{
  TipoShow.ipInterfaceBrief: _ipBrief,
  TipoShow.vlanBrief: _vlanBrief,
  TipoShow.ospfNeighbor: _ospf,
  TipoShow.ipRoute: explicarRuta,
  TipoShow.interfacesTrunk: explicarTrunk,
  TipoShow.dhcpBinding: explicarDhcpBinding,
  TipoShow.ipconfig: explicarIpconfig,
  TipoShow.arp: explicarArp,
};

/// Explica [texto]. Devuelve null si no reconoce el comando.
ExplicacionShow? explicarSalidaShow(String texto) {
  final tipo = detectarTipoShow(texto);
  return tipo == null ? null : _explicadores[tipo]!(texto);
}

// ---------------------------------------------------------------- ip brief

final RegExp _reIpBrief = RegExp(
  r'^(\S+)\s+(\S+)\s+(?:YES|NO)\s+\S+\s+(administratively down|up|down|deleted)\s+(up|down)\s*$',
  caseSensitive: false,
);

ExplicacionShow _ipBrief(String texto) {
  final h = <Hallazgo>[];
  final ips = <String, List<String>>{};
  var total = 0;
  var arriba = 0;
  for (final linea in texto.split('\n')) {
    final m = _reIpBrief.firstMatch(linea.trimRight());
    if (m == null) continue;
    total++;
    final nombre = m.group(1)!;
    final ip = m.group(2)!;
    final estado = m.group(3)!.toLowerCase();
    final protocolo = m.group(4)!.toLowerCase();
    final esSvi = nombre.toLowerCase().startsWith('vlan');
    if (ip.toLowerCase() != 'unassigned') {
      ips.putIfAbsent(ip, () => <String>[]).add(nombre);
    }
    if (estado == 'up' && protocolo == 'up') {
      arriba++;
      if (ip.toLowerCase() == 'unassigned' && !esSvi) {
        h.add(Hallazgo(Nivel.aviso, '$nombre: up / up sin IP',
            'Funciona en capa 2 (normal en un puerto de switch). Si es una interfaz de router, falta `ip address`.'));
      } else {
        h.add(Hallazgo(Nivel.ok, '$nombre: up / up',
            ip.toLowerCase() == 'unassigned' ? 'Operativa.' : 'Operativa con IP $ip.'));
      }
    } else if (estado == 'administratively down') {
      h.add(Hallazgo(Nivel.problema, '$nombre: administratively down / down',
          'Está apagada con el comando `shutdown`. Para activarla: `interface $nombre` y luego `no shutdown`.'));
    } else if (estado == 'down' && protocolo == 'down') {
      h.add(Hallazgo(Nivel.problema, '$nombre: down / down',
          esSvi
              ? 'La SVI está caída: la VLAN no existe o no tiene ningún puerto activo. Revisa `show vlan brief` y que haya un puerto en esa VLAN (o un trunk que la lleve) en estado up.'
              : 'Sin señal de capa física. Revisa el cable (y que sea el tipo correcto), que el otro extremo esté encendido y no tenga `shutdown`, y la velocidad/dúplex.'));
    } else if (estado == 'up' && protocolo == 'down') {
      h.add(Hallazgo(Nivel.problema, '$nombre: up / down',
          esSvi
              ? 'La SVI queda up/down cuando la VLAN no tiene ningún puerto activo (ni trunk que la lleve). Verifica la VLAN y sus puertos.'
              : 'La capa física está activa pero falla el protocolo de línea. Causas frecuentes: encapsulación distinta en los dos extremos, keepalives, o (en seriales) reloj/`clock rate`.'));
    } else {
      h.add(Hallazgo(Nivel.aviso, '$nombre: $estado / $protocolo',
          'Estado poco común; revisa `show interfaces $nombre`.'));
    }
  }
  ips.forEach((ip, nombres) {
    if (nombres.length > 1) {
      h.add(Hallazgo(Nivel.problema, 'IP duplicada $ip',
          'La misma IP está en ${nombres.join(' y ')}: dos interfaces del mismo equipo no pueden compartir dirección.'));
    }
  });
  return ExplicacionShow(
    TipoShow.ipInterfaceBrief,
    total == 0
        ? 'No se encontraron interfaces en el texto pegado.'
        : '$total interfaces: $arriba en up/up, ${total - arriba} con algo que revisar.',
    ordenarHallazgos(h),
  );
}

// -------------------------------------------------------------- vlan brief

final RegExp _reVlan = RegExp(r'^(\d+)\s+(\S+)\s+(active|act/unsup|act/lshut|suspended|sus/lshut)\b\s*(.*)$');

ExplicacionShow _vlanBrief(String texto) {
  final h = <Hallazgo>[];
  final vlans = <(int, String, String, StringBuffer)>[];
  for (final linea in texto.split('\n')) {
    final m = _reVlan.firstMatch(linea.trimRight());
    if (m != null) {
      vlans.add((int.parse(m.group(1)!), m.group(2)!, m.group(3)!, StringBuffer(m.group(4)!)));
    } else if (vlans.isNotEmpty && RegExp(r'^\s+\S').hasMatch(linea)) {
      vlans.last.$4.write(' ${linea.trim()}'); // continuación de la lista de puertos
    }
  }
  var propias = 0;
  var conPuertosEnVlan1 = 0;
  for (final (id, nombre, estado, puertos) in vlans) {
    final lista = puertos.toString().trim();
    final defecto = id == 1 || (id >= 1002 && id <= 1005);
    if (!defecto) propias++;
    if (id == 1) {
      conPuertosEnVlan1 = lista
          .split(RegExp(r'[,\s]+'))
          .where((p) => p.isNotEmpty)
          .length; // con o sin coma al final de línea
    }
    if (estado.contains('lshut')) {
      h.add(Hallazgo(Nivel.problema, 'VLAN $id ($nombre): $estado',
          'La VLAN está apagada localmente (`shutdown` dentro de la VLAN). Para activarla: `vlan $id` y `no shutdown`.'));
    } else if (estado == 'suspended') {
      h.add(Hallazgo(Nivel.problema, 'VLAN $id ($nombre): suspended',
          'La VLAN está suspendida; revisa VTP y el estado con `show vlan id $id`.'));
    } else if (!defecto && lista.isEmpty) {
      h.add(Hallazgo(Nivel.aviso, 'VLAN $id ($nombre): sin puertos de acceso',
          'Existe pero ningún puerto de acceso está en ella. Es normal si solo viaja por trunk; si esperabas hosts, falta `switchport access vlan $id` en sus puertos.'));
    } else if (!defecto) {
      h.add(Hallazgo(Nivel.ok, 'VLAN $id ($nombre): activa', 'Puertos: $lista.'));
    }
  }
  if (propias > 0 && conPuertosEnVlan1 > 0) {
    h.add(Hallazgo(Nivel.aviso, 'Hay $conPuertosEnVlan1 puertos en la VLAN 1',
        'Los puertos que no se asignaron a otra VLAN quedan en la VLAN 1 (la predeterminada). Si allí hay equipos que deberían estar en otra VLAN, asígnalos con `switchport access vlan N`.'));
  }
  if (vlans.isNotEmpty) {
    h.add(const Hallazgo(Nivel.aviso, 'Los puertos en trunk no aparecen aquí',
        'Esta salida solo lista puertos de acceso. Para ver los trunk y las VLAN permitidas usa `show interfaces trunk`.'));
  }
  return ExplicacionShow(
    TipoShow.vlanBrief,
    vlans.isEmpty
        ? 'No se encontraron VLAN en el texto pegado.'
        : '${vlans.length} VLAN en la lista ($propias creadas por ti, el resto son las predeterminadas).',
    ordenarHallazgos(h),
  );
}

// ------------------------------------------------------------ ospf neighbor

final RegExp _reOspf = RegExp(
  r'^(\S+)\s+(\d+)\s+([A-Za-z0-9]+)(?:/\s*(\S+))?\s+(\d\d:\d\d:\d\d|-)\s+(\S+)\s+(\S+)\s*$',
);

ExplicacionShow _ospf(String texto) {
  final h = <Hallazgo>[];
  var vecinos = 0;
  var full = 0;
  for (final linea in texto.split('\n')) {
    final m = _reOspf.firstMatch(linea.trimRight());
    if (m == null) continue;
    vecinos++;
    final id = m.group(1)!;
    final estado = m.group(3)!.toUpperCase();
    final rol = (m.group(4) ?? '-').toUpperCase();
    final direccion = m.group(6)!;
    final interfaz = m.group(7)!;
    final donde = 'vecino $id ($direccion) por $interfaz';
    switch (estado) {
      case 'FULL':
        full++;
        h.add(Hallazgo(Nivel.ok, '$donde: FULL${rol == '-' ? '' : '/$rol'}',
            'Adyacencia completa: las bases de datos están sincronizadas.'));
      case '2WAY':
        h.add(Hallazgo(
            rol == 'DROTHER' ? Nivel.ok : Nivel.aviso,
            '$donde: 2WAY${rol == '-' ? '' : '/$rol'}',
            rol == 'DROTHER'
                ? 'Normal en redes de acceso múltiple: dos routers que no son DR/BDR solo llegan a 2-Way entre sí y forman FULL con el DR y el BDR.'
                : 'Se ven, pero no avanzaron a FULL. Si la red es de acceso múltiple puede ser normal (ninguno es DR/BDR con el otro); si es punto a punto, revisa el tipo de red.'));
      case 'INIT':
        h.add(Hallazgo(Nivel.problema, '$donde: INIT',
            'Recibes sus Hello pero él no te lista a ti como vecino. Revisa que el otro extremo tenga la interfaz en OSPF, ACL que bloqueen 224.0.0.5, autenticación y que ambos lados coincidan en área, máscara y temporizadores.'));
      case 'EXSTART':
      case 'EXCHANGE':
        h.add(Hallazgo(Nivel.problema, '$donde: $estado',
            'Atascado en $estado: la causa más común es un **MTU distinto** entre las dos interfaces (Cisco doc 13684-12). Iguala el MTU de ambos lados; `ip ospf mtu-ignore` desactiva la comprobación pero solo se justifica en casos raros. Comprueba también que el ping con el tamaño del MTU pase por el enlace.'));
      case 'LOADING':
        h.add(Hallazgo(Nivel.aviso, '$donde: LOADING',
            'Está recibiendo la base de datos. Si no pasa a FULL en segundos, puede haber paquetes perdidos o MTU inconsistente.'));
      default:
        h.add(Hallazgo(Nivel.problema, '$donde: $estado',
            'El vecino no está activo. Revisa la conectividad de la interfaz y los temporizadores hello/dead.'));
    }
  }
  if (vecinos == 0) {
    h.add(const Hallazgo(Nivel.problema, 'No hay vecinos OSPF',
        'Revisa: interfaces up/up, que la red esté cubierta por `network`/`ip ospf area`, que no sea `passive-interface`, y que coincidan área, máscara, hello/dead y autenticación con el otro router.'));
  }
  return ExplicacionShow(
    TipoShow.ospfNeighbor,
    vecinos == 0
        ? 'No se encontraron vecinos en el texto pegado.'
        : '$vecinos vecinos: $full en FULL, ${vecinos - full} por revisar.',
    ordenarHallazgos(h),
  );
}
