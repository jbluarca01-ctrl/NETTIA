/// Tipos compartidos por los explicadores de salidas de comandos.
library;

/// Gravedad de un hallazgo.
enum Nivel { ok, aviso, problema }

class Hallazgo {
  const Hallazgo(this.nivel, this.titulo, this.detalle);

  final Nivel nivel;

  /// Qué se ve (p. ej. "GigabitEthernet0/1: administratively down / down").
  final String titulo;

  /// Qué significa y qué revisar.
  final String detalle;
}

/// Comandos reconocidos.
enum TipoShow {
  ipInterfaceBrief('show ip interface brief'),
  vlanBrief('show vlan brief'),
  ospfNeighbor('show ip ospf neighbor'),
  ipRoute('show ip route'),
  interfacesTrunk('show interfaces trunk'),
  dhcpBinding('show ip dhcp binding'),
  ipconfig('ipconfig (PC)'),
  arp('arp -a (PC)');

  const TipoShow(this.comando);
  final String comando;
}

class ExplicacionShow {
  const ExplicacionShow(this.tipo, this.resumen, this.hallazgos);

  final TipoShow tipo;
  final String resumen;
  final List<Hallazgo> hallazgos;
}

/// Problemas primero, luego avisos y al final lo que está bien.
List<Hallazgo> ordenarHallazgos(List<Hallazgo> h) {
  int peso(Nivel n) => switch (n) {
        Nivel.problema => 0,
        Nivel.aviso => 1,
        Nivel.ok => 2,
      };
  final copia = List<Hallazgo>.of(h);
  // sort de Dart no es estable: se desempata por posición original.
  final orden = <Hallazgo, int>{for (var i = 0; i < copia.length; i++) copia[i]: i};
  copia.sort((a, b) {
    final c = peso(a.nivel).compareTo(peso(b.nivel));
    return c != 0 ? c : orden[a]!.compareTo(orden[b]!);
  });
  return copia;
}
