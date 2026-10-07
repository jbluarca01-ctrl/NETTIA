// Genera los íconos de lanzamiento de Android a partir del logo de Nettia.
//
// En la suite normal los genera en una carpeta temporal y verifica que los
// PNG versionados en android/app/src/main/res sean idénticos (el logo y los
// íconos no pueden divergir). Para regenerar los versionados:
//   GENERATE_ICONS=1 flutter test test/tool/generate_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

// Píxeles por dp de cada densidad.
const Map<String, double> _escala = <String, double>{
  'mipmap-mdpi': 1.0,
  'mipmap-hdpi': 1.5,
  'mipmap-xhdpi': 2.0,
  'mipmap-xxhdpi': 3.0,
  'mipmap-xxxhdpi': 4.0,
};

Future<void> _guardar(
  WidgetTester tester,
  GlobalKey clave,
  String ruta,
) async {
  await tester.runAsync(() async {
    final boundary =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(ruta).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Widget _logo(double lado, {required double fraccion}) => NettiaLogo(
      size: lado * fraccion,
      color: NetworkTheme.darkTextPrimary,
      accent: NetworkTheme.darkAccentBlue,
      accent2: NetworkTheme.darkAccentTeal,
    );

void main() {
  final generar = Platform.environment['GENERATE_ICONS'] == '1';

  testWidgets(
    'genera los íconos de Nettia (legado y adaptativo)',
    (tester) async {
      final res = '${Directory.current.path}/android/app/src/main/res';
      final tmp = generar ? null : Directory.systemTemp.createTempSync('iconos_');
      addTearDown(() => tmp?.deleteSync(recursive: true));
      final salida = tmp?.path ?? res;
      for (final carpeta in _escala.keys) {
        Directory('$salida/$carpeta').createSync(recursive: true);
        final d = _escala[carpeta]!;

        // Ícono clásico 48 dp: fondo redondeado + logo.
        final legado = (48 * d).roundToDouble();
        final k1 = GlobalKey();
        await tester.binding.setSurfaceSize(Size(legado, legado));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: k1,
              child: Container(
                width: legado,
                height: legado,
                decoration: BoxDecoration(
                  color: NetworkTheme.darkBase,
                  borderRadius: BorderRadius.circular(legado * 0.22),
                ),
                alignment: Alignment.center,
                child: _logo(legado, fraccion: 0.66),
              ),
            ),
          ),
        );
        await _guardar(tester, k1, '$salida/$carpeta/ic_launcher.png');

        // Primer plano adaptativo 108 dp (el sistema recorta ~1/3 exterior).
        final adaptativo = (108 * d).roundToDouble();
        final k2 = GlobalKey();
        await tester.binding.setSurfaceSize(Size(adaptativo, adaptativo));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: k2,
              child: SizedBox(
                width: adaptativo,
                height: adaptativo,
                child: Center(child: _logo(adaptativo, fraccion: 0.5)),
              ),
            ),
          ),
        );
        await _guardar(tester, k2, '$salida/$carpeta/ic_launcher_foreground.png');
      }
      await tester.binding.setSurfaceSize(null);

      for (final carpeta in _escala.keys) {
        for (final png in ['ic_launcher.png', 'ic_launcher_foreground.png']) {
          expect(
            File('$salida/$carpeta/$png').readAsBytesSync(),
            File('$res/$carpeta/$png').readAsBytesSync(),
            reason: '$carpeta/$png difiere del logo actual; regenerar con GENERATE_ICONS=1',
          );
        }
      }
    },
  );
}
