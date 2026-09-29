import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nettia_core/nettia_core.dart';

import 'conversion_tab.dart';
import 'dividir_tab.dart';
import 'ipv6_tab.dart';
import 'practica_tab.dart';
import 'vlsm_tab.dart';

class _SubnetResult {
  final String mask;
  final int cidr;
  final String networkAddress;
  final String broadcastAddress;
  final String firstHost;
  final String lastHost;
  final String defaultGateway;
  final int totalHosts;

  const _SubnetResult({
    required this.mask,
    required this.cidr,
    required this.networkAddress,
    required this.broadcastAddress,
    required this.firstHost,
    required this.lastHost,
    required this.defaultGateway,
    required this.totalHosts,
  });
}

/// Desglose binario octeto a octeto de una IP/máscara, para mostrar el
/// paso intermedio que se pide en los ejercicios de subneteo.
String _ipToBinary(String ip) {
  return ip
      .split('.')
      .map((o) => int.parse(o).toRadixString(2).padLeft(8, '0'))
      .join('.');
}

/// Convierte una IP/máscara en binario punteado (4 octetos de 8 bits,
/// ej. "11000000.10101000.00000001.00000001") a su forma decimal punteada.
/// Devuelve null si el formato no es válido (permite validar en vivo
/// mientras el usuario escribe).
String? _binaryToDecimalIp(String binaryStr) {
  final parts = binaryStr.trim().split('.');
  if (parts.length != 4) return null;
  final octets = <int>[];
  for (final part in parts) {
    if (part.length != 8 || !RegExp(r'^[01]{8}$').hasMatch(part)) return null;
    octets.add(int.parse(part, radix: 2));
  }
  return octets.join('.');
}

/// Parsea una IP decimal punteada a su entero de 32 bits, o null si no es
/// válida (reutilizado tanto por el cálculo de subred como por la
/// conversión de máscara decimal a CIDR).
int? _decimalIpToInt(String ipStr) {
  final parts = ipStr.trim().split('.');
  if (parts.length != 4) return null;
  var value = 0;
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return null;
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) return null;
    value = value * 256 + octet;
  }
  return value;
}

/// Encuentra el CIDR (1-30) cuya máscara decimal equivalente coincide con
/// `decimalMask`, o null si la máscara no es válida/contigua o está fuera
/// de ese rango.
int? _cidrFromDecimalMask(String decimalMask) {
  final maskInt = _decimalIpToInt(decimalMask);
  if (maskInt == null) return null;
  for (var cidr = 1; cidr <= 30; cidr++) {
    var blockSize = 1;
    for (var i = 0; i < 32 - cidr; i++) {
      blockSize *= 2;
    }
    if (4294967296 - blockSize == maskInt) return cidr;
  }
  return null;
}

/// Máscara en binario punteado (ej. "11111111.11111111.11111111.00000000")
/// para un CIDR dado: `cidr` unos seguidos de ceros hasta completar 32 bits.
String _cidrToMaskBits(int cidr) {
  final bits32 = ''.padRight(cidr, '1').padRight(32, '0');
  return '${bits32.substring(0, 8)}.${bits32.substring(8, 16)}.'
      '${bits32.substring(16, 24)}.${bits32.substring(24, 32)}';
}

/// Operación bit a bit entre dos IPs en binario punteado (mismo formato de
/// `_ipToBinary`/`_cidrToMaskBits`), preservando los puntos separadores.
String _bitwiseOp(String a, String b, int Function(int x, int y) op) {
  final buffer = StringBuffer();
  for (var i = 0; i < a.length; i++) {
    buffer.write(a[i] == '.' ? '.' : op(int.parse(a[i]), int.parse(b[i])));
  }
  return buffer.toString();
}

String _bitwiseAnd(String a, String b) => _bitwiseOp(a, b, (x, y) => x & y);
String _bitwiseOr(String a, String b) => _bitwiseOp(a, b, (x, y) => x | y);

