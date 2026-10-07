/// Explica salidas de verificación del router y el switch vistas en clase:
/// show ip route, show interfaces trunk y show ip dhcp binding. Las causas
/// que propone son las frecuentes, no un diagnóstico definitivo.
library;

import 'modelo_show.dart';

// ---------------------------------------------------------------- ip route

final RegExp _reRuta = RegExp(
  r'^([A-Z])(\*?)(?:\s+(?:IA|E1|E2|EX|N1|N2))?\s+(\d+\.\d+\.\d+\.\d+/\d+)\s+(.*)$',
);

const _origen = <String, String>{
  'S': 'Estática',
  'O': 'OSPF',
  'D': 'EIGRP',
  'R': 'RIP',
  'B': 'BGP',
};

/// Hallazgo de una línea de la tabla, o `null` si no es una ruta (o es una
/// ruta local L, que repite la IP de la interfaz).
Hallazgo? _ruta(String linea) {
  final m = _reRuta.firstMatch(linea);
  if (m == null || m[1] == 'L') return null;
  final red = m[3]!;
  final resto = m[4]!;
  if (m[1] == 'C') {
    return Hallazgo(Nivel.ok, 'Conectada: $red', 'Por ${resto.split(', ').last}.');
  }
  final defecto = m[2] == '*' ? ' (por defecto)' : '';
  return Hallazgo(Nivel.ok, '${_origen[m[1]] ?? m[1]}$defecto: $red', resto);
}

/// show ip route.
ExplicacionShow explicarRuta(String texto) {
  final rutas = [
    for (final l in texto.split('\n')) _ruta(l.trim()),
  ].whereType<Hallazgo>().toList();
  final conectadas = rutas.where((h) => h.titulo.startsWith('Conectada')).length;
  final sinDefecto = texto.toLowerCase().contains('gateway of last resort is not set');
  return ExplicacionShow(
    TipoShow.ipRoute,
    '$conectadas redes conectadas, ${rutas.length - conectadas} aprendidas.',
    ordenarHallazgos([
      if (conectadas == 0)
        const Hallazgo(Nivel.problema, 'Ninguna red conectada',
            'Las interfaces con IP están caídas o sin IP: revisa show ip interface brief (up/up) y no shutdown.'),
      if (sinDefecto)
        const Hallazgo(Nivel.aviso, 'Sin ruta por defecto',
            'El router solo llega a las redes de la tabla. Si debe salir a otras redes o a Internet: ip route 0.0.0.0 0.0.0.0 <siguiente salto>.'),
      ...rutas,
    ]),
  );
}

// ---------------------------------------------------------- interfaces trunk

final RegExp _rePuerto = RegExp(
  r'^(\S+)\s+(on|desirable|auto|nonegotiate|off)\s+(\S+)\s+(\S+)\s+(\d+)\s*$',
);
final RegExp _reLista = RegExp(r'^(\S+)\s+([\d,\-]+|none)\s*$');

typedef _Puerto = ({String nombre, String modo, String enc, String estado, String nativa});

/// Tabla a la que van las filas tras la cabecera [t]: permitidas, activas o
/// ninguna (p. ej. la de spanning tree).
Map<String, String>? _seccionDe(
  String t,
  Map<String, String> permitidas,
  Map<String, String> activas,
) =>
    t.contains('allowed on trunk')
        ? permitidas
        : (t.contains('allowed and active') ? activas : null);

