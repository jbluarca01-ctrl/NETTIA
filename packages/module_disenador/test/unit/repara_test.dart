import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/repara.dart';

PlanRed _plan() => planificarRed('192.168.10.0', 24, const [
  Segmento('VENTAS', 50),
  Segmento('TI', 20),
  Segmento('RRHH', 10),
], const OpcionesPlan());

void main() {
  group('equipoDe', () {
    test('las fallas de switch van a SW1 y el resto a R1', () {
      const deSwitch = {TipoFalla.puertoOtraVlan, TipoFalla.troncalSinVlan, TipoFalla.nativaDistinta};
      for (final f in TipoFalla.values) {
        expect(equipoDe(f), deSwitch.contains(f) ? 'SW1' : 'R1', reason: '$f');
      }
    });
  });

  group('inyectarFalla', () {
    test('no modifica la configuración original y cambia solo el equipo afectado', () {
      final plan = _plan();
      final limpia = generarConfiguracion(plan, const OpcionesConfig());
      final antes = [for (final c in limpia) c.texto];
      final ti = plan.segmentos[1];
      final con = inyectarFalla(limpia, plan, TipoFalla.sinPool, ti);
      expect([for (final c in limpia) c.texto], antes);
      expect(con.singleWhere((c) => c.hostname == 'SW1').texto, limpia.singleWhere((c) => c.hostname == 'SW1').texto);
      expect(con.singleWhere((c) => c.hostname == 'R1').texto, isNot(contains('ip dhcp pool TI')));
      expect(con.singleWhere((c) => c.hostname == 'R1').texto, contains('ip dhcp pool RRHH'));
    });

    test('el puerto en otra VLAN usa la del segmento siguiente (el último usa el primero)', () {
      final plan = _plan();
      final limpia = generarConfiguracion(plan, const OpcionesConfig());
      final ultimo = plan.segmentos.last;
      final sw = inyectarFalla(limpia, plan, TipoFalla.puertoOtraVlan, ultimo).singleWhere((c) => c.hostname == 'SW1');
      final i = sw.lineas.indexOf(' description ${ultimo.nombre}');
      expect(sw.lineas.sublist(i, i + 3), [
        ' description ${ultimo.nombre}',
        ' switchport mode access',
        ' switchport access vlan ${plan.segmentos.first.vlan}',
      ]);
      expect(sintomaDe(TipoFalla.puertoOtraVlan, ultimo, plan), contains('de la red de VENTAS (192.168.10.0/26)'));
    });

    test('una configuración que no es la del Diseñador no se puede alterar', () {
      final plan = _plan();
      expect(
        () => inyectarFalla([const ConfigEquipo('R1', ['hostname R1'])], plan, TipoFalla.sinPool, plan.segmentos[0]),
        throwsA(isA<StateError>().having((e) => e.message, 'mensaje', 'no se encontró "ip dhcp pool VENTAS"')),
      );
    });

    test('la máscara equivocada es la del prefijo siguiente', () {
      final plan = _plan();
      final rrhh = plan.segmentos.last; // /28
      final r1 = inyectarFalla(generarConfiguracion(plan, const OpcionesConfig()), plan, TipoFalla.mascaraGateway, rrhh)
          .singleWhere((c) => c.hostname == 'R1');
      expect(r1.lineas, contains(' ip address ${rrhh.gateway} 255.255.255.248'));
    });
  });

  group('armarEjercicio y responder', () {
    test('4 causas: la correcta y 3 de otras fallas; acertar y fallar', () {
      final plan = _plan();
      final e = armarEjercicio(plan, TipoFalla.troncalSinVlan, plan.segmentos[0], Random(3));
      expect(e.causas, hasLength(4));
      expect(e.causas.where((c) => c == causaDe(TipoFalla.troncalSinVlan)), hasLength(1));
      expect(e.causas[e.indiceCorrecta], causaDe(TipoFalla.troncalSinVlan));
      final otra = (e.indiceCorrecta + 1) % 4;
      final mal = e.responder(otra);
      expect(mal.acierto, isFalse);
      expect(mal.elegida, otra);
      expect(mal.causaCorrecta, causaDe(TipoFalla.troncalSinVlan));
      expect([for (final h in mal.hallazgos) h.mensaje], ['GigabitEthernet0/1: el troncal no permite la VLAN 10 (VENTAS).']);
      expect(e.responder(e.indiceCorrecta).acierto, isTrue);
      expect(e.equipo, 'SW1');
    });

    test('semillas distintas cambian el orden de las causas', () {
      final plan = _plan();
      final ordenes = {
        for (var s = 0; s < 20; s++) armarEjercicio(plan, TipoFalla.sinPool, plan.segmentos[0], Random(s)).causas.join('|'),
      };
      expect(ordenes.length, greaterThan(1));
    });

    test('planAlAzar usa los 6 nombres y todas las redes 192.168.1–254.0', () {
      final nombres = <String>{};
      final octetos = <int>{};
      for (var s = 0; s < 4000; s++) {
        final plan = planAlAzar(Random(s));
        nombres.addAll([for (final g in plan.segmentos) g.nombre]);
        octetos.add(int.parse(plan.segmentos.first.red.split('.')[2]));
      }
      expect(nombres, {'VENTAS', 'TI', 'RRHH', 'BODEGA', 'GERENCIA', 'SOPORTE'});
      expect(octetos, {for (var o = 1; o <= 254; o++) o});
    });

    test('ejercicioAlAzar recorre fallas distintas', () {
      final fallas = {for (var s = 0; s < 60; s++) ejercicioAlAzar(Random(s)).falla};
      expect(fallas.length, greaterThan(6));
    });
  });
}
