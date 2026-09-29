import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_core/nettia_core.dart';

import 'src/screens/nettia_splash_screen.dart';
import 'src/shell/nettia_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AiSettingsService.instance.load();
  await UserProfileService.instance.load();
  await FeedbackService.instance.load();
  await HistorialConversacionesService.instance.load();
  runApp(const NettiaApp());
}

class NettiaApp extends StatefulWidget {
  const NettiaApp({super.key});

  @override
  State<NettiaApp> createState() => _NettiaAppState();
}

class _NettiaAppState extends State<NettiaApp> {
  final NetiaAiService _netiaService = NetiaAiService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AppearanceController.instance.addListener(_onAppearanceChanged);
  }

  @override
  void dispose() {
    AppearanceController.instance.removeListener(_onAppearanceChanged);
    super.dispose();
  }

  void _onAppearanceChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Nettia',
      debugShowCheckedModeBanner: false,
      themeMode: AppearanceController.instance.themeMode,
      theme: NetworkTheme.lightTheme,
      darkTheme: NetworkTheme.darkTheme,
      // Textos del sistema (diálogos, selectores, menús) en español.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // El perfil (estudiante/profesional) va antes que todo lo demás: sin
      // perfil guardado no se muestra ni el splash ni el menú.
      home: UserProfileService.instance.hasProfile
          ? _splash()
          : ProfileSelectionScreen(
              onSelected: () => _navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute<void>(builder: (_) => _splash()),
              ),
            ),
    );
  }

  Widget _splash() => NettiaSplashScreen(
        next: (context) => NettiaShell(aiService: _netiaService),
      );
}
