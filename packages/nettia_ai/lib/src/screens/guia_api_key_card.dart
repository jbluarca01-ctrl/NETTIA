import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ai_config_models.dart';
import 'aviso.dart';

/// Guía por proveedor: cómo obtener la API Key (mismo criterio que PRAXIA).
class GuiaApiKeyCard extends StatelessWidget {
  const GuiaApiKeyCard(this.tipo, {super.key});

  final AiProviderType tipo;

  /// Web donde se crea la clave y paso a paso, por proveedor.
  static const Map<AiProviderType, (String, String)> guias = {
    AiProviderType.nvidiaNim: (
      'https://build.nvidia.com',
      'Crea una cuenta en build.nvidia.com, entra a cualquier modelo NIM y genera una API Key desde el botón "Get API Key".',
    ),
    AiProviderType.openAi: (
      'https://platform.openai.com/api-keys',
      'En platform.openai.com/api-keys, pulsa "Create new secret key" y cópiala (solo se muestra una vez).',
    ),
    AiProviderType.gemini: (
      'https://aistudio.google.com/apikey',
      'En aistudio.google.com/apikey, pulsa "Create API key" con tu cuenta de Google.',
    ),
    AiProviderType.anthropic: (
      'https://console.anthropic.com',
      'En console.anthropic.com, ve a "API Keys" → "Create Key".',
    ),
    AiProviderType.openRouter: (
      'https://openrouter.ai/keys',
      'En openrouter.ai/keys, pulsa "Create Key" tras iniciar sesión.',
    ),
  };

  /// Sin `canLaunchUrl`: en Android 11+ responde false si el manifiesto no
  /// declara `<queries>`, aunque haya navegador.
  Future<void> _abrirWeb(BuildContext context, String url) async {
    final abierta = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!abierta && context.mounted) avisar(context, '⚠️ No se pudo abrir $url');
  }

  @override
  Widget build(BuildContext context) {
    final guia = guias[tipo];
    if (guia == null) return const SizedBox.shrink();
    final (url, pasos) = guia;
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
          Text(pasos, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _abrirWeb(context, url),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('Abrir ${tipo.displayName}'),
          ),
        ],
      ),
    );
  }
}