String _bitwiseNot(String bits) =>
    bits.split('').map((c) => c == '.' ? '.' : (c == '0' ? '1' : '0')).join();

class _NetworkCalculator {
  // Red = IP AND Máscara. Broadcast = Red OR (NOT Máscara).
  // Esto se resuelve bit a bit sobre las cadenas binarias (`_bitwiseOp`) en
  // vez de con los operadores nativos `&`/`|`/`~` de Dart: esos operadores
  // truncan a 32 bits CON signo al compilar a JS (Flutter Web) y romperían
  // toda IP con el primer octeto >= 128. Trabajando bit a bit sobre texto
  // el resultado es idéntico y correcto en cualquier plataforma.
  static _SubnetResult? calculate(String ipStr, int cidr) {
    if (cidr < 1 || cidr > 30) return null;

    final parts = ipStr.trim().split('.');
    if (parts.length != 4) return null;

    final octets = <int>[];
    for (final part in parts) {
      if (part.isEmpty || part.length > 3) return null;
      final val = int.tryParse(part);
      if (val == null || val < 0 || val > 255) return null;
      octets.add(val);
    }

    final ipBits =
        octets.map((o) => o.toRadixString(2).padLeft(8, '0')).join('.');
    final maskBits = _cidrToMaskBits(cidr);
    final wildcardBits = _bitwiseNot(maskBits);
    final networkBits = _bitwiseAnd(ipBits, maskBits);
    final broadcastBits = _bitwiseOr(networkBits, wildcardBits);

    final maskDecimal = _binaryToDecimalIp(maskBits)!;
    final networkDecimal = _binaryToDecimalIp(networkBits)!;
    final broadcastDecimal = _binaryToDecimalIp(broadcastBits)!;

    final netInt = _decimalIpToInt(networkDecimal)!;
    final bcastInt = _decimalIpToInt(broadcastDecimal)!;
    final firstHostInt = netInt + 1;
    final lastHostInt = bcastInt - 1;

    // blockSize = 2^(32 - cidr), por duplicación sucesiva, para la cantidad
    // de hosts útiles (blockSize - dirección de red - broadcast).
    var blockSize = 1;
    for (var i = 0; i < 32 - cidr; i++) {
      blockSize *= 2;
    }
    final totalHosts = blockSize - 2;

    return _SubnetResult(
      mask: maskDecimal,
      cidr: cidr,
      networkAddress: networkDecimal,
      broadcastAddress: broadcastDecimal,
      firstHost: _intToIp(firstHostInt),
      lastHost: _intToIp(lastHostInt),
      defaultGateway: _intToIp(firstHostInt),
      totalHosts: totalHosts,
    );
  }

  static String _intToIp(int value) {
    final v = value % 4294967296;
    return '${v ~/ 16777216 % 256}.${v ~/ 65536 % 256}.${v ~/ 256 % 256}.${v % 256}';
  }
}

