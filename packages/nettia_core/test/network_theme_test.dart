import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

void main() {
  group('AppearanceController', () {
    test('modo por defecto es auto y mapea a ThemeMode.system', () {
      final c = AppearanceController.instance;
      c.setMode(AppearanceMode.auto);
      expect(c.mode, AppearanceMode.auto);
      expect(c.themeMode, ThemeMode.system);
    });

    test('light y dark mapean directo a su ThemeMode', () {
      final c = AppearanceController.instance;
      c.setMode(AppearanceMode.light);
      expect(c.themeMode, ThemeMode.light);
      c.setMode(AppearanceMode.dark);
      expect(c.themeMode, ThemeMode.dark);
    });

    test('cambiar a un modo distinto avisa a los listeners', () {
      final c = AppearanceController.instance;
      c.setMode(AppearanceMode.auto);
      var avisos = 0;
      c.addListener(() => avisos++);
      c.setMode(AppearanceMode.dark);
      expect(avisos, 1);
      c.removeListener(() {});
    });

    test('poner el mismo modo otra vez no avisa (no-op)', () {
      final c = AppearanceController.instance;
      c.setMode(AppearanceMode.dark);
      var avisos = 0;
      void listener() => avisos++;
      c.addListener(listener);
      c.setMode(AppearanceMode.dark);
      expect(avisos, 0);
      c.removeListener(listener);
    });
  });

  group('NetworkTheme.mono', () {
    test('valores por defecto', () {
      final s = NetworkTheme.mono();
      expect(s.fontSize, 13);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.letterSpacing, 0.3);
      expect(s.fontFamilyFallback, ['monospace', 'Roboto Mono', 'Menlo', 'Courier New', 'Courier']);
    });

    test('se pueden sobrescribir tamaño, peso, color y espaciado', () {
      final s = NetworkTheme.mono(size: 20, weight: FontWeight.bold, color: Colors.red, letterSpacing: 1);
      expect(s.fontSize, 20);
      expect(s.fontWeight, FontWeight.bold);
      expect(s.color, Colors.red);
      expect(s.letterSpacing, 1);
    });
  });

  group('NetworkTheme.title', () {
    test('valores por defecto', () {
      final s = NetworkTheme.title();
      expect(s.fontSize, 16);
      expect(s.fontWeight, FontWeight.bold);
      expect(s.letterSpacing, 0.1);
    });
  });

  group('NetworkTheme radios (valores fijos, no contra la constante)', () {
    // Comparar contra NetworkTheme.radiusX sería tautológico: si el mutante
    // cambia el valor de la constante, el mismo cambio aparecería a los dos
    // lados de la comparación y el test nunca fallaría.
    test('radiusSm/Md/Lg tienen los valores del mockup', () {
      expect(NetworkTheme.radiusSm, 10);
      expect(NetworkTheme.radiusMd, 16);
      expect(NetworkTheme.radiusLg, 22);
    });
  });

  group('NetworkTheme.lightTheme / darkTheme', () {
    test('lightTheme usa Brightness.light y los radios declarados', () {
      final t = NetworkTheme.lightTheme;
      expect(t.brightness, Brightness.light);
      expect(t.scaffoldBackgroundColor, NetworkTheme.lightBase);
      final shape = t.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
      final dialogShape = t.dialogTheme.shape as RoundedRectangleBorder;
      expect(dialogShape.borderRadius, BorderRadius.circular(22));
    });

    test('darkTheme usa Brightness.dark y los radios declarados', () {
      final t = NetworkTheme.darkTheme;
      expect(t.brightness, Brightness.dark);
      expect(t.scaffoldBackgroundColor, NetworkTheme.darkBase);
      final shape = t.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    test('radiusSm se usa en el borde de los campos de texto', () {
      final t = NetworkTheme.lightTheme;
      final border = t.inputDecorationTheme.border as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(10));
    });
  });
}
