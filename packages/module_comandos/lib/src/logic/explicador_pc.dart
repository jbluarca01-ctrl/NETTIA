/// Explica lo que muestra una PC con ipconfig y arp -a (Clases 13 y 14):
/// APIPA, gateway fuera de la red y la tabla ARP.
library;

import 'dart:math';

import 'modelo_show.dart';

// ------------------------------------------------------------------ ipconfig

final RegExp _reCampo = RegExp(
  r'^\s*(IPv4 Address|IP Address|Subnet Mask|Default Gateway)[\s.]*:\s*(\d+\.\d+\.\d+\.\d+)?',
);

/// Primer valor de cada campo: 'ip', 'subnet mask' y 'default gateway'.
Map<String, String> _campos(String texto) {
  final c = <String, String>{};
  for (final linea in texto.split('\n')) {
    final m = _reCampo.firstMatch(linea);
    if (m == null || m[2] == null) continue;
    final clave = m[1]!.toLowerCase().endsWith('address') ? 'ip' : m[1]!.toLowerCase();
    c.putIfAbsent(clave, () => m[2]!);
  }
  return c;
}

int _valor(String ip) => ip.split('.').map(int.parse).reduce((v, o) => v * 256 + o);

String _texto(int v) =>
    [v ~/ 16777216, v ~/ 65536 % 256, v ~/ 256 % 256, v % 256].join('.');

/// Prefijo de una máscara contigua, o `null` si no lo es.
int? _prefijo(String mascara) {
  final bits = mascara
      .split('.')
      .map((o) => int.parse(o).toRadixString(2).padLeft(8, '0'))
      .join();
  return RegExp(r'^1*0*$').hasMatch(bits) ? bits.indexOf('0') % 33 : null;
}

const _sinIp = Hallazgo(Nivel.problema, 'Sin dirección IPv4',
    'La PC no tiene IP con máscara válida: configúrala a mano o en DHCP (Desktop > IP Configuration).');

const _apipa = Hallazgo(Nivel.problema, 'APIPA: la PC no obtuvo IP del DHCP',
    'Se autoasignó 169.254.x.x. Revisa el servidor o pool DHCP, la VLAN del puerto y el trunk; o asigna una IP fija.');

Hallazgo _gateway(String? gw, String ip, int red, int cidr) {
  final tam = pow(2, 32 - cidr).toInt();
  if (gw == null || gw == '0.0.0.0') {
    return const Hallazgo(Nivel.aviso, 'Sin gateway',
        'La PC solo llega a su propia red. Configura el default gateway (la IP del router en esta red).');
  }
  if (gw == ip) {
    return const Hallazgo(Nivel.problema, 'El gateway es la propia IP de la PC',
        'Debe ser la IP del router en esta red.');
  }
  final g = _valor(gw);
  if (g - g % tam != red) {
    return Hallazgo(Nivel.problema, 'El gateway $gw está fuera de la red',
        'La red de la PC es ${_texto(red)}/$cidr (${_texto(red)} a ${_texto(red + tam - 1)}). El gateway debe ser una IP de esa red, normalmente la primera.');
  }
  return Hallazgo(Nivel.ok, 'Gateway $gw dentro de la red',
      'La PC puede salir de su red a través de él.');
}

/// (IP, prefijo, gateway) si hay una IP usable con máscara válida.
(String, int, String?)? _ipYPrefijo(Map<String, String> c) {
  final ip = c['ip'];
  final mascara = c['subnet mask'];
  if (ip == null || mascara == null || ip == '0.0.0.0') return null;
  final cidr = _prefijo(mascara);
  return (cidr == null || cidr == 0) ? null : (ip, cidr, c['default gateway']);
}

/// ipconfig o ipconfig /all de una PC (Windows o Packet Tracer).
ExplicacionShow explicarIpconfig(String texto) {
  final datos = _ipYPrefijo(_campos(texto));
  if (datos == null) {
    return const ExplicacionShow(
        TipoShow.ipconfig, 'No se encontró una IP con máscara válida.', [_sinIp]);
  }
  final (ip, cidr, gateway) = datos;
  if (ip.startsWith('169.254.')) {
    return ExplicacionShow(TipoShow.ipconfig, 'IP $ip (APIPA).', const [_apipa]);
  }
  final v = _valor(ip);
  final red = v - v % (pow(2, 32 - cidr).toInt());
  return ExplicacionShow(
    TipoShow.ipconfig,
    'IP $ip/$cidr en la red ${_texto(red)}.',
    [_gateway(gateway, ip, red, cidr)],
  );
}

// -------------------------------------------------------------------- arp -a

final RegExp _reArp = RegExp(
  r'^\s*(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f]{2}(?:[-:][0-9a-f]{2}){5}|[0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})\s+(\w+)',
  caseSensitive: false,
);

/// arp -a de una PC.
ExplicacionShow explicarArp(String texto) {
  final vecinos = [
    for (final l in texto.split('\n'))
      if (_reArp.firstMatch(l) case final m?)
        Hallazgo(
          Nivel.ok,
          '${m[1]} → ${m[2]}',
          m[3]!.toLowerCase() == 'dynamic'
              ? 'Aprendida con ARP (dynamic).'
              : 'Entrada fija (${m[3]}): no la aprendió ARP.',
        ),
  ];
  return ExplicacionShow(
    TipoShow.arp,
    '${vecinos.length} vecinos en la tabla ARP. ARP solo resuelve vecinos de '
        'la misma red; para otra red se usa la MAC del gateway.',
    vecinos.isNotEmpty
        ? vecinos
        : const [
            Hallazgo(Nivel.aviso, 'La tabla ARP está vacía',
                'La PC todavía no habló con nadie de su red. Haz ping a un vecino (o al gateway) y vuelve a correr arp -a.'),
          ],
  );
}
