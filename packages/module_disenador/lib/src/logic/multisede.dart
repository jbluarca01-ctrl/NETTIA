/// Red con varios routers (SPEC-003 T1): cada sede (un [PlanRed]) tiene su
/// router Rk; los routers van en cadena (R1–R2–…–Rn) unidos por enlaces /30
/// tomados de la red de enlaces, y se enrutan con estáticas resumidas, por
/// subred u OSPF.
library;

import 'ip.dart';
import 'plan_red.dart';

/// Cómo aprenden los routers las redes de las otras sedes.
enum Enrutamiento { estaticaResumida, estaticaPorSubred, ospf }

/// Enlace /30 entre el router [desde] (desde 0) y el siguiente de la cadena.
class Enlace {
  const Enlace(this.desde, this.red, this.ipDesde, this.ipHasta);
  final int desde;
  final String red;
  final String ipDesde;
  final String ipHasta;

  static const mascara = '255.255.255.252';
  static const wildcard = '0.0.0.3';
}

/// Una ruta estática: `ip route <red> <mascara> <siguienteSalto>`.
class Ruta {
  const Ruta(this.red, this.mascara, this.siguienteSalto);
  final String red;
  final String mascara;
  final String siguienteSalto;
}

class RedMultisede {
  const RedMultisede(this.sedes, this.enlaces, this.enrutamiento, this.rutas);

  /// Una por router, en orden (la sede k es la de Rk).
  final List<PlanRed> sedes;
  final List<Enlace> enlaces;
  final Enrutamiento enrutamiento;

  /// Rutas estáticas de cada router; vacías con OSPF.
  final List<List<Ruta>> rutas;

  /// Enlaces del router [i]: primero el del anterior, después el del
  /// siguiente.
  List<Enlace> enlacesDe(int i) => [
    for (final e in enlaces)
      if (e.desde == i - 1 || e.desde == i) e,
  ];

  /// Redes que el router [i] anuncia con OSPF, como `red wildcard`: sus
  /// segmentos y sus enlaces.
  List<String> redesOspf(int i) => [
    for (final s in sedes[i].segmentos) '${s.red} ${s.wildcard}',
    for (final e in enlacesDe(i)) '${e.red} ${Enlace.wildcard}',
  ];
}

/// Router-id OSPF del router [i] (desde 0): R1 → 1.1.1.1.
String routerId(int i) => List.filled(4, '${i + 1}').join('.');

const _pideEnlaces = 'Escribe la red de los enlaces entre routers, p. ej. 10.0.0.0/30.';

/// Planifica la red de [sedes] (2 o más) con los enlaces de [redEnlaces].
/// Lanza [DisenoException] si la red de enlaces no sirve o algo se solapa.
RedMultisede planificarMultisede(List<PlanRed> sedes, String? redEnlaces, Enrutamiento enrutamiento) {
  final (base, prefijo) = _leerEnlaces(redEnlaces);
  final enlaces = _enlaces(base, prefijo, sedes.length - 1);
  _validarSolapes(sedes, _Bloque(base, _tamano(prefijo)));
  return RedMultisede(sedes, enlaces, enrutamiento, [
    for (var i = 0; i < sedes.length; i++)
      if (enrutamiento == Enrutamiento.ospf) const [] else _rutas(sedes, enlaces, i, enrutamiento),
  ]);
}

int _tamano(int prefijo) => 1 << (32 - prefijo);

int _mascara(int prefijo) => (0xFFFFFFFF << (32 - prefijo)) & 0xFFFFFFFF;

(int, int) _leerEnlaces(String? texto) {
  final (ip, prefijo) = _partesEnlaces(texto);
  if (ip == null || prefijo == null) {
    throw const DisenoException(_pideEnlaces);
  }
  final red = ip & _mascara(prefijo);
  if (red != ip) {
    throw DisenoException('${texto!.trim()} no es una dirección de red: usa ${ipATexto(red)}/$prefijo.');
  }
  return (red, prefijo);
}

/// Los [n] enlaces /30, en orden, desde [base].
List<Enlace> _enlaces(int base, int prefijo, int n) {
  if (_tamano(prefijo) < 4 * n) {
    throw DisenoException('La red de enlaces ${ipATexto(base)}/$prefijo no alcanza: se necesitan $n enlaces /30.');
  }
  return [
    for (var k = 0; k < n; k++) Enlace(k, ipATexto(base + 4 * k), ipATexto(base + 4 * k + 1), ipATexto(base + 4 * k + 2)),
  ];
}

/// Bloque de [tamano] direcciones desde [base].
class _Bloque {
  const _Bloque(this.base, this.tamano);
  _Bloque.de(PlanRed p) : this(ipANumero(p.redBase)!, _tamano(p.cidrBase));
  final int base;
  final int tamano;

  bool seSolapaCon(_Bloque otro) => base < otro.base + otro.tamano && otro.base < base + tamano;
}

void _validarSolapes(List<PlanRed> sedes, _Bloque enlaces) {
  for (var i = 0; i < sedes.length; i++) {
    if (_Bloque.de(sedes[i]).seSolapaCon(enlaces)) {
      throw DisenoException('La red de enlaces se solapa con la sede ${i + 1}.');
    }
    for (var j = i + 1; j < sedes.length; j++) {
      if (_Bloque.de(sedes[i]).seSolapaCon(_Bloque.de(sedes[j]))) {
        throw DisenoException('Las redes de la sede ${i + 1} y la sede ${j + 1} se solapan.');
      }
    }
  }
}

/// El prefijo más corto que cubre todos los segmentos de [sede]: (red,
/// prefijo). [planificarRed] los asigna en orden de dirección, así que van
/// del primero al último.
(String, int) resumenDe(PlanRed sede) {
  final desde = ipANumero(sede.segmentos.first.red)!;
  final hasta = ipANumero(sede.segmentos.last.broadcast)!;
  final prefijo = 32 - (desde ^ hasta).bitLength;
  return (ipATexto(desde & _mascara(prefijo)), prefijo);
}

List<Ruta> _rutas(List<PlanRed> sedes, List<Enlace> enlaces, int i, Enrutamiento e) => [
  // Las sedes anteriores, por el vecino de atrás; las siguientes, por el de
  // adelante.
  for (var j = 0; j < i; j++) ..._rutasHacia(sedes[j], enlaces[i - 1].ipDesde, e),
  for (var j = i + 1; j < sedes.length; j++) ..._rutasHacia(sedes[j], enlaces[i].ipHasta, e),
];

List<Ruta> _rutasHacia(PlanRed sede, String salto, Enrutamiento e) {
  if (e == Enrutamiento.estaticaPorSubred) {
    return [for (final s in sede.segmentos) Ruta(s.red, s.mascara, salto)];
  }
  final (red, prefijo) = resumenDe(sede);
  return [Ruta(red, ipATexto(_mascara(prefijo)), salto)];
}

/// La IP y el prefijo de `red/prefijo`; `null` en lo que falte o no sirva.
(int?, int?) _partesEnlaces(String? texto) {
  final partes = texto?.trim().split('/') ?? const <String>[];
  if (partes.length != 2) return (null, null);
  return (ipANumero(partes.first), _prefijo(partes[1]));
}

/// El prefijo de [texto] si es un número de 1 a 32; si no, `null`.
int? _prefijo(String texto) {
  final p = int.tryParse(texto.trim());
  return p != null && p >= 1 && p <= 32 ? p : null;
}
