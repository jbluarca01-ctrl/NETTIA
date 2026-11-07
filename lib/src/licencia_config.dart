// Configuración de la licencia de venta (SPEC-005).
import 'package:flutter/foundation.dart';

/// Clave pública Ed25519 de venta (32 bytes). La entrega Jairo desde su
/// licenciador. Vacía = el APK de venta no acepta ninguna licencia y
/// `scripts/build_venta.ps1` se niega a compilar.
const List<int> clavePublicaVenta = [
  196, 144, 43, 39, 85, 219, 18, 88, 193, 98, 241, 106, 156, 84, 238, 213, //
  183, 143, 135, 36, 111, 225, 191, 156, 224, 149, 198, 107, 10, 85, 122, 105,
];

/// Huella SHA-256 del certificado de publicación de Jairo (`AA:BB:…`).
/// Vacía = el APK de venta se bloquea siempre y el script no compila.
const String huellaVenta =
    'FC:0D:B7:0C:63:F1:C4:2A:30:B6:AF:61:36:03:BF:39:3F:8C:52:23:75:A2:78:F1:23:2F:F4:A9:45:17:C9:71';

/// Contacto para comprar o pedir soporte; vacío = no se muestra.
const String contactoCompra = 'Escríbeme por WhatsApp al +503 7683 5548';

/// Clave pública de PRUEBA (semilla 0..31, conocida): solo para debug y
/// tests. En release nunca se usa.
const List<int> clavePublicaPrueba = [
  3, 161, 7, 191, 243, 206, 16, 190, 29, 112, 221, 24, 231, 75, 192, 153, //
  103, 228, 214, 48, 155, 165, 13, 95, 29, 220, 134, 100, 18, 85, 49, 184,
];

/// La clave que usa esta compilación.
const List<int> clavePublicaActiva =
    kReleaseMode ? clavePublicaVenta : clavePublicaPrueba;

/// La huella que se exige: solo en release.
const String? huellaExigidaActiva = kReleaseMode ? huellaVenta : null;

/// `true` si la clave y la huella de venta tienen forma válida.
bool ventaLista({required List<int> clave, required String huella}) =>
    clave.length == 32 && huella.isNotEmpty;
