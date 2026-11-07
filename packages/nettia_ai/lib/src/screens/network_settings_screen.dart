import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import '../provider_style.dart';
import '../services/ai_settings_service.dart';
import 'comentarios_card.dart';
import 'motor_ia_card.dart';
import 'perfil_card.dart';

/// Pantalla de configuración del sistema de IA y preferencias de Nettia.
class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  AiSettingsService get _settings => AiSettingsService.instance;

  @override
  Widget build(BuildContext context) {
    // Se redibuja cuando cambia cualquiera de los servicios que muestra.
    return ListenableBuilder(
      listenable: Listenable.merge([
        _settings,
        AppearanceController.instance,
        UserProfileService.instance,
      ]),
      builder: (context, _) => _pantalla(context),
    );
  }

  Widget _pantalla(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primario = theme.colorScheme.primary;
    final terciario = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración & Sistema')),
      body: NetworkBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ..._seccion(NettiaIcons.perfil, 'Perfil de uso', primario, PerfilCard(isDark: isDark)),
            const SizedBox(height: 20),
            ..._seccion(NettiaIcons.apariencia, 'Apariencia', primario, _aparienciaCard()),
            const SizedBox(height: 20),
            ..._seccion(NettiaIcons.motorIa, 'Motor de Inteligencia Artificial (NETIA)',
                colorDeProveedor(_settings.activeProvider), const MotorIaCard()),
            const SizedBox(height: 20),
            ..._seccion(NettiaIcons.preferencias, 'Preferencias de Red & Ejecución', terciario, _offlineCard(primario)),
            const SizedBox(height: 20),
            ..._seccion(NettiaIcons.aviso, 'Comentarios sobre las respuestas', terciario, const ComentariosCard()),
            const SizedBox(height: 8),
            _sanitizarCard(primario),
          ],
        ),
      ),
    );
  }

  List<Widget> _seccion(IconData icon, String title, Color color, Widget tarjeta) {
    return [
      Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 12),
      tarjeta,
    ];
  }

  Widget _aparienciaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SegmentedButton<AppearanceMode>(
          segments: const [
            ButtonSegment(value: AppearanceMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode_outlined, size: 16)),
            ButtonSegment(value: AppearanceMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
            ButtonSegment(value: AppearanceMode.auto, label: Text('Automático'), icon: Icon(Icons.brightness_auto_outlined, size: 16)),
          ],
          selected: {AppearanceController.instance.mode},
          showSelectedIcon: false,
          onSelectionChanged: (sel) => AppearanceController.instance.setMode(sel.first),
        ),
      ),
    );
  }

  Widget _offlineCard(Color primario) {
    return Card(
      child: SwitchListTile(
        title: const Text('Forzar modo Offline para NETIA'),
        subtitle: const Text('Ignora la conexión a internet y utiliza siempre las heurísticas locales'),
        value: _settings.offlinePreferred,
        activeTrackColor: primario,
        onChanged: (val) => _settings.setOfflinePreferred(val),
      ),
    );
  }

  Widget _sanitizarCard(Color primario) {
    return Card(
      child: SwitchListTile(
        title: const Text('Ocultar datos sensibles antes de enviar a la IA'),
        subtitle: const Text('Enmascara contraseñas, comunidades SNMP, claves e IPs públicas de lo que escribas o pegues antes de mandarlo al proveedor en la nube'),
        value: _settings.sanitizeBeforeSend,
        activeTrackColor: primario,
        onChanged: (val) => _settings.setSanitizeBeforeSend(val),
      ),
    );
  }
}
