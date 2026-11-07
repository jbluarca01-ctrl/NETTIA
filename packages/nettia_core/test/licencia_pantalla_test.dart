import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clave = [
  3, 161, 7, 191, 243, 206, 16, 190, 29, 112, 221, 24, 231, 75, 192, 153, //
  103, 228, 214, 48, 155, 165, 13, 95, 29, 220, 134, 100, 18, 85, 49, 184,
];
const _licNode =
    'NT1.UHJ1ZWJhIE5ldHRpYQ.YlXp0XxUDUBC3--h9okVn9lQVnwudIZkEuILCgP4tB7c_'
    'LmlUAm-elHHBnFTNJc7XZ6itcLKDdcc_MM_wrJJAA';

class _Fuente {
  _Fuente(this.datos);
  final DatosTelefono? datos;
  Future<DatosTelefono?> call() async => datos;
}

FuenteTelefono _fuente(DatosTelefono? d) => _Fuente(d).call;

GuardianLicencia _guardian({bool conDatos = true, String? huella}) =>
    GuardianLicencia(
      fuente: _fuente(
        conDatos
            ? const DatosTelefono(
              androidId: '9774d56d682e549c',
              huellaApk: 'AA',
            )
            : null,
      ),
      clavePublica: _clave,
      huellaExigida: huella,
    );

Future<void> _montar(
  WidgetTester t,
  GuardianLicencia g, {
  String contacto = '',
}) async {
  await t.pumpWidget(
    MaterialApp(
      builder:
          (_, child) =>
              PuertaLicencia(guardian: g, contacto: contacto, child: child!),
      home: const Text('APP'),
    ),
  );
  await t.runAsync(() => Future<void>.delayed(Duration.zero));
  await t.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sin revisar muestra solo un fondo vacío', (t) async {
    final g = _guardian();
    await t.pumpWidget(
      MaterialApp(
        builder:
            (_, child) =>
                PuertaLicencia(guardian: g, contacto: '', child: child!),
        home: const Text('APP'),
      ),
    );
    expect(find.text('APP'), findsNothing);
    expect(find.text('Activa tu Nettia'), findsNothing);
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
  });

  testWidgets('la puerta revisa sola y muestra la activación', (t) async {
    await _montar(t, _guardian());
    expect(find.text('Activa tu Nettia'), findsOneWidget);
    expect(find.text('706SD-81FDE'), findsOneWidget);
    expect(find.text('APP'), findsNothing);
  });

  testWidgets('el contacto se muestra solo si existe', (t) async {
    await _montar(t, _guardian());
    expect(find.textContaining('Compra'), findsNothing);
    await _montar(t, _guardian(), contacto: 'WhatsApp 7000-0000');
    expect(find.text('Compra o soporte: WhatsApp 7000-0000'), findsOneWidget);
  });

  testWidgets('copiar código', (t) async {
    String? copiado;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (c) async {
        if (c.method == 'Clipboard.setData') {
          copiado = (c.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await _montar(t, _guardian());
    expect(find.text('Código copiado'), findsNothing);
    await t.tap(find.text('Copiar código'));
    await t.pump();
    expect(copiado, '706SD-81FDE');
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('activar con licencia válida pasa a la app', (t) async {
    await _montar(t, _guardian());
    await t.enterText(find.byType(TextField), _licNode);
    await t.tap(find.text('Activar'));
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump();
    expect(find.text('APP'), findsOneWidget);
  });

  testWidgets('activar con texto inválido muestra el error', (t) async {
    await _montar(t, _guardian());
    const error =
        'Ese código no corresponde a este teléfono. Revisa que lo copiaste completo.';
    expect(find.text(error), findsNothing);
    await t.enterText(find.byType(TextField), 'hola');
    await t.tap(find.text('Activar'));
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump();
    expect(find.text(error), findsOneWidget);
    expect(find.text('APP'), findsNothing);
  });

  testWidgets('sin datos del teléfono', (t) async {
    await _montar(t, _guardian(conDatos: false));
    expect(
      find.text(
        'No se pudo leer este teléfono. Cierra Nettia y vuelve a abrirla.',
      ),
      findsOneWidget,
    );
    expect(find.text('APP'), findsNothing);
  });

  testWidgets('APK con otra firma', (t) async {
    await _montar(t, _guardian(huella: 'CC'));
    expect(
      find.text('Nettia no puede abrirse en este teléfono.'),
      findsOneWidget,
    );
    expect(find.text('APP'), findsNothing);
  });

  testWidgets('ya revisada no vuelve a revisar al montar', (t) async {
    SharedPreferences.setMockInitialValues({'licencia_v1': _licNode});
    final g = _guardian();
    await t.runAsync(g.revisar);
    var avisos = 0;
    g.addListener(() => avisos++);
    await _montar(t, g);
    expect(find.text('APP'), findsOneWidget);
    expect(avisos, 0);
  });
}
