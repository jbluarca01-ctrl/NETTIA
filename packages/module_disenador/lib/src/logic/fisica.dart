/// Distribución física del diseño: qué VLAN y puertos lleva cada switch,
/// sus troncales y de qué interfaz del router cuelga cada subinterfaz.
library;

import 'opciones.dart';
import 'plan_red.dart';

/// Un troncal visto desde un extremo.
class Troncal {
  const Troncal(this.puerto, this.vecino, this.vlans);
  final String puerto;

  /// Equipo del otro extremo (R1, SW2…).
  final String vecino;

  /// VLAN permitidas, separadas por comas, con la nativa al final.
  final String vlans;
}

/// Un switch con sus VLAN, puertos de acceso y troncales.
class SwitchFisico {
  const SwitchFisico(this.hostname, this.vlans, this.acceso, this.troncales);
  final String hostname;

  /// VLAN que se crean en el switch (la nativa aparte).
  final List<SegmentoPlan> vlans;

  /// Segmentos con PC en este switch y su rango de puertos de acceso.
  final List<(SegmentoPlan, String)> acceso;
  final List<Troncal> troncales;
}

/// Interfaz física del router y los segmentos que cuelgan de ella.
class InterfazRouter {
  const InterfazRouter(this.nombre, this.segmentos);
  final String nombre;
  final List<SegmentoPlan> segmentos;
}

class Fisica {
  const Fisica(this.switches, this.router);
  final List<SwitchFisico> switches;

  /// Vacío en capa 3: las VLAN se enrutan en el switch.
  final List<InterfazRouter> router;
}

/// Separador de las listas de VLAN. Constante con nombre: un literal `','`
/// genera un mutante idéntico al original (intercambia las dos comillas).
const String _coma = ',';

/// Rango de puertos de acceso de cada segmento de un único switch, en el
/// orden del plan.
List<String> rangosDeAcceso(PlanRed plan, OpcionesConfig o) =>
    _rangos(plan.segmentos.length, o.puertosAcceso, o.prefijoAcceso);

List<String> _rangos(int n, int puertos, String prefijo) {
  final porSegmento = puertos ~/ n;
  if (porSegmento < 1) {
    throw DisenoException(
      'No alcanzan los $puertos puertos de acceso para $n segmentos.',
    );
  }
  return [
    for (var i = 0; i < n; i++)
      '$prefijo${i * porSegmento + 1} - ${(i + 1) * porSegmento}',
  ];
}

/// Reparte el [plan] entre los equipos. Lanza [DisenoException] si un switch
/// queda sin PC o una VLAN repartida no puede llegar a su gateway.
Fisica disenarFisica(PlanRed plan, OpcionesConfig o) {
  if (o.topologia == Topologia.switchCapa3) {
    final rangos = rangosDeAcceso(plan, o);
    final segs = plan.segmentos;
    return Fisica([
      SwitchFisico(o.hostnameSwitch, segs, [
        for (var i = 0; i < segs.length; i++) (segs[i], rangos[i]),
      ], const []),
    ], const []);
  }
  final red = _Red(plan, o).._validar();
  return Fisica([
    for (var i = 0; i < o.switches; i++) red.switchFisico(i),
  ], red.router());
}

class _Red {
  _Red(this.plan, this.o);
  final PlanRed plan;
  final OpcionesConfig o;

  int get _n => o.switches;
  bool get _enlazados => o.conexion != Conexion.alRouter;

  int _pcs(SegmentoPlan s, int i) {
    final l = o.pcPorSwitch[s.nombre] ?? [s.hostsPedidos];
    return i < l.length ? l[i] : 0;
  }

  String _hostname(int i) => i == 0 ? o.hostnameSwitch : 'SW${i + 1}';

  bool _alRouter(int i) => o.conexion != Conexion.enCadena || i == 0;

  /// Switch cuyo troncal al router lleva la subinterfaz de [s].
  int _gateway(SegmentoPlan s) =>
      o.conexion == Conexion.enCadena
          ? 0
          : [for (var i = 0; i < _n; i++) i].firstWhere((i) => _pcs(s, i) > 0);

  List<SegmentoPlan> _presentes(int i) => [
    for (final s in plan.segmentos)
      if (_pcs(s, i) > 0) s,
  ];

  void _validar() {
    for (var i = 0; i < _n; i++) {
      if (_presentes(i).isEmpty) {
        throw DisenoException(
          '${_hostname(i)} no tiene PC asignadas: baja la cantidad de '
          'switches o reparte las PC.',
        );
      }
    }
    for (final s in plan.segmentos) {
      final con = [
        for (var i = 0; i < _n; i++)
          if (_pcs(s, i) > 0) _hostname(i),
      ];
      if (!_enlazados && con.length > 1) {
        throw DisenoException(
          '${s.nombre} (VLAN ${s.vlan}) tiene PC en varios switches '
          '(${con.join(', ')}); con «Cada uno al router» no llegan a un mismo '
          'gateway. Elige «Ambos» o deja sus PC en un solo switch.',
        );
      }
    }
  }

  String _lista(Iterable<SegmentoPlan> segs) =>
      [...segs.map((s) => s.vlan), plan.opciones.vlanNativa].join(_coma);

  List<(String, String)> _vecinos(int i) => [
    if (_alRouter(i))
      (o.hostnameRouter, _lista(plan.segmentos.where((s) => _gateway(s) == i))),
    if (_enlazados && i > 0) (_hostname(i - 1), _lista(plan.segmentos)),
    if (_enlazados && i < _n - 1) (_hostname(i + 1), _lista(plan.segmentos)),
  ];

  /// Puerto del troncal número [j] de un switch: los dos Gigabit y, si hace
  /// falta un tercero, el último FastEthernet.
  String _puerto(int j) => switch (j) {
    0 => o.troncalSwitch,
    1 => 'GigabitEthernet0/2',
    _ => '${o.prefijoAcceso}${o.puertosAcceso}',
  };

  SwitchFisico switchFisico(int i) {
    final vecinos = _vecinos(i);
    final presentes = _presentes(i);
    final libres = o.puertosAcceso - (vecinos.length > 2 ? 1 : 0);
    final rangos = _rangos(presentes.length, libres, o.prefijoAcceso);
    return SwitchFisico(
      _hostname(i),
      _enlazados && _n > 1 ? plan.segmentos : presentes,
      [for (var j = 0; j < presentes.length; j++) (presentes[j], rangos[j])],
      [
        for (var j = 0; j < vecinos.length; j++)
          Troncal(_puerto(j), vecinos[j].$1, vecinos[j].$2),
      ],
    );
  }

  /// Nombre de la interfaz del router hacia el switch [i]: la base con el
  /// último número desplazado en [i].
  String _interfazRouter(int i) {
    final base = o.interfazRouter;
    final corte = base.lastIndexOf('/') + 1;
    return '${base.substring(0, corte)}${int.parse(base.substring(corte)) + i}';
  }

  List<InterfazRouter> router() => [
    for (var i = 0; i < _n; i++)
      if (_alRouter(i))
        InterfazRouter(_interfazRouter(i), [
          for (final s in plan.segmentos)
            if (_gateway(s) == i) s,
        ]),
  ];
}
