import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/verificacion.dart';

void main() {
  final plan = planificarRed('10.0.0.0', 24, const [
    Segmento('A', 20),
    Segmento('B', 10),
  ], const OpcionesPlan());

  test('en capa 3 no hay troncal y el enrutador es el switch', () {
    final pasos = planVerificacion(
      plan,
      const OpcionesConfig(
        topologia: Topologia.switchCapa3,
        hostnameSwitch: 'CORE',
      ),
    );
    expect(pasos.where((p) => p.comando == 'show interfaces trunk'), isEmpty);
    expect(
      pasos
          .where((p) => p.comando == 'show ip interface brief')
          .map((p) => p.esperado),
      [
        'Vlan10 con 10.0.0.1, estado up/up',
        'Vlan20 con 10.0.0.33, estado up/up',
      ],
    );
    expect(pasos.last.equipo, 'CORE');
    expect(
      pasos
          .where((p) => p.esperado.contains('enrutamiento entre VLAN'))
          .single
          .comando,
      'ping 10.0.0.33',
    );
  });

  test('usa los nombres de equipo e interfaces indicados', () {
    final pasos = planVerificacion(
      plan,
      const OpcionesConfig(
        hostnameSwitch: 'ACC1',
        hostnameRouter: 'BORDE',
        troncalSwitch: 'GigabitEthernet0/2',
        interfazRouter: 'GigabitEthernet0/1',
      ),
    );
    expect(pasos.first.equipo, 'ACC1');
    expect(
      pasos.singleWhere((p) => p.comando == 'show interfaces trunk').esperado,
      startsWith('GigabitEthernet0/2 en trunking'),
    );
    expect(
      pasos.where((p) => p.equipo == 'BORDE').first.esperado,
      startsWith('GigabitEthernet0/1.10 con'),
    );
    expect(pasos.last.equipo, 'BORDE');
  });

  test('la IP de la PC sale del rango DHCP, respetando las reservadas', () {
    final conReservadas = planificarRed('10.0.0.0', 24, const [
      Segmento('A', 5),
    ], const OpcionesPlan(reservadas: 3));
    final renew = planVerificacion(
      conReservadas,
      const OpcionesConfig(),
    ).singleWhere((p) => p.comando == 'ipconfig /renew');
    expect(renew.esperado, startsWith('IP entre 10.0.0.5 y 10.0.0.14,'));
  });
}
