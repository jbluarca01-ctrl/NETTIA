import 'package:ai_core/ai_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ai_config_models.dart';
import '../services/ai_settings_service.dart';
import 'package:nettia_core/nettia_core.dart';

import '../provider_logo.dart';
import '../provider_style.dart';

/// Pantalla de configuración del sistema de IA y preferencias de Nettia.
class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  final _settings = AiSettingsService.instance;
  late final TextEditingController _keyController;
  bool _obscureKey = true;
  bool _probandoConexion = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: _settings.getApiKey(_settings.activeProvider));
    _settings.addListener(_onSettingsChanged);
    AppearanceController.instance.addListener(_onAppearanceChanged);
    UserProfileService.instance.addListener(_onAppearanceChanged);
    FeedbackService.instance.addListener(_onAppearanceChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    AppearanceController.instance.removeListener(_onAppearanceChanged);
    UserProfileService.instance.removeListener(_onAppearanceChanged);
    FeedbackService.instance.removeListener(_onAppearanceChanged);
    _keyController.dispose();
    super.dispose();
  }

  void _onAppearanceChanged() {
    if (mounted) setState(() {});
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final currentKey = _settings.getApiKey(_settings.activeProvider);
    if (_keyController.text != currentKey) {
      _keyController.text = currentKey;
    }
    setState(() {});
  }

  /// Cambia el perfil tras confirmar: recarga el menú, el corpus y el tono
  /// del asistente.
  Future<void> _cambiarPerfil(UserProfile nuevo) async {
    if (nuevo == UserProfileService.instance.profile) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar de perfil'),
        content: Text(
          'Pasarás al perfil ${nuevo.etiqueta}. El menú y el tono del '
          'asistente se ajustarán a ese perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
    if (confirmado == true) await UserProfileService.instance.setProfile(nuevo);
  }

  void _guardarClave() {
    final key = _keyController.text.trim();
    _settings.setApiKey(_settings.activeProvider, key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(key.isEmpty
            ? 'API Key eliminada para ${_settings.activeProvider.displayName}'
            : 'API Key guardada para ${_settings.activeProvider.displayName}'),
        backgroundColor: colorDeProveedor(_settings.activeProvider),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Resultado de una acción: mensaje emergente (no queda fijo en pantalla).
  void _avisar(String mensaje) {
    if (!mounted) return;
    final ok = mensaje.startsWith('✅');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              ok ? NetworkTheme.ledGreen.withValues(alpha: 0.95) : null,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _probarConexion() async {
    final proveedor = _settings.activeProvider;
    if (!proveedor.usaApi) {
      _avisar('✅ Base de conocimiento local activa y lista.');
      return;
    }
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      _avisar('⚠️ Ingresa una API Key para probar la conexión.');
      return;
    }
    if (key != _settings.getApiKey(proveedor)) {
      await _settings.setApiKey(proveedor, key);
    }
    setState(() => _probandoConexion = true);
    try {
      final catalogo = await core.AiProviderFactory()
          .getService(proveedor.aiCore!)
          .listarModelos(apiKey: key)
          .timeout(const Duration(seconds: 20));
      final ids = catalogo
          .where((m) => m.funcion == core.FuncionIa.chat)
          .map((m) => m.modelId)
          .toSet()
          .toList()
        ..sort();
      if (!mounted) return;
      _settings.setCatalogo(proveedor, ids);
      _avisar(ids.isEmpty
          ? '⚠️ Conexión correcta, pero el proveedor no devolvió modelos de chat.'
          : '✅ Conexión correcta: ${ids.length} modelos disponibles. Elige uno.');
    } on core.AiAuthException {
      if (!mounted) return;
      _avisar('⚠️ La API Key no es válida para ${proveedor.displayName}.');
    } catch (e) {
      if (!mounted) return;
      _avisar('⚠️ No se pudo conectar con ${proveedor.displayName}: $e');
    } finally {
      if (mounted) setState(() => _probandoConexion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentProvider = _settings.activeProvider;
    final currentModel = _settings.getSelectedModel(currentProvider);
    final providerColor = colorDeProveedor(currentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración & Sistema')),
      body: NetworkBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ─── SECCIÓN: PERFIL ───────────────────────────────────────
            _buildSectionHeader(icon: NettiaIcons.perfil, title: 'Perfil de uso', color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<UserProfile>(
                      segments: [
                        for (final p in UserProfile.values)
                          ButtonSegment(
                            value: p,
                            label: Text(p.etiqueta),
                            icon: Icon(
                              p == UserProfile.estudiante ? NettiaIcons.estudiante : NettiaIcons.profesional,
                              size: 16,
                            ),
                          ),
                      ],
                      selected: {UserProfileService.instance.profile ?? UserProfile.estudiante},
                      showSelectedIcon: false,
                      onSelectionChanged: (sel) => _cambiarPerfil(sel.first),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (UserProfileService.instance.profile ?? UserProfile.estudiante).descripcion,
                      style: TextStyle(fontSize: 12.5, color: isDark ? NetworkTheme.darkTextSecondary : NetworkTheme.lightTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── SECCIÓN: APARIENCIA ────────────────────────────────────
            _buildSectionHeader(icon: NettiaIcons.apariencia, title: 'Apariencia', color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Card(
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
            ),
            const SizedBox(height: 20),

            // ─── SECCIÓN: PROVEEDOR DE IA ACTIVO ───────────────────────
            _buildSectionHeader(icon: NettiaIcons.motorIa, title: 'Motor de Inteligencia Artificial (NETIA)', color: providerColor),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona el proveedor para las consultas técnicas y de diagnóstico:',
                      style: TextStyle(fontSize: 13, color: isDark ? NetworkTheme.darkTextSecondary : NetworkTheme.lightTextSecondary),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AiProviderType.values.map((provider) {
                        final isSelected = provider == currentProvider;
                        final color = colorDeProveedor(provider);
                        return ChoiceChip(
                          avatar: ProviderLogo(provider, size: 18, color: color),
                          label: Text(provider.displayName),
                          selected: isSelected,
                          selectedColor: color.withValues(alpha: 0.22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(NetworkTheme.radiusLg),
                            side: BorderSide(color: isSelected ? color : Colors.transparent),
                          ),
                          onSelected: (selected) {
                            if (selected) _settings.setActiveProvider(provider);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (currentProvider != AiProviderType.offline) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text('API Key de ${currentProvider.displayName}:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _settings.currentActiveKey.isNotEmpty
                                  ? NetworkTheme.ledGreen.withValues(alpha: 0.15)
                                  : NetworkTheme.amberAlert.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(NetworkTheme.radiusSm),
                            ),
                            child: Text(
                              _settings.currentActiveKey.isNotEmpty ? 'CONFIGURADA' : 'SIN CLAVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _settings.currentActiveKey.isNotEmpty ? NetworkTheme.ledGreen : NetworkTheme.amberAlert,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keyController,
                        obscureText: _obscureKey,
                        style: NetworkTheme.mono(size: 13),
                        decoration: InputDecoration(
                          hintText: 'Pega tu clave de ${currentProvider.displayName}...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(NetworkTheme.radiusSm)),
                          isDense: true,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(_obscureKey ? NettiaIcons.mostrar : NettiaIcons.ocultar, size: 18),
                                tooltip: _obscureKey ? 'Mostrar' : 'Ocultar',
                                onPressed: () => setState(() => _obscureKey = !_obscureKey),
                              ),
                              IconButton(icon: const Icon(NettiaIcons.guardar, size: 18), tooltip: 'Guardar clave', onPressed: _guardarClave),
                            ],
                          ),
                        ),
                        onSubmitted: (_) => _guardarClave(),
                      ),
                      const SizedBox(height: 12),
                      _buildGuiaProveedorCard(currentProvider, isDark),
                      const SizedBox(height: 14),
                      const Text('Modelo seleccionado:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('${currentProvider.name}_model'),
                        initialValue: currentModel.isEmpty ? null : currentModel,
                        isExpanded: true,
                        hint: const Text('Pulsa "Probar conexión y cargar modelos"'),
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(NetworkTheme.radiusSm)), isDense: true),
                        items: <String>{
                          if (currentModel.isNotEmpty) currentModel,
                          ..._settings.getCatalogo(currentProvider),
                        }
                            .map((m) => DropdownMenuItem(value: m, child: Text(m, style: NetworkTheme.mono(size: 13), overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) _settings.setSelectedModel(currentProvider, val);
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: providerColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(NetworkTheme.radiusMd),
                          border: Border.all(color: providerColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(NettiaIcons.offline, color: providerColor),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Modo Offline activo: el asistente NETIA responderá consultas sobre VLANs, Router-on-a-stick, subredes y protocolos industriales sin consumir datos ni requerir API Keys.',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          icon: _probandoConexion
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(NettiaIcons.conexion, size: 16),
                          label: const Text('Probar conexión y cargar modelos'),
                          onPressed: _probandoConexion ? null : _probarConexion,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(icon: NettiaIcons.preferencias, title: 'Preferencias de Red & Ejecución', color: theme.colorScheme.tertiary),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Forzar modo Offline para NETIA'),
                subtitle: const Text('Ignora la conexión a internet y utiliza siempre las heurísticas locales'),
                value: _settings.offlinePreferred,
                activeTrackColor: theme.colorScheme.primary,
                onChanged: (val) => _settings.setOfflinePreferred(val),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(icon: NettiaIcons.aviso, title: 'Comentarios sobre las respuestas', color: theme.colorScheme.tertiary),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guardados en este teléfono: ${FeedbackService.instance.entradas.length}. Son tus "Me funcionó / No funcionó / Lo probé en Packet Tracer" sobre la base local. Nada se envía solo: si quieres, copia el reporte y mándaselo al autor.',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(NettiaIcons.copiar, size: 16),
                          label: const Text('Copiar reporte'),
                          onPressed: FeedbackService.instance.entradas.isEmpty
                              ? null
                              : () async {
                                  await Clipboard.setData(ClipboardData(text: FeedbackService.instance.reporte()));
                                  _avisar('✅ Reporte copiado. Pégalo en un mensaje para el autor.');
                                },
                        ),
                        TextButton(
                          onPressed: FeedbackService.instance.entradas.isEmpty ? null : () => FeedbackService.instance.borrarTodo(),
                          child: const Text('Borrar comentarios'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Ocultar datos sensibles antes de enviar a la IA'),
                subtitle: const Text('Enmascara contraseñas, comunidades SNMP, claves e IPs públicas de lo que escribas o pegues antes de mandarlo al proveedor en la nube'),
                value: _settings.sanitizeBeforeSend,
                activeTrackColor: theme.colorScheme.primary,
                onChanged: (val) => _settings.setSanitizeBeforeSend(val),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Guía por proveedor: cómo obtener la API Key (mismo criterio que PRAXIA) ──

  static const Map<AiProviderType, String> _guiaUrls = {
    AiProviderType.nvidiaNim: 'https://build.nvidia.com',
    AiProviderType.openAi: 'https://platform.openai.com/api-keys',
    AiProviderType.gemini: 'https://aistudio.google.com/apikey',
    AiProviderType.anthropic: 'https://console.anthropic.com',
    AiProviderType.openRouter: 'https://openrouter.ai/keys',
  };

  static const Map<AiProviderType, String> _guiaPasos = {
    AiProviderType.nvidiaNim:
        'Crea una cuenta en build.nvidia.com, entra a cualquier modelo NIM y genera una API Key desde el botón "Get API Key".',
    AiProviderType.openAi:
        'En platform.openai.com/api-keys, pulsa "Create new secret key" y cópiala (solo se muestra una vez).',
    AiProviderType.gemini:
        'En aistudio.google.com/apikey, pulsa "Create API key" con tu cuenta de Google.',
    AiProviderType.anthropic:
        'En console.anthropic.com, ve a "API Keys" → "Create Key".',
    AiProviderType.openRouter:
        'En openrouter.ai/keys, pulsa "Create Key" tras iniciar sesión.',
  };

  Widget _buildGuiaProveedorCard(AiProviderType tipo, bool isDark) {
    final url = _guiaUrls[tipo];
    if (url == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(NetworkTheme.radiusSm),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cómo obtener tu API Key de ${tipo.displayName}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _guiaPasos[tipo] ?? '',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (mounted) {
                _avisar('⚠️ No se pudo abrir $url');
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('Abrir ${tipo.displayName}'),
          ),
        ],
      ),
    );
  }
}