/// Módulo independiente: calculadoras de red. Pestañas: cálculo de una red
/// IPv4, dividir en subredes, VLSM, IPv6, conversiones y práctica.
class CalculadoraScreen extends StatelessWidget {
  const CalculadoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Column(
        children: <Widget>[
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[
              Tab(text: 'Red'),
              Tab(text: 'Dividir'),
              Tab(text: 'VLSM'),
              Tab(text: 'IPv6'),
              Tab(text: 'Conversión'),
              Tab(text: 'Práctica'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: <Widget>[
                _RedTab(),
                DividirTab(),
                VlsmTab(),
                Ipv6Tab(),
                ConversionTab(),
                PracticaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestaña "Red": cálculo de una única red IPv4 (máscara, rango, broadcast).
class _RedTab extends StatefulWidget {
  const _RedTab();

  @override
  State<_RedTab> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<_RedTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.1.1');
  final TextEditingController _maskController =
      TextEditingController(text: '255.255.255.0');
  int _selectedCidr = 24;
  _SubnetResult? _subnetResult;
  String? _resolvedIp;

  // 0 = CIDR (dropdown), 1 = máscara decimal manual, 2 = máscara binaria manual.
  int _maskInputMode = 0;
  bool _ipBinaryMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resolvedIp = _ipController.text.trim();
    _subnetResult =
        _NetworkCalculator.calculate(_ipController.text, _selectedCidr);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _maskController.dispose();
    super.dispose();
  }

  /// Resuelve el CIDR efectivo según el modo de entrada de máscara elegido:
  /// dropdown, máscara decimal escrita a mano o máscara binaria escrita a
  /// mano (útil cuando el enunciado da la máscara en vez del /CIDR).
  int? _resolveCidr() {
    switch (_maskInputMode) {
      case 1:
        return _cidrFromDecimalMask(_maskController.text);
      case 2:
        final decimalMask = _binaryToDecimalIp(_maskController.text);
        return decimalMask == null ? null : _cidrFromDecimalMask(decimalMask);
      default:
        return _selectedCidr;
    }
  }

  void _recalculate() {
    setState(() {
      _resolvedIp = _ipBinaryMode
          ? _binaryToDecimalIp(_ipController.text)
          : _ipController.text.trim();
      final cidr = _resolveCidr();
      _subnetResult = (_resolvedIp == null || cidr == null)
          ? null
          : _NetworkCalculator.calculate(_resolvedIp!, cidr);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[_buildCalculatorCard(theme)],
      ),
    );
  }

  Widget _buildCalculatorCard(ThemeData theme) {
    final result = _subnetResult;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.calculate_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                // Expanded: sin esto el título desborda con textScaler alto.
                Expanded(
                  child: Text(
                    'Cálculo de Red, Máscara y Gateway',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.text,
                    // El set de caracteres permitido cambia según el modo:
                    // decimal (dígitos y puntos) o binario (0/1 y puntos).
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(_ipBinaryMode ? r'[01.]' : r'[0-9.]'),
                      ),
                      LengthLimitingTextInputFormatter(_ipBinaryMode ? 35 : 15),
                    ],
                    style: const TextStyle(
                      fontFamilyFallback: kMonoFallback,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Dirección IPv4',
                      hintText: _ipBinaryMode
                          ? '11000000.10101000.00000001.00000001'
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(value: false, label: Text('Dec')),
                    ButtonSegment<bool>(value: true, label: Text('Bin')),
                  ],
                  selected: <bool>{_ipBinaryMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<bool> sel) {
                    final bool toBinary = sel.first;
                    setState(() {
                      // Convierte el valor ya escrito al nuevo formato para
                      // no perderlo al alternar Dec/Bin.
                      if (toBinary && !_ipBinaryMode) {
                        final decInt = _decimalIpToInt(_ipController.text);
                        if (decInt != null) {
                          _ipController.text =
                              _ipToBinary(_ipController.text);
                        }
                      } else if (!toBinary && _ipBinaryMode) {
                        final dec = _binaryToDecimalIp(_ipController.text);
                        if (dec != null) _ipController.text = dec;
                      }
                      _ipBinaryMode = toBinary;
                    });
                    _recalculate();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text('CIDR')),
                ButtonSegment<int>(value: 1, label: Text('Máscara dec.')),
                ButtonSegment<int>(value: 2, label: Text('Máscara bin.')),
              ],
              selected: <int>{_maskInputMode},
              showSelectedIcon: false,
              onSelectionChanged: (Set<int> sel) {
                final int newMode = sel.first;
                setState(() {
                  // Al cambiar de modo se intenta convertir lo ya escrito
                  // (dec<->bin) para no perderlo; si no hay nada válido, se
                  // precarga el equivalente del CIDR actualmente seleccionado.
                  final String? fallback =
                      _NetworkCalculator.calculate('0.0.0.0', _selectedCidr)
                          ?.mask;
                  if (newMode == 1) {
                    final String? fromBin =
                        _maskInputMode == 2 ? _binaryToDecimalIp(_maskController.text) : null;
                    _maskController.text = fromBin ?? fallback ?? '';
                  } else if (newMode == 2) {
                    final int? fromDec = _maskInputMode == 1
                        ? _decimalIpToInt(_maskController.text)
                        : null;
                    final String? decSource = fromDec != null
                        ? _maskController.text.trim()
                        : fallback;
                    _maskController.text =
                        decSource == null ? '' : _ipToBinary(decSource);
                  } else if (newMode == 0 && _maskInputMode != 0) {
                    // Vuelve a CIDR desde un modo de máscara manual: el
                    // dropdown debe reflejar lo que se escribió a mano, no
                    // quedarse en el CIDR seleccionado antes de salir de él.
                    final int? resuelto = _resolveCidr();
                    if (resuelto != null) _selectedCidr = resuelto;
                  }
                  _maskInputMode = newMode;
                });
                _recalculate();
              },
            ),
            const SizedBox(height: 10),
            if (_maskInputMode == 0)
              DropdownButtonFormField<int>(
                // Flutter >= 3.35: `value` está deprecado en favor de
                // `initialValue`. El widget mantiene la selección en su
                // propio FormFieldState; `_selectedCidr` se sincroniza
                // en onChanged.
                initialValue: _selectedCidr,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'CIDR',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: List<int>.generate(30, (int i) => i + 1)
                    .map((int cidr) => DropdownMenuItem<int>(
                          value: cidr,
                          child: Text('/$cidr'),
                        ))
                    .toList(),
                onChanged: (int? val) {
                  if (val == null) return;
                  _selectedCidr = val;
                  _recalculate();
                },
              )
            else
              TextField(
                controller: _maskController,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(_maskInputMode == 2 ? r'[01.]' : r'[0-9.]'),
                  ),
                  LengthLimitingTextInputFormatter(
                      _maskInputMode == 2 ? 35 : 15),
                ],
                style: const TextStyle(
                  fontFamilyFallback: kMonoFallback,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: _maskInputMode == 2
                      ? 'Máscara en binario'
                      : 'Máscara decimal (ej. 255.255.255.0)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _recalculate(),
              ),
            const SizedBox(height: 14),
            if (result != null) ...<Widget>[
              const Divider(),
              _infoRow('Máscara Decimal:', '${result.mask} (/${result.cidr})'),
              _infoRow('Dirección de Red:', result.networkAddress),
              _infoRow('Gateway Sugerido:', result.defaultGateway),
              _infoRow('Primer Host:', result.firstHost),
              _infoRow('Último Host:', result.lastHost),
              _infoRow('Broadcast:', result.broadcastAddress),
              _infoRow('Capacidad:', '${result.totalHosts} hosts útiles'),
              const SizedBox(height: 10),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Text(
                  'Desglose en binario',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              _binaryRow('IP:', _ipToBinary(_resolvedIp ?? '0.0.0.0')),
              _binaryRow('Máscara:', _ipToBinary(result.mask)),
              _binaryRow('Red:', _ipToBinary(result.networkAddress)),
              _binaryRow('Broadcast:', _ipToBinary(result.broadcastAddress)),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.error_outline,
                        size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resolvedIp == null
                            ? (_ipBinaryMode
                                ? 'IP en binario inválida. Se esperan 4 octetos de 8 bits (0/1).'
                                : 'Dirección IPv4 inválida. Se esperan 4 octetos de 0 a 255.')
                            : 'Máscara inválida. Debe ser una máscara de subred contigua (/1 a /30).',
                        style: TextStyle(
                            color: theme.colorScheme.error, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Flexible en ambos lados: evita RenderFlex overflow en pantallas
          // angostas o con escala de texto grande.
          Flexible(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontFamilyFallback: kMonoFallback,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _binaryRow(String label, String binaryValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 7,
            child: SelectableText(
              binaryValue,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontFamilyFallback: kMonoFallback,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
