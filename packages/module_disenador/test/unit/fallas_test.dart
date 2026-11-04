// SPEC-001 T1: cada falla cambia exactamente las líneas que debe (ni una de
// más, ni en otro lugar). El auditor no basta para esto: encuentra la falla
// aunque, p. ej., el shutdown quede una línea antes.
import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/fallas.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';

final _plan = planificarRed('192.168.10.0', 24, const [
  Segmento('VENTAS', 50),
  Segmento('TI', 20),
], const OpcionesPlan());

final _limpia = generarConfiguracion(_plan, const OpcionesConfig());

List<String> _lineas(String equipo) => _limpia.singleWhere((c) => c.hostname == equipo).lineas;

/// Las líneas de [equipo] con la falla [f] en TI.
List<String> _con(TipoFalla f, String equipo) =>
    inyectarFalla(_limpia, _plan, f, _plan.segmentos[1]).singleWhere((c) => c.hostname == equipo).lineas;

void main() {
  test('la subinterfaz apagada lleva el shutdown justo después de su ip address', () {
    final r1 = _lineas('R1');
    final esperado = [...r1]..insert(r1.indexOf(' ip address 192.168.10.65 255.255.255.224') + 1, ' shutdown');
    expect(_con(TipoFalla.subinterfazApagada, 'R1'), esperado);
  });

  test('el gateway equivocado es la IP siguiente con la misma máscara', () {
    final r1 = _lineas('R1');
    final esperado = [...r1]..[r1.indexOf(' ip address 192.168.10.65 255.255.255.224')] =
        ' ip address 192.168.10.66 255.255.255.224';
    expect(_con(TipoFalla.gatewayEquivocado, 'R1'), esperado);
  });

  test('sin pool se borra el bloque del pool hasta su exit, incluido', () {
    final r1 = _lineas('R1');
    final i = r1.indexOf('ip dhcp pool TI');
    final fin = r1.indexOf('exit', i);
    expect(_con(TipoFalla.sinPool, 'R1'), [...r1.sublist(0, i), ...r1.sublist(fin + 1)]);
  });

  test('al troncal le falta solo la VLAN del segmento', () {
    final sw = _lineas('SW1');
    const base = ' switchport trunk allowed vlan ';
    final i = sw.indexWhere((l) => l.startsWith(base));
    final vlans = sw[i].substring(base.length).split(',');
    expect(vlans, contains('20'));
    final esperado = [...sw]..[i] = '$base${[for (final v in vlans) if (v != '20') v].join(',')}';
    expect(_con(TipoFalla.troncalSinVlan, 'SW1'), esperado);
  });

  test('la nativa distinta deja la VLAN 1 en el troncal', () {
    final sw = _lineas('SW1');
    final i = sw.indexWhere((l) => l.startsWith(' switchport trunk native vlan '));
    final esperado = [...sw]..[i] = ' switchport trunk native vlan 1';
    expect(_con(TipoFalla.nativaDistinta, 'SW1'), esperado);
  });

  test('una línea buscada que está al principio también se encuentra', () {
    final ti = _plan.segmentos[1];
    final r1 = inyectarFalla([
      const ConfigEquipo('R1', ['ip dhcp pool TI', ' network 192.168.10.64 255.255.255.224', 'exit', 'end']),
    ], _plan, TipoFalla.sinPool, ti).single;
    expect(r1.lineas, ['end']);
  });
}
