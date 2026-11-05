/// Lectura de `show ip route` de IOS (SPEC-004 T3): cada ruta con su código,
/// su red y su siguiente salto.
library;

import 'ip.dart';

/// Una línea de la tabla: código (C, L, S, O…), red y `via` (si lo trae).
class EntradaTabla {
  const EntradaTabla(this.codigo, this.base, this.prefijo, this.via);
  final String codigo;
  final int base;
  final int prefijo;
  final String? via;
}

final _reEncabezado = RegExp(r'^\d+\.\d+\.\d+\.\d+/(\d+) is (variably )?subnetted');
final _reEntrada = RegExp(
  r'^([A-Z]{1,2})\*?(?:\s+(?:IA|E1|E2|N1|N2))?\s+(\d+\.\d+\.\d+\.\d+)(?:/(\d+))?\s+'
  r'(?:\[\d+/\d+\]\s+via\s+(\d+\.\d+\.\d+\.\d+)|is directly connected)',
);

/// Las rutas de [texto]. Una red sin `/p` toma la máscara de la línea
/// "`<red>/<p> is subnetted`" de arriba; sin ella, la línea no se cuenta.
List<EntradaTabla> leerTabla(String texto) {
  final entradas = <EntradaTabla>[];
  int? mascaraComun;
  for (final cruda in texto.split('\n')) {
    final linea = cruda.trim();
    if (_reEncabezado.firstMatch(linea) case final m?) {
      mascaraComun = m[2] == null ? int.parse(m[1]!) : null;
    } else if (_entrada(linea, mascaraComun) case final e?) {
      entradas.add(e);
    }
  }
  return entradas;
}

EntradaTabla? _entrada(String linea, int? mascaraComun) {
  final m = _reEntrada.firstMatch(linea);
  final prefijo = m == null ? null : (m[3] == null ? mascaraComun : int.parse(m[3]!));
  return prefijo == null ? null : EntradaTabla(m![1]!, ipANumero(m[2]!)!, prefijo, m[4]);
}
