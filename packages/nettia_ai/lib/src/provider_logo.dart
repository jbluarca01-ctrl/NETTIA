import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:simple_icons/simple_icons.dart';

import 'models/ai_config_models.dart';

/// Marca en miniatura de cada proveedor de IA, teñida con su color.
///
/// Gemini, Anthropic, NVIDIA y OpenRouter usan el glifo de `simple_icons`.
/// OpenAI no está en ese paquete: se usa la imagen de su logo que aportó el
/// autor (`assets/openai_logo.webp`, fondo blanco con el nudo en negro), que no
/// se tiñe con el color del proveedor.
class ProviderLogo extends StatelessWidget {
  const ProviderLogo(this.provider, {super.key, this.size = 18, this.color});

  final AiProviderType provider;
  final double size;
  final Color? color;

  static IconData? _iconFor(AiProviderType provider) {
    switch (provider) {
      case AiProviderType.gemini:
        return SimpleIcons.googlegemini;
      case AiProviderType.anthropic:
        return SimpleIcons.anthropic;
      case AiProviderType.nvidiaNim:
        return SimpleIcons.nvidia;
      case AiProviderType.openRouter:
        return SimpleIcons.openrouter;
      case AiProviderType.offline:
        return NettiaIcons.offline;
      case AiProviderType.openAi:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(provider);
    if (icon != null) return Icon(icon, size: size, color: color);
    return Image.asset(
      'assets/openai_logo.webp',
      package: 'nettia_ai',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'OpenAI',
    );
  }
}
