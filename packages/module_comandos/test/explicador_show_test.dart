import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_comandos/module_comandos.dart';
import 'package:module_comandos/src/explicar_tab.dart';
import 'package:module_comandos/src/logic/explicador_show.dart';
import 'package:nettia_core/nettia_core.dart';

const String _ipBrief = '''
Router#show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     192.168.1.1     YES manual up                    up
GigabitEthernet0/1     unassigned      YES unset  administratively down down
GigabitEthernet0/2     10.0.0.1        YES manual down                  down
Serial0/0/0            172.16.0.1      YES manual up                    down
Vlan1                  unassigned      YES unset  up                    down
Vlan10                 192.168.1.1     YES manual up                    up
''';

const String _vlanBrief = '''
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/1, Fa0/2, Fa0/3, Fa0/4
                                                Fa0/5, Fa0/6
10   VENTAS                           active    Fa0/7, Fa0/8
20   TI                               active
30   LAB                              act/lshut
1002 fddi-default                     act/unsup
1003 token-ring-default               act/unsup
''';

const String _ospf = '''
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/DR         00:00:33    10.0.0.2        GigabitEthernet0/0
3.3.3.3           1   2WAY/DROTHER    00:00:38    10.0.0.3        GigabitEthernet0/0
4.4.4.4           1   EXSTART/BDR     00:00:31    10.0.0.4        GigabitEthernet0/0
5.5.5.5           0   INIT/DROTHER    00:00:35    10.0.0.5        GigabitEthernet0/0
6.6.6.6           0   FULL/  -        00:00:39    172.16.0.2      Serial0/0/0
''';

Hallazgo _buscar(ExplicacionShow e, String texto) =>
    e.hallazgos.firstWhere((h) => h.titulo.contains(texto), orElse: () => throw StateError('sin "$texto"'));

void main() {
  group('reconocimiento', () {
    test('detecta cada comando por su encabezado', () {
      expect(detectarTipoShow(_ipBrief), TipoShow.ipInterfaceBrief);
      expect(detectarTipoShow(_vlanBrief), TipoShow.vlanBrief);
      expect(detectarTipoShow(_ospf), TipoShow.ospfNeighbor);
      expect(detectarTipoShow('hola mundo'), isNull);
      expect(explicarSalidaShow(''), isNull);
    });
  });

  group('show ip interface brief', () {
    final e = explicarSalidaShow(_ipBrief)!;

    test('clasifica cada combinación estado/protocolo', () {
      expect(_buscar(e, 'GigabitEthernet0/0').nivel, Nivel.ok);
      final admin = _buscar(e, 'GigabitEthernet0/1');
      expect(admin.nivel, Nivel.problema);
      expect(admin.detalle, contains('no shutdown'));
      expect(_buscar(e, 'GigabitEthernet0/2').detalle, contains('cable'));
      expect(_buscar(e, 'Serial0/0/0').detalle, contains('encapsulación'));
      expect(_buscar(e, 'Vlan1').detalle, contains('ningún puerto activo'));
    });

    test('detecta IP duplicada y ordena problemas primero', () {
      final dup = _buscar(e, 'IP duplicada');
      expect(dup.titulo, contains('192.168.1.1'));
      expect(dup.detalle, contains('GigabitEthernet0/0'));
      expect(e.hallazgos.first.nivel, Nivel.problema);
      expect(e.hallazgos.last.nivel, Nivel.ok);
    });

    test('el resumen cuenta las interfaces', () {
      expect(e.resumen, contains('6 interfaces'));
      expect(e.resumen, contains('2 en up/up'));
    });
  });

  group('show vlan brief', () {
    final e = explicarSalidaShow(_vlanBrief)!;

    test('lee puertos con continuación de línea y VLAN sin puertos', () {
      expect(_buscar(e, 'VLAN 10').nivel, Nivel.ok);
      expect(_buscar(e, 'VLAN 10').detalle, contains('Fa0/7, Fa0/8'));
      final sinPuertos = _buscar(e, 'VLAN 20');
      expect(sinPuertos.nivel, Nivel.aviso);
      expect(sinPuertos.detalle, contains('switchport access vlan 20'));
    });

    test('VLAN apagada y puertos en la VLAN 1', () {
      final apagada = _buscar(e, 'VLAN 30');
      expect(apagada.nivel, Nivel.problema);
      expect(apagada.detalle, contains('no shutdown'));
      expect(_buscar(e, 'puertos en la VLAN 1').titulo, contains('6 puertos'));
    });

    test('avisa que los trunk no aparecen y no critica las VLAN predeterminadas', () {
      expect(_buscar(e, 'trunk').detalle, contains('show interfaces trunk'));
      expect(e.hallazgos.any((h) => h.titulo.contains('1002')), isFalse);
      expect(e.resumen, contains('3 creadas'));
    });
  });

  group('show ip ospf neighbor', () {
    final e = explicarSalidaShow(_ospf)!;

    test('FULL y 2WAY/DROTHER son normales', () {
      expect(_buscar(e, '2.2.2.2').nivel, Nivel.ok);
      expect(_buscar(e, '3.3.3.3').nivel, Nivel.ok);
      expect(_buscar(e, '3.3.3.3').detalle, contains('DR y el BDR'));
      expect(_buscar(e, '6.6.6.6').nivel, Nivel.ok); // punto a punto: "FULL/  -"
    });

    test('EXSTART apunta al MTU y INIT a Hello unidireccional', () {
      final ex = _buscar(e, '4.4.4.4');
      expect(ex.nivel, Nivel.problema);
      expect(ex.detalle, contains('MTU'));
      expect(ex.detalle, contains('13684-12'));
      expect(_buscar(e, '5.5.5.5').detalle, contains('Hello'));
    });

    test('sin vecinos sugiere qué revisar', () {
      final vacio = explicarSalidaShow(
          'Neighbor ID     Pri   State           Dead Time   Address         Interface\n')!;
      expect(vacio.hallazgos.single.titulo, 'No hay vecinos OSPF');
      expect(vacio.hallazgos.single.detalle, contains('passive-interface'));
    });

    test('el resumen cuenta los vecinos FULL', () {
      expect(e.resumen, '5 vecinos: 2 en FULL, 3 por revisar.');
    });
  });

  group('pantalla', () {
    Future<void> abrir(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: ExplicarSalidaTab()),
      ));
    }

    testWidgets('explica una salida pegada', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byType(TextField), _ipBrief);
      await tester.tap(find.text('Explicar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('show ip interface brief: 6 interfaces'), findsOneWidget);
      expect(find.textContaining('administratively down / down'), findsOneWidget);
    });

    testWidgets('texto no reconocido muestra el aviso', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byType(TextField), 'esto no es una salida');
      await tester.tap(find.text('Explicar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No reconozco ese texto'), findsOneWidget);
    });

    testWidgets('está dentro de Comandos CLI como quinta pestaña', (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: const Scaffold(body: ComandosScreen()),
      ));
      await tester.tap(find.widgetWithText(Tab, 'Explicar salida'));
      await tester.pumpAndSettle();
      expect(find.text('Pega aquí la salida de un comando show'), findsOneWidget);
    });
  });
}
