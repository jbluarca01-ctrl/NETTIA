/// Ejercicio de "Repara la red" (SPEC-001 T1): un plan al azar con una falla,
/// su síntoma y 4 causas posibles; al responder, el diagnóstico del auditor.
library;

import 'dart:math';

import 'auditor.dart';
import 'fallas.dart';
import 'generador.dart';
import 'plan_red.dart';

const _nombres = ['VENTAS', 'TI', 'RRHH', 'BODEGA', 'GERENCIA', 'SOPORTE'];

/// 2 o 3 segmentos de nombres distintos y 5 a 60 hosts en 192.168.N.0/24.
PlanRed planAlAzar(Random rnd) {
  final nombres = [..._nombres]..shuffle(rnd);
  return planificarRed('192.168.${1 + rnd.nextInt(254)}.0', 24, [
    for (final n in nombres.take(2 + rnd.nextInt(2))) Segmento(n, 5 + rnd.nextInt(56)),
  ], const OpcionesPlan());
}

/// Resultado de elegir la causa [elegida].
class ResultadoRepara {
  const ResultadoRepara({
    required this.elegida,
    required this.acierto,
    required this.causaCorrecta,
    required this.hallazgos,
  });

  final int elegida;
  final bool acierto;
  final String causaCorrecta;

  /// Lo que reporta el auditor en el equipo con la falla.
  final List<Hallazgo> hallazgos;
}

class EjercicioRepara {
  const EjercicioRepara({
    required this.plan,
    required this.configs,
    required this.falla,
    required this.segmento,
    required this.sintoma,
    required this.causas,
    required this.indiceCorrecta,
  });

  final PlanRed plan;

  /// Configuración de SW1 y R1, con la falla.
  final List<ConfigEquipo> configs;
  final TipoFalla falla;
  final SegmentoPlan segmento;
  final String sintoma;
  final List<String> causas;
  final int indiceCorrecta;

  /// Hostname del equipo con la falla.
  String get equipo => equipoDe(falla);

  ResultadoRepara responder(int elegida) => ResultadoRepara(
    elegida: elegida,
    acierto: elegida == indiceCorrecta,
    causaCorrecta: causas[indiceCorrecta],
    hallazgos: auditarConfig(configs.singleWhere((c) => c.hostname == equipo).texto, plan),
  );
}

/// Ejercicio con la falla [falla] en [segmento] de [plan]; [rnd] elige las 3
/// causas incorrectas y el orden.
EjercicioRepara armarEjercicio(PlanRed plan, TipoFalla falla, SegmentoPlan segmento, Random rnd) {
  final otras = [for (final f in TipoFalla.values) if (f != falla) f]..shuffle(rnd);
  final causas = [for (final f in [falla, ...otras.take(3)]) causaDe(f)]..shuffle(rnd);
  return EjercicioRepara(
    plan: plan,
    configs: inyectarFalla(generarConfiguracion(plan, const OpcionesConfig()), plan, falla, segmento),
    falla: falla,
    segmento: segmento,
    sintoma: sintomaDe(falla, segmento, plan),
    causas: causas,
    indiceCorrecta: causas.indexOf(causaDe(falla)),
  );
}

/// Ejercicio completo al azar: plan, falla y segmento.
EjercicioRepara ejercicioAlAzar(Random rnd) {
  final plan = planAlAzar(rnd);
  final falla = TipoFalla.values[rnd.nextInt(TipoFalla.values.length)];
  final segmento = plan.segmentos[rnd.nextInt(plan.segmentos.length)];
  return armarEjercicio(plan, falla, segmento, rnd);
}