/// Puertos de la primera tabla y, por puerto, las listas de VLAN permitidas
/// y activas de las tablas siguientes.
(List<_Puerto>, Map<String, String>, Map<String, String>) _leerTrunk(String texto) {
  final puertos = <_Puerto>[];
  final permitidas = <String, String>{};
  final activas = <String, String>{};
  Map<String, String>? seccion;
  for (final linea in texto.split('\n').map((l) => l.trim())) {
    final t = linea.toLowerCase();
    if (t.startsWith('port')) {
      seccion = _seccionDe(t, permitidas, activas);
      continue;
    }
    final p = _rePuerto.firstMatch(linea);
    final l = _reLista.firstMatch(linea);
    if (p != null) {
      puertos.add((nombre: p[1]!, modo: p[2]!, enc: p[3]!, estado: p[4]!, nativa: p[5]!));
    } else if (l != null) {
      seccion?[l[1]!] = l[2]!;
    }
  }
  return (puertos, permitidas, activas);
}

/// VLAN de una lista como "10,20,30-32" ("none" = ninguna).
Set<int> _vlans(String lista) => {
      for (final parte in lista.split(','))
        if (parte.contains('-'))
          for (var v = int.parse(parte.split('-')[0]); v <= int.parse(parte.split('-')[1]); v++) v
        else if (parte != 'none')
          int.parse(parte),
    };

List<Hallazgo> _hallazgosPuerto(_Puerto p, String? permitidas, String? activas) {
  if (p.estado.toLowerCase() != 'trunking') {
    return [
      Hallazgo(Nivel.problema, '${p.nombre}: no está en trunk (${p.estado})',
          'Revisa switchport mode trunk en este puerto y en el otro extremo (en modo ${p.modo} no forma trunk por sí solo).'),
    ];
  }
  final faltan = (permitidas == null || activas == null)
      ? <int>[]
      : (_vlans(permitidas).difference(_vlans(activas)).toList()..sort());
  return [
    if (faltan.isNotEmpty && faltan.length <= 20)
      Hallazgo(Nivel.aviso, '${p.nombre}: VLAN permitidas que no existen en el switch',
          '${faltan.join(',')}. Créalas con vlan <número> o quítalas del trunk.'),
    Hallazgo(Nivel.ok, '${p.nombre}: trunk activo',
        'Encapsulación ${p.enc}, VLAN nativa ${p.nativa}, permite ${permitidas ?? '?'}.'),
  ];
}

/// show interfaces trunk.
ExplicacionShow explicarTrunk(String texto) {
  final (puertos, permitidas, activas) = _leerTrunk(texto);
  final h = [
    for (final p in puertos) ..._hallazgosPuerto(p, permitidas[p.nombre], activas[p.nombre]),
  ];
  final activos = puertos.where((p) => p.estado.toLowerCase() == 'trunking').length;
  return ExplicacionShow(
    TipoShow.interfacesTrunk,
    '$activos trunk activos de ${puertos.length}.',
    ordenarHallazgos([
      if (puertos.isEmpty)
        const Hallazgo(Nivel.aviso, 'No hay ningún trunk',
            'Falta switchport mode trunk en el puerto hacia el router o hacia el otro switch.'),
      ...h,
    ]),
  );
}

// --------------------------------------------------------- ip dhcp binding

final RegExp _reBinding = RegExp(
  r'^(\d+\.\d+\.\d+\.\d+)\s+(\S+)\s+.*?(automatic|manual)\s*$',
  caseSensitive: false,
);

/// show ip dhcp binding.
ExplicacionShow explicarDhcpBinding(String texto) {
  final entregadas = [
    for (final l in texto.split('\n'))
      if (_reBinding.firstMatch(l.trim()) case final m?)
        Hallazgo(Nivel.ok, m[1]!, 'Entregada a ${m[2]}.'),
  ];
  return ExplicacionShow(
    TipoShow.dhcpBinding,
    '${entregadas.length} direcciones entregadas por DHCP.',
    entregadas.isNotEmpty
        ? entregadas
        : const [
            Hallazgo(Nivel.problema, 'Nadie recibió IP por DHCP',
                'Revisa que el pool tenga network y default-router de la misma subred, que las PCs estén en DHCP y que la VLAN y el trunk lleguen al router. Si el servidor está en otra red, falta ip helper-address.'),
          ],
  );
}
