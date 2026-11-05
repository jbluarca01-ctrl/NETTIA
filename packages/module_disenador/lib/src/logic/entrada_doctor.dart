/// Lo que se pega en Auditar con varios routers (SPEC-004 T4): se corta en
/// bloques (running-config o `show ip route`), se reconoce de qué equipo es
/// cada uno y se revisa contra el diseño.
library;

import 'auditor.dart';
import 'doctor_rutas.dart';
import 'formulario.dart';
import 'ip.dart';
import 'lectura_config.dart';
import 'tabla_rutas.dart';

/// Lo que dijo el doctor: los hallazgos de cada bloque (con su título) y los
/// del camino entre sedes.
class ResultadoDoctor {
  const ResultadoDoctor(this.bloques, this.camino);
  final List<(String, List<Hallazgo>)> bloques;

  /// `null` si no se pegó la running-config de ningún router.
  final List<Hallazgo>? camino;

  /// Ningún bloque ni el camino tienen hallazgos.
  bool get sinDiferencias => bloques.every((b) => b.$2.isEmpty) && (camino?.isEmpty ?? true);
}

final _rePrompt = RegExp(r'^(\S+?)[#>]\s*(?:sh|show)\b', caseSensitive: false);

/// Una línea que ya hace útil al bloque: no es solo un prompt ni un aviso
/// de IOS.
bool _util(String linea) {
  final l = linea.trim();
  return l.startsWith('hostname ') || l.startsWith('interface ') || l.startsWith('Gateway of last resort') || leerTabla(l).isNotEmpty;
}

/// Corta [texto] en bloques: en cada prompt con `show`, en cada `Building
/// configuration` y en cada `hostname` repetido, siempre que el bloque en
/// curso ya tenga algo útil.
List<String> separarBloques(String texto) {
  final bloques = <List<String>>[[]];
  for (final linea in texto.split('\n')) {
    if (_empieza(linea.trim(), bloques.last)) bloques.add([]);
    bloques.last.add(linea);
  }
  return [
    for (final b in bloques)
      if (b.any(_util)) b.join('\n'),
  ];
}

bool _empieza(String l, List<String> actual) {
  final corte = _rePrompt.hasMatch(l) ||
      l.startsWith('Building configuration') ||
      (l.startsWith('hostname ') && actual.any((x) => x.trim().startsWith('hostname ')));
  return corte && actual.any(_util);
}

/// Revisa lo pegado en [texto] contra [d] (con varios routers) en [modo].
ResultadoDoctor revisarRed(String texto, Diseno d, ModoRutas modo) {
  final red = d.red!;
  final pegados = <int, ConfigLeida>{};
  final bloques = [
    for (final (n, b) in separarBloques(texto).indexed) _revisarBloque(b, n + 1, d, modo, pegados),
  ];
  return ResultadoDoctor(bloques, pegados.isEmpty ? null : diagnosticarCamino(pegados, red, modo));
}

(String, List<Hallazgo>) _revisarBloque(String b, int n, Diseno d, ModoRutas modo, Map<int, ConfigLeida> pegados) {
  final esConfig = b.split('\n').any((l) => l.trim().startsWith('hostname ') || l.trim().startsWith('interface '));
  return esConfig ? _revisarConfig(b, leerConfig(b), n, d, modo, pegados) : _revisarTabla(b, n, d);
}

const _noReconocido = Hallazgo(Gravedad.aviso, 'No se reconoció de qué equipo es este bloque.', []);

(String, List<Hallazgo>) _revisarConfig(String b, ConfigLeida c, int n, Diseno d, ModoRutas modo, Map<int, ConfigLeida> pegados) {
  final equipo = _equipoDeConfig(c, d);
  if (equipo == null) return ('Bloque $n', const [_noReconocido]);
  final (nombre, sede) = equipo;
  final hallazgos = [...auditarConfig(b, d.red!.sedes[sede])];
  if (nombre == 'R${sede + 1}') {
    pegados[sede] = c;
    final esperada = leerConfig(d.equipos.singleWhere((e) => e.hostname == nombre).texto);
    hallazgos.addAll(diagnosticarRouter(c, esperada, sede, d.red!, modo));
  }
  return ('$nombre · running-config', hallazgos);
}

(String, List<Hallazgo>) _revisarTabla(String b, int n, Diseno d) {
  final tabla = leerTabla(b);
  final router = _routerDeTabla(b, tabla, d);
  if (router == null) return ('Bloque $n', const [_noReconocido]);
  return ('R${router + 1} · show ip route', diagnosticarTabla(tabla, router, d.red!));
}

/// (hostname, sede) del equipo de [c]: por su `hostname` si es del diseño
/// o, si no, el router cuyos gateways o enlaces tiene.
(String, int)? _equipoDeConfig(ConfigLeida c, Diseno d) {
  final hostname = valorDe(c.globales, 'hostname ');
  if (d.sedeDe[hostname] case final sede?) return (hostname!, sede);
  final ips = {
    for (final ls in c.interfaces.values)
      if (valorDe(ls, 'ip address ') case final ip?) ip.split(' ').first,
  };
  final sede = _sedePorIps(ips, d);
  return sede == null ? null : ('R${sede + 1}', sede);
}

/// La sede cuyo router tiene alguna de las [ips] (gateway o enlace).
int? _sedePorIps(Set<String> ips, Diseno d) {
  final red = d.red!;
  for (var k = 0; k < red.sedes.length; k++) {
    final propias = {
      for (final s in red.sedes[k].segmentos) s.gateway,
      for (final e in red.enlacesDe(k)) e.desde == k ? e.ipDesde : e.ipHasta,
    };
    if (propias.any(ips.contains)) return k;
  }
  return null;
}

/// El router de una tabla: por el prompt (`R2#show ip route`) o por sus
/// redes conectadas.
int? _routerDeTabla(String b, List<EntradaTabla> tabla, Diseno d) {
  final prompt = _rePrompt.firstMatch(b.trimLeft())?[1];
  if (d.sedeDe[prompt] case final sede? when prompt == 'R${sede + 1}') return sede;
  final conectadas = {
    for (final e in tabla)
      if (e.codigo == 'C') e.base,
  };
  final red = d.red!;
  for (var k = 0; k < red.sedes.length; k++) {
    if (red.sedes[k].segmentos.any((s) => conectadas.contains(ipANumero(s.red)))) return k;
  }
  return null;
}
