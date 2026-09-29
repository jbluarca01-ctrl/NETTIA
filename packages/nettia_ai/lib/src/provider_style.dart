import 'package:flutter/material.dart';

import 'models/ai_config_models.dart';

/// Color de marca por proveedor de IA.
Color colorDeProveedor(AiProviderType provider) {
  switch (provider) {
    case AiProviderType.gemini:
      return const Color(0xFF4E8CF4);
    case AiProviderType.openAi:
      return const Color(0xFF12A187);
    case AiProviderType.anthropic:
      return const Color(0xFFD97757);
    case AiProviderType.openRouter:
      return const Color(0xFF7C6FF0);
    case AiProviderType.nvidiaNim:
      return const Color(0xFF76B900);
    case AiProviderType.offline:
      return const Color(0xFF9B9797);
  }
}
