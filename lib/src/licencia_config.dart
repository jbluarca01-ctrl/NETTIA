// Configuración de la licencia de venta (SPEC-005).
import 'package:flutter/foundation.dart';

/// Clave pública Ed25519 de venta (32 bytes, en hex). La entrega Jairo
/// desde su licenciador. Vacía = el APK de venta no acepta ninguna licencia
/// y `scripts/build_venta.ps1` se niega a compilar.
List<int> get clavePublicaVenta => _bytes('c4902b2755db1258c162f16a9c54eed5b78f87246fe1bf9ce095c66b0a557a69');

/// Huella SHA-256 del certificado de publicación de Jairo (`AA:BB:…`).
/// Vacía = el APK de venta se bloquea siempre y el script no compila.
String get huellaVenta => 'FC:0D:B7:0C:63:F1:C4:2A:30:B6:AF:61:36:03:BF:39:3F:8C:52:23:75:A2:78:F1:23:2F:F4:A9:45:17:C9:71';

/// Contacto para comprar o pedir soporte; vacío = no se muestra.
String get contactoCompra => 'Escríbeme por WhatsApp al +503 7683 5548';

/// Clave pública de PRUEBA (semilla 0..31, conocida): solo para debug y
/// tests. En release nunca se usa.
List<int> get clavePublicaPrueba => _bytes('03a107bff3ce10be1d70dd18e74bc09967e4d6309ba50d5f1ddc8664125531b8');

/// La clave que usa esta compilación.
List<int> get clavePublicaActiva => kReleaseMode ? clavePublicaVenta : clavePublicaPrueba;

/// La huella que se exige: solo en release.
String? get huellaExigidaActiva => kReleaseMode ? huellaVenta : null;

/// Bytes de [hex] (dos dígitos por byte).
List<int> _bytes(String hex) => [
  for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16),
];

/// `true` si la clave y la huella de venta tienen forma válida.
bool ventaLista({required List<int> clave, required String huella}) =>
    clave.length == 32 && huella.isNotEmpty;
