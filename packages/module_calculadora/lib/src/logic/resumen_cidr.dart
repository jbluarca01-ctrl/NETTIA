/// Revisión de una ruta resumen CIDR con las cinco preguntas de la Clase 18:
/// mismo salto, contiguas, potencia de dos, alineadas y rango cubierto. Solo
/// aritmética entera, como conversiones.dart.
library;

import 'conversiones.dart';

/// Si la ruta resumen se puede anunciar.
enum Veredicto { valido, condicional, noValido }

/// Resumen de [sumarizarRedes] más lo que hay que revisar antes de anunciarlo.
class RevisionResumen {
  const RevisionResumen({
    required this.resumen,
    required this.cubierto,
    required this.faltantes,
    required this.sobrantes,
    required this.veredicto,
    required this.preguntas,
  });

  final ResultadoSumarizacion resumen;

  /// Primera – última dirección que abarca la ruta resumen.
  final String cubierto;

  /// Lo que falta entre las redes dadas (red/n o rango).
  final List<String> faltantes;

  /// Lo que el resumen abarca de más en los extremos (red/n o rango).
  final List<String> sobrantes;

  final Veredicto veredicto;

  /// Las cinco preguntas respondidas, y un aviso si hay redes solapadas.
  final List<String> preguntas;

  String get textoVeredicto => switch (veredicto) {
        Veredicto.valido => 'Válido: cubre exactamente las redes dadas.',
        Veredicto.condicional =>
          'Válido solo si estas direcciones también van a ese router o están '
              'libres: ${sobrantes.join(', ')}.',
        Veredicto.noValido =>
          'No válido: falta ${faltantes.join(', ')} entre las redes; el '
              'resumen le enviaría ese tráfico al mismo salto.',
      };
}

int _potencia(int k) {
  var v = 1;
  for (var i = 0; i < k; i++) {
    v *= 2;
  }
  return v;
}

/// Menor k con 2^k >= [n].
int _bits(int n) {
  var k = 0;
  while (_potencia(k) < n) {
    k++;
  }
  return k;
}

bool _esPotencia(int n) => _potencia(_bits(n)) == n;

/// Direcciones [ini] a [fin] como red/n si forman un bloque CIDR exacto.
String _tramo(int ini, int fin) {
  final tam = fin - ini + 1;
  if (_esPotencia(tam) && ini % tam == 0) {
    return '${ipATexto(ini)}/${32 - _bits(tam)}';
  }
  return '${ipATexto(ini)} – ${ipATexto(fin)}';
}

/// Primera y última dirección de la ruta resumen.
(int, int) _extremos(ResultadoSumarizacion r) {
  final ini = ipDesdeTexto(r.red)!;
  return (ini, ini + _potencia(32 - r.prefijo) - 1);
}

/// Orden por inicio y, con el mismo inicio, la red más grande primero.
int _porInicio((int, int) a, (int, int) b) =>
    a.$1 != b.$1 ? a.$1.compareTo(b.$1) : b.$2.compareTo(a.$2);

/// Las redes ordenadas y unidas en tramos contiguos, y si alguna se solapa.
/// Dos redes CIDR o están una dentro de la otra o no se tocan: con
/// [_porInicio], una red que empieza dentro del tramo cabe entera en él.
(List<(int, int)>, bool) _unir(List<String> redes) {
  final rangos = redes.map(rangoDeRed).toList()..sort(_porInicio);
  final tramos = <(int, int)>[rangos.first];
  var solapan = false;
  for (final (ini, fin) in rangos.skip(1)) {
    final (tIni, tFin) = tramos.last;
    if (ini <= tFin) {
      solapan = true;
    } else if (ini == tFin + 1) {
      tramos.last = (tIni, fin);
    } else {
      tramos.add((ini, fin));
    }
  }
  return (tramos, solapan);
}

List<String> _huecos(List<(int, int)> tramos) {
  final huecos = <String>[];
  for (var i = 1; i < tramos.length; i++) {
    huecos.add(_tramo(tramos[i - 1].$2 + 1, tramos[i].$1 - 1));
  }
  return huecos;
}

List<String> _preguntas(
  ResultadoSumarizacion r,
  List<(int, int)> tramos,
  List<String> faltantes,
  bool solapan,
) {
  final (ini, fin) = _extremos(r);
  final suma = tramos.fold(0, (s, t) => s + t.$2 - t.$1 + 1);
  final primero = ipATexto(tramos.first.$1);
  return <String>[
    '1. Mismo salto: compruebe que todas van al mismo router (siguiente salto).',
    faltantes.isEmpty
        ? '2. Contiguas: sí, no falta ningún bloque entre ellas.'
        : '2. Contiguas: no, falta ${faltantes.join(', ')}.',
    '3. Potencia de dos: ${_esPotencia(suma) ? 'sí' : 'no'}, suman $suma '
        'direcciones.',
    tramos.first.$1 == ini
        ? '4. Alineadas: sí, empiezan en $primero, inicio del bloque '
            '/${r.prefijo}.'
        : '4. Alineadas: no, empiezan en $primero pero el bloque '
            '/${r.prefijo} empieza en ${ipATexto(ini)}.',
    '5. Rango cubierto: ${ipATexto(ini)} – ${ipATexto(fin)} '
        '(${fin - ini + 1} direcciones).',
    if (solapan) 'Aviso: algunas redes se solapan entre sí.',
  ];
}

/// Revisa la ruta resumen de [redes] ("a.b.c.d/n"): qué cubre, qué falta
/// entre ellas, qué sobra y si se puede anunciar.
RevisionResumen revisarResumen(List<String> redes) {
  final resumen = sumarizarRedes(redes);
  final (tramos, solapan) = _unir(redes);
  final (ini, fin) = _extremos(resumen);
  final primero = tramos.first.$1;
  final ultimo = tramos.last.$2;
  final faltantes = _huecos(tramos);
  final sobrantes = <String>[
    if (ini < primero) _tramo(ini, primero - 1),
    if (ultimo < fin) _tramo(ultimo + 1, fin),
  ];
  return RevisionResumen(
    resumen: resumen,
    cubierto: '${ipATexto(ini)} – ${ipATexto(fin)}',
    faltantes: faltantes,
    sobrantes: sobrantes,
    veredicto: faltantes.isNotEmpty
        ? Veredicto.noValido
        : (sobrantes.isNotEmpty ? Veredicto.condicional : Veredicto.valido),
    preguntas: _preguntas(resumen, tramos, faltantes, solapan),
  );
}

/// Comando IOS de la ruta estática resumen hacia [salto]; sin salto deja el
/// marcador "[siguiente salto]".
String comandoResumen(ResultadoSumarizacion r, String salto) {
  final s = salto.trim();
  if (s.isNotEmpty && ipDesdeTexto(s) == null) {
    throw ConversionException('Siguiente salto inválido: $s (usa a.b.c.d).');
  }
  return 'ip route ${r.red} ${r.mascara} ${s.isEmpty ? '[siguiente salto]' : s}';
}
