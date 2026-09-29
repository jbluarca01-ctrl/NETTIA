import 'package:flutter/material.dart';

/// Modo de apariencia elegido por el usuario (independiente del tema del SO).
enum AppearanceMode { light, dark, auto }

/// Controlador simple de apariencia. `auto` delega en `ThemeMode.system`.
/// Reemplaza el guardado en memoria por `shared_preferences` si se quiere
/// persistir entre sesiones.
class AppearanceController extends ChangeNotifier {
  AppearanceController._();
  static final AppearanceController instance = AppearanceController._();

  AppearanceMode _mode = AppearanceMode.auto;
  AppearanceMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case AppearanceMode.light:
        return ThemeMode.light;
      case AppearanceMode.dark:
        return ThemeMode.dark;
      case AppearanceMode.auto:
        return ThemeMode.system;
    }
  }

  void setMode(AppearanceMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}

/// Sistema de diseño "Nettia".
///
/// - **Modo claro:** prensa técnica — papel claro, acentos cian/magenta
///   saturados (no pastel).
/// - **Modo oscuro:** inspirado en editores de código (paleta VS Code Dark+):
///   fondo casi negro, azul de palabra clave, verde-azulado de tipos y
///   naranja de cadenas/placeholders para los bloques de comandos.
class NetworkTheme {
  NetworkTheme._();

  // ─── Acentos compartidos (estado) ─────────────────────────────────────
  static const Color ledGreen = Color(0xFF27C93F);
  static const Color amberAlert = Color(0xFFFFBD2E);
  static const Color redDown = Color(0xFFFF5F56);
  static const Color purpleVlan = Color(0xFF7C6FF0);

  // ─── Modo Claro ────────────────────────────────────────────────────────
  static const Color lightBase = Color(0xFFF3F2F2);
  static const Color lightSurface = Color(0xFFEAE9E9);
  static const Color lightCard = Color(0xFFEAE9E9);
  static const Color lightBorder = Color(0xFFD7D3D3);
  static const Color lightTextPrimary = Color(0xFF201E1D);
  static const Color lightTextSecondary = Color(0xFF605D5D);
  static const Color fiberBlue = Color(0xFF0088B0);
  static const Color cyanOptical = Color(0xFF0088B0);
  static const Color lightAccent2 = Color(0xFFD6006C);

  // ─── Modo Oscuro (VS Code Dark+) ───────────────────────────────────────
  static const Color darkBase = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF252526);
  static const Color darkCard = Color(0xFF252526);
  static const Color darkCardElevated = Color(0xFF2D2D2D);
  static const Color darkBorder = Color(0xFF3C3C3C);
  static const Color darkBorderSubtle = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFD4D4D4);
  static const Color darkTextSecondary = Color(0xFFC5C5C5);
  static const Color darkTextMuted = Color(0xFF8A8A8A);
  static const Color darkAccentBlue = Color(0xFF3FA7FF);
  static const Color darkAccentTeal = Color(0xFF4EC9B0);

  /// Fondo/letra fijos para bloques de código (siempre oscuros,
  /// independientemente del tema de la app — como un editor).
  static const Color ink = Color(0xFF161719);
  static const Color inkFg = Color(0xFF6CB6FF);
  static const Color inkPlaceholder = Color(0xFFCE9178);
  static const Color inkMuted = Color(0xFF6A6A6A);

  static const List<String> monoFallback = <String>[
    'monospace',
    'Roboto Mono',
    'Menlo',
    'Courier New',
    'Courier',
  ];

  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.3,
  }) {
    return TextStyle(
      fontFamilyFallback: monoFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle title({double size = 16, FontWeight weight = FontWeight.bold, Color? color}) {
    return TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.1);
  }

  // Esquinas redondeadas (antes casi cuadradas): usar en tarjetas, chips,
  // diálogos y campos para que coincida con el mockup.
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: fiberBlue,
    onPrimary: Colors.white,
    secondary: fiberBlue,
    onSecondary: Colors.white,
    tertiary: lightAccent2,
    onTertiary: Colors.white,
    error: redDown,
    onError: Colors.white,
    surface: lightSurface,
    onSurface: lightTextPrimary,
    surfaceContainerHighest: Color(0xFFE2E8F0),
    surfaceContainerHigh: Color(0xFFF1F5F9),
    surfaceContainer: lightSurface,
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainerLowest: Colors.white,
    onSurfaceVariant: lightTextSecondary,
    outline: lightBorder,
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF0F172A),
    onInverseSurface: Colors.white,
    inversePrimary: darkAccentBlue,
  );

  static ThemeData get lightTheme {
    const colorScheme = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBase,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBase,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), space: 1, thickness: 1),
    );
  }

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkAccentBlue,
    onPrimary: Color(0xFF04101C),
    secondary: darkAccentBlue,
    onSecondary: Colors.white,
    tertiary: darkAccentTeal,
    onTertiary: Color(0xFF04211B),
    error: redDown,
    onError: Colors.white,
    surface: darkSurface,
    onSurface: darkTextPrimary,
    surfaceContainerHighest: darkCardElevated,
    surfaceContainerHigh: darkCardElevated,
    surfaceContainer: darkSurface,
    surfaceContainerLow: darkBase,
    surfaceContainerLowest: Color(0xFF141414),
    onSurfaceVariant: darkTextSecondary,
    outline: darkBorder,
    outlineVariant: darkBorderSubtle,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: darkTextPrimary,
    onInverseSurface: darkBase,
    inversePrimary: fiberBlue,
  );

  static ThemeData get darkTheme {
    const colorScheme = _darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBase,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBase,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      dividerTheme: const DividerThemeData(color: darkBorderSubtle, space: 1, thickness: 1),
    );
  }
}
