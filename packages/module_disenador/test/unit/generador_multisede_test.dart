import 'package:flutter_test/flutter_test.dart';
import 'package:module_disenador/src/logic/fisica.dart';
import 'package:module_disenador/src/logic/generador.dart';
import 'package:module_disenador/src/logic/generador_multisede.dart';
import 'package:module_disenador/src/logic/multisede.dart';
import 'package:module_disenador/src/logic/plan_red.dart';
import 'package:module_disenador/src/logic/verificacion.dart';

PlanRed _sede(String red) => planificarRed(red, 24, const [Segmento('A', 20)], const OpcionesPlan());

void main() {
  test('paraSede conserva todo y cambia hostnames, primer switch y topología', () {
    const o = OpcionesConfig(
      topologia: Topologia.switchCapa3,
      troncalSwitch: 'GigabitEthernet0/2',
      interfazRouter: 'GigabitEthernet0/1',
      prefijoAcceso: 'Fa0/',
      puertosAcceso: 48,
      dns: '8.8.8.8',
      dominio: 'lab.local',
      enableSecret: 'cisco',
      switches: 2,
      conexion: Conexion.ambos,
      pcPorSwitch: {
        'A': [1, 2],
      },
    );
    final s = o.paraSede(3, 5);
    expect(s.hostnameRouter, 'R3');
    expect(s.hostnameSwitch, 'SW5');
    expect(s.primerSwitch, 5);
    expect(s.topologia, Topologia.routerOnAStick);
    expect(
      [s.troncalSwitch, s.interfazRouter, s.prefijoAcceso, s.puertosAcceso, s.dns, s.dominio, s.enableSecret, s.switches, s.conexion, s.pcPorSwitch],
      [o.troncalSwitch, o.interfazRouter, o.prefijoAcceso, o.puertosAcceso, o.dns, o.dominio, o.enableSecret, o.switches, o.conexion, o.pcPorSwitch],
    );
    expect(const OpcionesConfig().primerSwitch, 1);
  });

  test('interfazDesplazada mueve solo el último número', () {
    expect(interfazDesplazada('GigabitEthernet0/0/0', 2), 'GigabitEthernet0/0/2');
    expect(interfazDesplazada('GigabitEthernet0/1', 0), 'GigabitEthernet0/1');
    expect(interfazDesplazada('Fa0/9', 3), 'Fa0/12');
  });

  test('las opciones de cada sede (DNS, clave) llegan a sus equipos', () {
    final red = planificarMultisede([_sede('192.168.10.0'), _sede('192.168.20.0')], '10.0.0.0/30', Enrutamiento.ospf);
    final equipos = generarMultisede(red, const [OpcionesConfig(enableSecret: 'uno'), OpcionesConfig(dns: '1.1.1.1')]);
    expect(equipos[1].lineas, contains('enable secret uno'));
    expect(equipos[3].lineas, contains(' dns-server 1.1.1.1'));
    expect(equipos[3].lineas, isNot(contains('enable secret uno')));
  });

  test('la verificación es la de cada sede y después la de enlaces y rutas, en orden', () {
    final sedes = [_sede('192.168.10.0'), _sede('192.168.20.0'), _sede('192.168.30.0')];
    final red = planificarMultisede(sedes, '10.0.0.0/29', Enrutamiento.estaticaPorSubred);
    const opciones = [OpcionesConfig(switches: 1), OpcionesConfig(), OpcionesConfig()];
    String texto(PasoVerificacion p) => '${p.equipo}|${p.comando}|${p.esperado}';
    final esperado = [
      for (var i = 0; i < 3; i++) ...planVerificacion(sedes[i], opciones[i].paraSede(i + 1, i + 1)).map(texto),
      'R1|ping 10.0.0.2|Responde: el enlace con R2 está arriba.',
      'R2|ping 10.0.0.6|Responde: el enlace con R3 está arriba.',
      for (var i = 1; i <= 3; i++) 'R$i|show ip route|Las redes de las otras sedes aparecen con S (estáticas).',
    ];
    expect(verificacionMultisede(red, opciones).map(texto), esperado);
  });

  test('el enrutamiento va justo antes del DHCP', () {
    final red = planificarMultisede([_sede('192.168.10.0'), _sede('192.168.20.0')], '10.0.0.0/30', Enrutamiento.estaticaResumida);
    final r1 = generarMultisede(red, const [OpcionesConfig(), OpcionesConfig()])[1];
    final i = r1.lineas.indexOf('ip route 192.168.20.0 255.255.255.224 10.0.0.2');
    expect(r1.lineas[i + 1], 'ip dhcp excluded-address 192.168.10.1');
    expect(r1.lineas.indexOf('end'), greaterThan(i));
  });
}
