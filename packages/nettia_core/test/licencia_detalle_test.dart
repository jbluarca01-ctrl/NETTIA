import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'soporte/instantanea.dart';

/// Detalle de la activación (último intento del gate de SPEC-005,
/// 2026-11-06): aspecto fijado con instantáneas y casos finos de la puerta.
///
///   Escenario: la pantalla de activación conserva textos, campo y espacios
///   Escenario: el aviso de bloqueo conserva su margen
///   Escenario: reconstruir la puerta con el mismo guardián no lo revisa de nuevo
///   Escenario: si la pantalla se cierra mientras activa, no falla
///   Escenario: los resultados de una licencia se describen legibles
const _clave = [
  3, 161, 7, 191, 243, 206, 16, 190, 29, 112, 221, 24, 231, 75, 192, 153, //
  103, 228, 214, 48, 155, 165, 13, 95, 29, 220, 134, 100, 18, 85, 49, 184,
];
const _datos = DatosTelefono(androidId: '9774d56d682e549c', huellaApk: 'AA');

GuardianLicencia _guardian(FuenteTelefono fuente, {String? huella}) =>
    GuardianLicencia(fuente: fuente, clavePublica: _clave, huellaExigida: huella);

Future<DatosTelefono?> _conDatos() async => _datos;

/// Guardián cuya activación tarda: deja tiempo para cerrar la pantalla.
class _GuardianLento extends GuardianLicencia {
  _GuardianLento() : super(fuente: _conDatos, clavePublica: _clave);

  @override
  Future<bool> activar(String texto) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return false;
  }
}

Widget _puerta(GuardianLicencia g, {String contacto = ''}) => MaterialApp(
  builder: (_, child) => PuertaLicencia(guardian: g, contacto: contacto, child: child!),
  home: const Text('APP'),
);

Future<void> _montar(WidgetTester t, GuardianLicencia g, {String contacto = ''}) async {
  await t.pumpWidget(_puerta(g, contacto: contacto));
  await t.runAsync(() => Future<void>.delayed(Duration.zero));
  await t.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la pantalla de activación conserva textos, campo y espacios', (t) async {
    await _montar(t, _guardian(_conDatos), contacto: 'WhatsApp 1234');
    expectInstantanea(
      instantanea(t, find.byType(PantallaActivacion)),
      'pantalla_activacion',
    );
    final campo = t.widget<TextField>(find.byType(TextField));
    expect(campo.minLines, 2);
    expect(campo.maxLines, 4);
    expect(campo.decoration!.labelText, 'Pega aquí tu licencia');
    expect(find.text('Código de este teléfono'), findsOneWidget);
    expect(
      find.text(
        'Envía este código a quien te vendió Nettia. Te devolverá tu '
        'licencia: cópiala y pégala aquí.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el aviso de bloqueo conserva su margen', (t) async {
    await _montar(t, _guardian(_conDatos, huella: 'CC'));
    expect(find.text('Nettia no puede abrirse en este teléfono.'), findsOneWidget);
    expectInstantanea(instantanea(t, find.byType(Center).last), 'aviso_bloqueo');
  });

  testWidgets('reconstruir la puerta con el mismo guardián no lo revisa de nuevo', (t) async {
    var lecturas = 0;
    final nunca = Completer<DatosTelefono?>();
    final g = _guardian(() {
      lecturas++;
      return nunca.future;
    });
    await t.pumpWidget(_puerta(g));
    await t.pumpWidget(_puerta(g, contacto: 'otro'));
    expect(g.estado, EstadoLicencia.sinRevisar);
    expect(lecturas, 1);
  });

  testWidgets('si la pantalla se cierra mientras activa, no falla', (t) async {
    await _montar(t, _GuardianLento());
    await t.enterText(find.byType(TextField), 'NT1.no.vale');
    await t.tap(find.text('Activar'));
    await t.pumpWidget(const MaterialApp(home: Text('otra')));
    await t.pump(const Duration(milliseconds: 200));
    expect(t.takeException(), isNull);
  });

  test('los resultados de una licencia se describen legibles', () {
    expect(const LicenciaValida('Ana').toString(), 'LicenciaValida(Ana)');
    expect(
      const LicenciaInvalida(MotivoRechazo.firma).toString(),
      'LicenciaInvalida(firma)',
    );
  });
}
