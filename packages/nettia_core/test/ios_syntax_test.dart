import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

const _base = TextStyle();

Map<String, Color?> _porTexto(List<InlineSpan> spans) => {
      for (final s in spans.whereType<TextSpan>())
        if (s.text != null && s.text!.trim().isNotEmpty) s.text!: s.style?.color,
    };

void main() {
  test('resalta comandos, IPs, interfaces y placeholders con One Dark', () {
    final m = _porTexto(resaltarIos('show ip interface fa0/1 192.168.1.1 <vlan-id>', _base));
    expect(m['show'], OneDark.command);
    expect(m['ip'], OneDark.keyword);
    expect(m['interface'], OneDark.keyword);
    expect(m['fa0/1'], OneDark.iface);
    expect(m['192.168.1.1'], OneDark.number);
    expect(m['<vlan-id>'], OneDark.placeholder);
  });

  test('la sangría se pinta por niveles (indent-rainbow)', () {
    final spans = resaltarIos('    switchport mode trunk', _base).whereType<TextSpan>().toList();
    final niveles = spans.where((s) => s.style?.backgroundColor != null).toList();
    expect(niveles.length, 2); // 4 espacios = 2 niveles de 2
    expect(niveles[0].style!.backgroundColor, kIndentRainbow[0]);
    expect(niveles[1].style!.backgroundColor, kIndentRainbow[1]);
  });

  test('el comentario y "no" tienen su propio color', () {
    final m = _porTexto(resaltarIos('no shutdown ! activa', _base));
    expect(m['no'], OneDark.operator);
    expect(m['! activa'], OneDark.comment);
  });

  test('el texto no se altera', () {
    const linea = '  ip address 10.0.0.1/24 <mask>';
    final texto = resaltarIos(linea, _base).whereType<TextSpan>().map((s) => s.text).join();
    expect(texto, linea);
  });

  test('una cadena entre comillas se pinta como string', () {
    final m = _porTexto(resaltarIos('banner motd "bienvenido"', _base));
    expect(m['"bienvenido"'], OneDark.string);
  });

  test('un número suelto (no IP) se pinta igual que un número', () {
    final m = _porTexto(resaltarIos('vlan 10', _base));
    expect(m['10'], OneDark.number);
  });

  test('una palabra que no es comando ni palabra de configuración usa el color base', () {
    final m = _porTexto(resaltarIos('hostname MiSwitch', _base));
    expect(m['MiSwitch'], OneDark.fg);
  });

  test('un comando exec que no es la primera palabra se pinta como palabra clave, no como comando', () {
    final m = _porTexto(resaltarIos('show ping', _base));
    expect(m['show'], OneDark.command);
    expect(m['ping'], OneDark.keyword);
  });

  test('texto suelto al final de la línea, tras el último token, usa el color base', () {
    final spans = resaltarIos('interface fa0/1 ***', _base).whereType<TextSpan>().toList();
    expect(spans.last.text, ' ***');
    expect(spans.last.style?.color, OneDark.fg);
  });

  test('las palabras compuestas con guion se pintan enteras como palabra de configuración', () {
    const compuestas = [
      'default-gateway', 'spanning-tree', 'channel-group', 'running-config',
      'startup-config', 'domain-name', 'exec-timeout', 'excluded-address',
      'default-router', 'dns-server', 'access-list',
    ];
    for (final w in compuestas) {
      final m = _porTexto(resaltarIos('x $w', _base));
      expect(m[w], OneDark.keyword, reason: w);
    }
  });

  test('port-channel y sus variantes se reconocen como interfaz', () {
    expect(_porTexto(resaltarIos('interface port-channel1', _base))['port-channel1'], OneDark.iface);
    expect(_porTexto(resaltarIos('interface Po 12', _base))['Po 12'], OneDark.iface);
    expect(_porTexto(resaltarIos('interface Gi0/0/1.20', _base))['Gi0/0/1.20'], OneDark.iface);
  });

  test('un rango numérico se pinta como un solo token numérico', () {
    final spans = resaltarIos('vlan 10-20', _base).whereType<TextSpan>().toList();
    final rango = spans.where((s) => s.text == '10-20').toList();
    expect(rango, hasLength(1));
    expect(rango.single.style?.color, OneDark.number);
  });

  test('una palabra con guion, guion bajo y dígitos es un único token', () {
    final m = _porTexto(resaltarIos('hostname SW_core-01', _base));
    expect(m['SW_core-01'], OneDark.fg);
  });

  test('nunca genera spans vacíos: ni entre tokens pegados ni al final', () {
    for (final linea in ['show', 'show ip', 'fa0/1', '10.0.0.1/24!x', '"a""b"', '  exit', '']) {
      final spans = resaltarIos(linea, _base).whereType<TextSpan>();
      expect(spans.every((s) => s.text!.isNotEmpty), isTrue, reason: '"$linea"');
    }
  });

  test('el texto entre tokens conserva el color base', () {
    final spans = resaltarIos('a;b', _base).whereType<TextSpan>().toList();
    expect(spans.map((s) => s.text).toList(), ['a', ';', 'b']);
    expect(spans[1].style?.color, OneDark.fg);
  });

  test('una tabulación cuenta como 4 espacios: dos niveles de sangría', () {
    final spans = resaltarIos('	show', _base).whereType<TextSpan>().toList();
    expect(spans.map((s) => s.text).toList(), ['  ', '  ', 'show']);
    expect(spans[0].style!.backgroundColor, kIndentRainbow[0]);
    expect(spans[1].style!.backgroundColor, kIndentRainbow[1]);
    expect(spans[2].style!.color, OneDark.command);
  });

  test('una sangría de longitud impar deja un último nivel de un solo espacio', () {
    final spans = resaltarIos('   show', _base).whereType<TextSpan>().toList();
    expect(spans.map((s) => s.text).toList(), ['  ', ' ', 'show']);
    expect(spans[1].style!.backgroundColor, kIndentRainbow[1]);
  });

  test('la paleta de sangría da la vuelta tras cuatro niveles', () {
    final spans = resaltarIos('          show', _base).whereType<TextSpan>().toList();
    final fondos = spans.take(5).map((s) => s.style!.backgroundColor).toList();
    expect(fondos, [...kIndentRainbow, kIndentRainbow[0]]);
  });
}
