import 'package:flutter/material.dart';

import 'logic/auditor.dart';
import 'logic/formulario.dart';
import 'logic/generador.dart';
import 'logic/plan_red.dart';
import 'vistas_resultado.dart';

/// Pantalla del Diseñador de red: en "Datos" se escriben los requisitos y al
/// tocar Diseñar se llenan Plan, Configuración, Verificación y Auditar.
class DisenadorScreen extends StatefulWidget {
  const DisenadorScreen({super.key});

  @override
  State<DisenadorScreen> createState() => _DisenadorScreenState();
}

/// Nombre del segmento y sus PC en SW1, SW2 y SW3.
typedef _Fila = (TextEditingController, List<TextEditingController>);

class _DisenadorScreenState extends State<DisenadorScreen>
    with SingleTickerProviderStateMixin {
  static const double _hueco = 12;
  static const List<String> _pestanas = [
    'Datos',
    'Plan',
    'Configuración',
    'Verificación',
    'Auditar',
  ];

  late final TabController _tabs = TabController(
    length: _pestanas.length,
    vsync: this,
  );
  final _red = TextEditingController(text: '192.168.10.0/24');
  final List<_Fila> _filas = [_fila('VENTAS', '50'), _fila('TI', '20')];
  final _reservadas = TextEditingController();
  final _crecimiento = TextEditingController();
  final _dns = TextEditingController();
  final _dominio = TextEditingController();
  final _clave = TextEditingController();
  Topologia _topologia = Topologia.routerOnAStick;
  int _switches = 1;
  Conexion _conexion = Conexion.alRouter;
  bool _gatewayAlFinal = false;
  Diseno? _diseno;
  String? _error;
  final _auditoria = TextEditingController();

  /// Hallazgos de la última auditoría; se descartan al diseñar de nuevo.
  List<Hallazgo>? _hallazgos;

  static const int _maxSwitches = 3;

  static _Fila _fila(String nombre, String hosts) => (
    TextEditingController(text: nombre),
    [
      TextEditingController(text: hosts),
      for (var i = 1; i < _maxSwitches; i++) TextEditingController(),
    ],
  );

  /// Switches que se piden: en capa 3 siempre uno.
  int get _n => _topologia == Topologia.switchCapa3 ? 1 : _switches;

  static void _liberar(_Fila f) {
    f.$1.dispose();
    for (final c in f.$2) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _red,
      _reservadas,
      _crecimiento,
      _dns,
      _dominio,
      _clave,
      _auditoria,
    ]) {
      c.dispose();
    }
    _filas.forEach(_liberar);
    _tabs.dispose();
    super.dispose();
  }

  void _disenar() {
    try {
      final d = disenar(_entrada());
      setState(() {
        _diseno = d;
        _error = null;
        _hallazgos = null;
      });
      _tabs.animateTo(1);
    } on DisenoException catch (e) {
      setState(() {
        _diseno = null;
        _error = e.mensaje;
      });
    }
  }

  EntradaDiseno _entrada() => EntradaDiseno(
    redBase: _red.text,
    segmentos: [
      for (final (n, hs) in _filas) (n.text, [for (final h in hs) h.text]),
    ],
    reservadas: _reservadas.text,
    crecimiento: _crecimiento.text,
    gatewayAlFinal: _gatewayAlFinal,
    topologia: _topologia,
    dns: _dns.text,
    dominio: _dominio.text,
    clave: _clave.text,
    switches: _switches,
    conexion: _conexion,
  );

  void _agregar() => setState(() => _filas.add(_fila('', '')));

  /// Quita la fila [i]; sus controladores se liberan después del cuadro en
  /// que dejan de usarse.
  void _quitar(int i) {
    final fila = _filas[i];
    setState(() => _filas.removeAt(i));
    WidgetsBinding.instance.addPostFrameCallback((_) => _liberar(fila));
  }

  void _auditar(PlanRed plan) =>
      setState(() => _hallazgos = auditarConfig(_auditoria.text, plan));

  @override
  Widget build(BuildContext context) {
    final d = _diseno;
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [for (final t in _pestanas) Tab(text: t)],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _datos(context),
              VistaPlan(d),
              VistaConfiguracion(d),
              VistaVerificacion(d),
              VistaAuditar(d, _auditoria, _hallazgos, onAuditar: _auditar),
            ],
          ),
        ),
      ],
    );
  }

  Widget _datos(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(_hueco),
      children: [
        _campo(_red, 'Red base'),
        ..._equipos(tema),
        Text(
          _n == 1
              ? 'Segmentos: nombre y hosts'
              : 'Segmentos: nombre y PC por switch',
          style: tema.textTheme.titleSmall,
        ),
        Text(
          'En la configuración los espacios pasan a _ (Sala de reuniones → '
          'SALA_DE_REUNIONES): es lo que acepta un switch real.',
          style: tema.textTheme.bodySmall,
        ),
        for (var i = 0; i < _filas.length; i++) _filaSegmento(i),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _agregar,
            icon: const Icon(Icons.add),
            label: const Text('Agregar segmento'),
          ),
        ),
        ..._opciones(),
        FilledButton(onPressed: _disenar, child: const Text('Diseñar')),
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: _hueco),
            child: Text(error, style: TextStyle(color: tema.colorScheme.error)),
          ),
      ],
    );
  }

  Widget _campo(TextEditingController c, String etiqueta, {Key? key}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: _hueco),
        child: TextField(
          key: key,
          controller: c,
          decoration: InputDecoration(labelText: etiqueta),
        ),
      );

  Widget _filaSegmento(int i) {
    final (nombre, hosts) = _filas[i];
    final n = i + 1;
    return Row(
      key: ObjectKey(nombre),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _campo(nombre, 'Nombre', key: ValueKey('segmento_nombre_$n')),
        ),
        for (var j = 0; j < _n; j++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: _hueco),
              child: _campo(
                hosts[j],
                _n == 1 ? 'Hosts' : 'SW${j + 1}',
                key: ValueKey(
                  j == 0
                      ? 'segmento_hosts_$n'
                      : 'segmento_hosts_${n}_sw${j + 1}',
                ),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Quitar segmento $n',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _quitar(i),
        ),
      ],
    );
  }

  /// Topología y, en router-on-a-stick, cuántos switches y cómo se conectan.
  List<Widget> _equipos(ThemeData tema) => [
    Text('Topología', style: tema.textTheme.titleSmall),
    _selector<Topologia>(_topologia, const {
      Topologia.routerOnAStick: 'Router-on-a-stick',
      Topologia.switchCapa3: 'Switch capa 3',
    }, (v) => _topologia = v),
    if (_topologia == Topologia.routerOnAStick) ...[
      Text('Switches', style: tema.textTheme.titleSmall),
      _selector<int>(_switches, const {
        1: '1 switch',
        2: '2 switches',
        3: '3 switches',
      }, (v) => _switches = v),
    ],
    if (_n > 1) ...[
      Text('Conexión', style: tema.textTheme.titleSmall),
      _selector<Conexion>(_conexion, const {
        Conexion.alRouter: 'Cada uno al router',
        Conexion.enCadena: 'En cadena',
        Conexion.ambos: 'Ambos',
      }, (v) => _conexion = v),
    ],
  ];

  Widget _selector<T>(
    T valor,
    Map<T, String> opciones,
    void Function(T) elegir,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: _hueco),
    child: SegmentedButton<T>(
      segments: [
        for (final MapEntry(:key, :value) in opciones.entries)
          ButtonSegment(value: key, label: Text(value)),
      ],
      selected: {valor},
      onSelectionChanged: (s) => setState(() => elegir(s.first)),
    ),
  );

  List<Widget> _opciones() => [
    _campo(_reservadas, 'IPs reservadas por segmento'),
    _campo(_crecimiento, 'Crecimiento previsto (%)'),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Gateway en la última IP útil'),
      value: _gatewayAlFinal,
      onChanged: (v) => setState(() => _gatewayAlFinal = v),
    ),
    _campo(_dns, 'DNS'),
    _campo(_dominio, 'Dominio'),
    _campo(_clave, 'Clave de enable (opcional)'),
  ];
}
