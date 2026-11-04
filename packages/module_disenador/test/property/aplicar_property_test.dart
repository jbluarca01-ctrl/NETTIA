import 'dart:math';

import 'package:flutter_test/flutter_test.dart' hide test, group;
import 'package:kiri_check/kiri_check.dart';
import 'package:module_disenador/src/logic/aplicar.dart';
import 'package:module_disenador/src/logic/auditor.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/repara.dart';

/// La línea `interface …` que está justo antes de [siguiente] en [c].
String _interfazAntesDe(ConfigEquipo c, String siguiente) => c.lineas[c.lineas.indexOf(siguiente) - 1];

/// Los comandos que arreglan [f] en [s], como los escribiría el estudiante.
List<String> _arreglo(TipoFalla f, SegmentoPlan s, PlanRed plan, ConfigEquipo sw, ConfigEquipo r1) {
  final fisica = r1.lineas.firstWhere((l) => l.startsWith('interface ')).substring(10);
  final sub = 'interface $fisica.${s.vlan}';
  final troncal = _interfazAntesDe(sw, sw.lineas.firstWhere((l) => l.startsWith(' description TRONCAL')));
  final ip = 'ip address ${s.gateway} ${s.mascara}';
  final pool = 'ip dhcp pool ${nombreIos(s.nombre)}';
  return switch (f) {
    TipoFalla.fisicaApagada => ['interface $fisica', 'no shutdown'],
    TipoFalla.subinterfazApagada => [sub, 'no shutdown'],
    TipoFalla.mascaraGateway || TipoFalla.gatewayEquivocado => [sub, ip],
    TipoFalla.sinEncapsulacion => [sub, 'encapsulation dot1Q ${s.vlan}'],
    TipoFalla.sinDefaultRouter || TipoFalla.defaultRouterEquivocado => [pool, 'default-router ${s.gateway}'],
    TipoFalla.sinPool => [pool, 'network ${s.red} ${s.mascara}', 'default-router ${s.gateway}'],
    TipoFalla.gatewayNoExcluido => ['ip dhcp excluded-address ${s.gateway}'],
    TipoFalla.puertoOtraVlan => [_interfazAntesDe(sw, ' description ${s.nombre}'), 'switchport access vlan ${s.vlan}'],
    TipoFalla.troncalSinVlan => [troncal, 'switchport trunk allowed vlan add ${s.vlan}'],
    TipoFalla.nativaDistinta => [troncal, 'switchport trunk native vlan ${plan.opciones.vlanNativa}'],
  };
}

const _comandos = [
  'interface GigabitEthernet0/1',
  'int g0/0/0',
  'no shutdown',
  'shutdown',
  'ip address 10.0.0.1 255.255.255.0',
  'switchport trunk allowed vlan add 7',
  'ip dhcp pool OTRO',
  'default-router 10.0.0.1',
  'exit',
  'router rip',
  'ip dhcp excluded-address 10.0.0.1',
];

void main() {
  property('toda falla se arregla escribiendo sus comandos en su equipo (SPEC-002-RF5)', () {
    forAll(integer(min: 0, max: 1 << 30), (semilla) {
      final plan = planAlAzar(Random(semilla));
      final limpia = generarConfiguracion(plan, const OpcionesConfig());
      for (final falla in TipoFalla.values) {
        for (final s in plan.segmentos) {
          final configs = inyectarFalla(limpia, plan, falla, s);
          final [sw, r1] = configs;
          final equipo = configs.singleWhere((c) => c.hostname == equipoDe(falla));
          final r = aplicarComandos(equipo, _arreglo(falla, s, plan, sw, r1).join('\n'));
          expect(r.noReconocidos, isEmpty, reason: '$falla ${s.nombre}');
          expect(auditarConfig(r.config.texto, plan), isEmpty, reason: '$falla ${s.nombre}');
        }
      }
    });
  });

  property('aplicar dos veces los mismos comandos da lo mismo que una (SPEC-002-RF2)', () {
    forAll(combine2(integer(min: 0, max: 1 << 30), list(constantFrom(_comandos), maxLength: 12)), (entrada) {
      final (semilla, comandos) = entrada;
      for (final c in generarConfiguracion(planAlAzar(Random(semilla)), const OpcionesConfig())) {
        final texto = comandos.join('\n');
        final una = aplicarComandos(c, texto).config;
        expect(aplicarComandos(una, texto).config.lineas, una.lineas);
      }
    });
  });

  property('solo comandos no reconocidos no cambian la configuración (SPEC-002-RF4)', () {
    forAll(combine2(integer(min: 0, max: 1 << 30), list(constantFrom(['router rip', 'vlan 5', 'no shutdown', 'name X']), maxLength: 6)), (entrada) {
      final (semilla, comandos) = entrada;
      for (final c in generarConfiguracion(planAlAzar(Random(semilla)), const OpcionesConfig())) {
        final r = aplicarComandos(c, comandos.join('\n'));
        expect(r.config.lineas, c.lineas);
        expect(r.noReconocidos, comandos);
      }
    });
  });

  property('la configuración aplicada sigue el formato del Diseñador (SPEC-002-RF3)', () {
    forAll(combine2(integer(min: 0, max: 1 << 30), list(constantFrom(_comandos), maxLength: 12)), (entrada) {
      final (semilla, comandos) = entrada;
      for (final c in generarConfiguracion(planAlAzar(Random(semilla)), const OpcionesConfig())) {
        final lineas = aplicarComandos(c, comandos.join('\n')).config.lineas;
        expect(lineas.sublist(lineas.length - 2), ['end', 'write memory']);
        for (var i = 0; i < lineas.length; i++) {
          if (lineas[i].startsWith('interface ') || lineas[i].startsWith('ip dhcp pool ')) {
            final fin = lineas.indexWhere((l) => !l.startsWith(' '), i + 1);
            expect(lineas[fin], 'exit', reason: lineas[i]);
          }
        }
      }
    });
  });
}
