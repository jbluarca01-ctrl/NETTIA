import 'package:flutter/material.dart';
import 'package:module_asistente/module_asistente.dart';
import 'package:module_calculadora/module_calculadora.dart';
import 'package:module_comandos/module_comandos.dart';
import 'package:module_guia/module_guia.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_core/nettia_core.dart';

import '../widgets/network_drawer.dart';

/// Ensambla los módulos independientes de Nettia. Cada índice del menú abre
/// SU pantalla; el shell solo aporta la barra superior y el menú lateral.
class NettiaShell extends StatefulWidget {
  const NettiaShell({super.key, required this.aiService});

  final AiDiagnosisService aiService;

  @override
  State<NettiaShell> createState() => _NettiaShellState();
}

class _NettiaShellState extends State<NettiaShell> {
  NettiaModulo _actual = NettiaModulo.calculadora;

  static const Map<NettiaModulo, String> _titulos = <NettiaModulo, String>{
    NettiaModulo.calculadora: 'Calculadora de Subredes',
    NettiaModulo.comandos: 'Comandos CLI & Plantillas',
    NettiaModulo.asistente: 'Asistente NETIA',
    NettiaModulo.guia: 'Guía Metodológica',
  };

  UserProfile get _perfil =>
      UserProfileService.instance.profile ?? UserProfile.estudiante;

  /// Módulos que el perfil activo puede usar.
  List<NettiaModulo> get _visibles =>
      NettiaModulo.values.where(_perfil.puedeUsar).toList();

  Widget _pantalla(NettiaModulo m) => switch (m) {
        NettiaModulo.calculadora => const CalculadoraScreen(),
        NettiaModulo.comandos => const ComandosScreen(),
        NettiaModulo.asistente => AsistenteScreen(aiService: widget.aiService),
        NettiaModulo.guia => const GuiaScreen(),
      };

  @override
  void initState() {
    super.initState();
    UserProfileService.instance.addListener(_onPerfilCambiado);
  }

  @override
  void dispose() {
    UserProfileService.instance.removeListener(_onPerfilCambiado);
    super.dispose();
  }

  /// Al cambiar de perfil se recarga el menú; si el módulo abierto deja de
  /// estar disponible, se vuelve al primero visible.
  void _onPerfilCambiado() {
    if (!mounted) return;
    setState(() {
      final visibles = _visibles;
      if (!visibles.contains(_actual)) _actual = visibles.first;
    });
  }

  void _abrirConfiguracion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NetworkSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NetworkBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: NetworkDrawer(
          profile: _perfil,
          current: _actual,
          onSelectModule: (m) {
            // Guarda de código: un módulo oculto para el perfil no se abre.
            if (_perfil.puedeUsar(m)) setState(() => _actual = m);
          },
          onOpenSettings: _abrirConfiguracion,
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(NettiaIcons.menu),
              tooltip: 'Menú',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              NettiaLogo(
                size: 22,
                color: theme.textTheme.bodyLarge?.color,
                accent: theme.colorScheme.primary,
                accent2: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _titulos[_actual]!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ListenableBuilder(
              listenable: AiSettingsService.instance,
              builder: (context, _) {
                final s = AiSettingsService.instance;
                final configurado =
                    s.currentActiveKey.isNotEmpty || !s.activeProvider.usaApi;
                return IconButton(
                  tooltip: 'Configuración & Sistema',
                  onPressed: _abrirConfiguracion,
                  icon: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(NettiaIcons.ajustes),
                      if (configurado)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: NetworkTheme.ledGreen,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        // IndexedStack conserva el estado de cada módulo (p. ej. el chat).
        body: IndexedStack(
          index: _visibles.indexOf(_actual),
          children: <Widget>[for (final m in _visibles) _pantalla(m)],
        ),
      ),
    );
  }
}
