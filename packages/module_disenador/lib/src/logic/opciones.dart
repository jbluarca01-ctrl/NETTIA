/// Opciones de los equipos que no salen del plan de direccionamiento.
library;

/// Cómo se enrutan las VLAN entre sí.
enum Topologia { routerOnAStick, switchCapa3 }

/// Cómo se conectan los switches con el router y entre sí.
enum Conexion {
  /// Cada switch con su propio troncal al router.
  alRouter,

  /// Solo SW1 llega al router; los demás se enlazan en cadena.
  enCadena,

  /// Cada switch al router y, además, enlazados en cadena.
  ambos,
}

/// Datos de los equipos que no salen del plan.
class OpcionesConfig {
  const OpcionesConfig({
    this.topologia = Topologia.routerOnAStick,
    this.hostnameSwitch = 'SW1',
    this.hostnameRouter = 'R1',
    this.troncalSwitch = 'GigabitEthernet0/1',
    this.interfazRouter = 'GigabitEthernet0/0/0',
    this.prefijoAcceso = 'FastEthernet0/',
    this.puertosAcceso = 24,
    this.dns = '',
    this.dominio = '',
    this.enableSecret = '',
    this.switches = 1,
    this.conexion = Conexion.alRouter,
    this.pcPorSwitch = const {},
  });

  final Topologia topologia;
  final String hostnameSwitch;
  final String hostnameRouter;
  final String troncalSwitch;
  final String interfazRouter;
  final String prefijoAcceso;
  final int puertosAcceso;
  final String dns;
  final String dominio;
  final String enableSecret;

  /// Switches de acceso (solo router-on-a-stick).
  final int switches;
  final Conexion conexion;

  /// PC de cada segmento (por nombre) en SW1, SW2…; la suma es igual a los
  /// hosts del segmento. Un segmento que no aparece tiene todo en SW1.
  final Map<String, List<int>> pcPorSwitch;
}
