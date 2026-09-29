/// Oculta datos sensibles de un texto (típicamente una configuración de Cisco
/// IOS pegada por el usuario) **antes** de enviarlo a un proveedor de IA en la
/// nube. Dart puro y por reglas: no usa red ni IA.
///
/// Limitaciones conocidas (v1): no reconoce direcciones IPv6 globales ni
/// secretos escritos en texto libre sin `clave:`/`password =`; una lista de
/// reglas no sustituye a revisar lo que se pega.
library;

/// Resultado de sanitizar: el texto ya enmascarado y cuántos datos de cada
/// categoría se ocultaron.
class ResultadoSanitizado {
  const ResultadoSanitizado(this.texto, this.ocultados);

  final String texto;

  /// Categoría → cantidad (solo las que tuvieron coincidencias).
  final Map<String, int> ocultados;

  int get total => ocultados.values.fold(0, (a, b) => a + b);

  /// Frase para mostrar al usuario, p. ej. "2 contraseñas, 1 IP pública".
  String get resumen =>
      ocultados.entries.map((e) => '${e.value} ${e.key}').join(', ');
}

const String _cPass = 'contraseña(s)';
const String _cSnmp = 'comunidad(es) SNMP';
const String _cClave = 'clave(s) compartida(s)';
const String _cSecreto = 'clave(s) privada(s) o de API';
const String _cHost = 'nombre(s) de equipo';
const String _cDominio = 'dominio(s)';
const String _cIp = 'IP(s) pública(s)';

bool _esIpv4Publica(String ip) {
  final p = ip.split('.').map(int.tryParse).toList();
  if (p.length != 4 || p.any((o) => o == null || o < 0 || o > 255)) {
    return false; // no es una IPv4 válida
  }
  final a = p[0]!;
  final b = p[1]!;
  final c = p[2]!;
  if (a == 0 || a == 127 || a >= 224) return false; // wildcard, loopback, multicast, máscaras
  if (a == 10) return false;
  if (a == 172 && b >= 16 && b <= 31) return false;
  if (a == 192 && b == 168) return false;
  if (a == 169 && b == 254) return false;
  if (a == 100 && b >= 64 && b <= 127) return false; // CGNAT
  // Rangos de documentación (RFC 5737): son ejemplos, no datos reales.
  if (a == 192 && b == 0 && c == 2) return false;
  if (a == 198 && b == 51 && c == 100) return false;
  if (a == 203 && b == 0 && c == 113) return false;
  return true;
}

/// Enmascara datos sensibles de [texto]. Los nombres de equipo, dominios e IPs
/// públicas se reemplazan por marcadores **consistentes** (`HOST-1`,
/// `IP-PUBLICA-2`) para que la IA pueda seguir razonando sobre la topología.
ResultadoSanitizado sanitizarDatosSensibles(String texto) {
  final cuentas = <String, int>{};
  void cuenta(String c) => cuentas[c] = (cuentas[c] ?? 0) + 1;

  var t = texto;

  // 1. Claves privadas en formato PEM.
  t = t.replaceAllMapped(
    RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----'),
    (m) {
      cuenta(_cSecreto);
      return '<CLAVE-PRIVADA-OCULTA>';
    },
  );

  // 2. Claves de API con prefijos conocidos.
  t = t.replaceAllMapped(
    RegExp(
      r'\b(?:sk-ant-[A-Za-z0-9_-]{16,}|sk-[A-Za-z0-9_-]{20,}|nvapi-[A-Za-z0-9_-]{16,}|AIza[0-9A-Za-z_-]{20,}|xox[abp]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{20,})',
    ),
    (m) {
      cuenta(_cSecreto);
      return '<CLAVE-API-OCULTA>';
    },
  );

  // 3. Líneas de configuración con secretos: se conserva el comando y se
  //    oculta el valor (y el tipo de cifrado opcional que lo precede).
  void enmascaraLinea(RegExp re, String categoria) {
    t = t.replaceAllMapped(re, (m) {
      cuenta(categoria);
      return '${m.group(1)}<OCULTO>';
    });
  }

  enmascaraLinea(
    RegExp(
      r'^(\s*(?:enable\s+(?:secret|password)|username\s+\S+(?:\s+privilege\s+\d+)?\s+(?:secret|password)|password|ppp\s+(?:chap|pap)\s+password|ip\s+ospf\s+authentication-key|ip\s+ospf\s+message-digest-key\s+\d+\s+md5)\s+(?:\d\s+)?)(\S+)',
      caseSensitive: false,
      multiLine: true,
    ),
    _cPass,
  );
  enmascaraLinea(
    RegExp(r'^(\s*snmp-server\s+community\s+)(\S+)',
        caseSensitive: false, multiLine: true),
    _cSnmp,
  );
  enmascaraLinea(
    RegExp(
      r'^(\s*(?:(?:tacacs|radius)-server\s+key|key-string|key|crypto\s+isakmp\s+key|pre-shared-key(?:\s+\w+)?)\s+(?:\d\s+)?)(\S+)',
      caseSensitive: false,
      multiLine: true,
    ),
    _cClave,
  );

  // 4. Secretos en texto libre con "clave: valor" o "password = valor".
  t = t.replaceAllMapped(
    RegExp(
      r'\b(password|passwd|contrase(?:ñ|n)a|secret|token)(\s*[:=]\s*)(\S+)',
      caseSensitive: false,
    ),
    (m) {
      cuenta(_cPass);
      return '${m.group(1)}${m.group(2)}<OCULTO>';
    },
  );

  // 5. Nombres de equipo y dominios, con marcadores consistentes.
  final hosts = <String, String>{};
  t = t.replaceAllMapped(
    RegExp(r'^(\s*hostname\s+)(\S+)', caseSensitive: false, multiLine: true),
    (m) {
      final id = hosts.putIfAbsent(
          m.group(2)!.toLowerCase(), () => 'HOST-${hosts.length + 1}');
      cuenta(_cHost);
      return '${m.group(1)}$id';
    },
  );
  // Si el nombre real aparece en otras líneas (prompts, descripciones), también,
  // pero solo si parece un nombre propio (lleva dígito, guion o guion bajo):
  // así no se destruyen palabras corrientes como "switch" o "router".
  hosts.forEach((real, marcador) {
    if (!RegExp(r'[\d_-]').hasMatch(real)) return;
    t = t.replaceAll(
      RegExp('(?<![A-Za-z0-9_-])${RegExp.escape(real)}(?![A-Za-z0-9_-])',
          caseSensitive: false),
      marcador,
    );
  });
  t = t.replaceAllMapped(
    RegExp(r'^(\s*ip\s+domain[- ]name\s+)(\S+)',
        caseSensitive: false, multiLine: true),
    (m) {
      cuenta(_cDominio);
      return '${m.group(1)}DOMINIO.LOCAL';
    },
  );

  // 6. IPv4 públicas → IP-PUBLICA-n (misma IP, mismo marcador).
  final ips = <String, String>{};
  t = t.replaceAllMapped(
    RegExp(r'(?<![\d.])(\d{1,3}(?:\.\d{1,3}){3})(?![\d.]*\d)'),
    (m) {
      final ip = m.group(1)!;
      if (!_esIpv4Publica(ip)) return ip;
      cuenta(_cIp);
      return ips.putIfAbsent(ip, () => 'IP-PUBLICA-${ips.length + 1}');
    },
  );

  return ResultadoSanitizado(t, cuentas);
}
