import 'package:ai_core/ai_core.dart' as core;

/// Proveedores de IA de Nettia (los mismos de PRAXIA, más el modo offline local).
enum AiProviderType {
  gemini,
  openAi,
  anthropic,
  openRouter,
  nvidiaNim,
  offline;

  String get displayName {
    switch (this) {
      case AiProviderType.gemini:
        return 'Google Gemini';
      case AiProviderType.openAi:
        return 'OpenAI';
      case AiProviderType.anthropic:
        return 'Anthropic Claude';
      case AiProviderType.openRouter:
        return 'OpenRouter';
      case AiProviderType.nvidiaNim:
        return 'NVIDIA NIM';
      case AiProviderType.offline:
        return 'Modo Offline (Base Local)';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case AiProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AiProviderType.openAi:
        return 'https://api.openai.com/v1';
      case AiProviderType.anthropic:
        return 'https://api.anthropic.com/v1';
      case AiProviderType.openRouter:
        return 'https://openrouter.ai/api/v1';
      case AiProviderType.nvidiaNim:
        return 'https://integrate.api.nvidia.com/v1';
      case AiProviderType.offline:
        return 'local://embedded';
    }
  }

  /// `false` para el modo offline local, que no usa API ni modelo.
  bool get usaApi => this != AiProviderType.offline;

  /// Equivalente en `ai_core` (`null` para el modo offline).
  core.AiProviderType? get aiCore {
    switch (this) {
      case AiProviderType.gemini:
        return core.AiProviderType.gemini;
      case AiProviderType.openAi:
        return core.AiProviderType.openAi;
      case AiProviderType.anthropic:
        return core.AiProviderType.anthropic;
      case AiProviderType.openRouter:
        return core.AiProviderType.openRouter;
      case AiProviderType.nvidiaNim:
        return core.AiProviderType.nvidiaNim;
      case AiProviderType.offline:
        return null;
    }
  }

  static AiProviderType fromString(String value) {
    final norm = value.toLowerCase().trim();
    for (final p in AiProviderType.values) {
      if (p.name.toLowerCase() == norm) return p;
    }
    if (norm == 'google' || norm == 'gemini_api') return AiProviderType.gemini;
    if (norm == 'openai') return AiProviderType.openAi;
    if (norm == 'claude' || norm == 'anthropic') return AiProviderType.anthropic;
    if (norm == 'openrouter') return AiProviderType.openRouter;
    if (norm == 'nvidia' || norm == 'nvidia_nim') return AiProviderType.nvidiaNim;
    return AiProviderType.gemini;
  }
}
