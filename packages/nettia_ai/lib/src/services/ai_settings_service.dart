import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_config_models.dart';

/// Configuración de IA de Nettia. Las API Keys se guardan cifradas en
/// `flutter_secure_storage` (nunca en texto plano ni embebidas en la app);
/// proveedor, modelo y preferencias en `shared_preferences`.
///
/// El modelo NUNCA se elige por cuenta propia: el usuario lo selecciona
/// manualmente del catálogo que devuelve el proveedor (mismo criterio que
/// PRAXIA). Sin selección, [getSelectedModel] devuelve cadena vacía.
///
/// Llamar `await AiSettingsService.instance.load()` antes de `runApp`.
class AiSettingsService extends ChangeNotifier {
  AiSettingsService._();
  static final AiSettingsService instance = AiSettingsService._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage();
  static const String _kProvider = 'nettia_active_provider';
  static const String _kOffline = 'nettia_offline_preferred';
  static const String _kSanitize = 'nettia_sanitize_before_send';
  static String _kKey(AiProviderType p) => 'nettia_api_key_${p.name}';
  static String _kModel(AiProviderType p) => 'nettia_model_${p.name}';

  AiProviderType _activeProvider = AiProviderType.nvidiaNim;
  final Map<AiProviderType, String> _apiKeys = {};
  final Map<AiProviderType, String> _selectedModels = {};

  /// Último catálogo de modelos de chat que devolvió cada proveedor.
  /// Vive en memoria mientras dure la sesión (no en disco: se refresca con
  /// "Probar conexión"), pero al ser parte de este singleton de toda la app
  /// sobrevive a que la pantalla de Configuración se cierre y se reabra —
  /// antes se guardaba en el estado local de esa pantalla y se perdía.
  final Map<AiProviderType, List<String>> _catalogos = {};
  bool _offlinePreferred = false;
  bool _sanitizeBeforeSend = true;
  bool _loaded = false;
  SharedPreferences? _prefs;

  AiProviderType get activeProvider => _activeProvider;
  bool get offlinePreferred => _offlinePreferred;

  /// Oculta contraseñas, claves, IPs públicas, etc. antes de enviar texto a un
  /// proveedor de IA en la nube. Activado por defecto.
  bool get sanitizeBeforeSend => _sanitizeBeforeSend;
  bool get isLoaded => _loaded;

  String getApiKey(AiProviderType provider) => _apiKeys[provider] ?? '';
  String getSelectedModel(AiProviderType provider) =>
      _selectedModels[provider] ?? '';

  /// Modelos de chat que devolvió la última vez que se probó la conexión de
  /// [provider] (vacío si nunca se cargó en esta sesión).
  List<String> getCatalogo(AiProviderType provider) =>
      List<String>.unmodifiable(_catalogos[provider] ?? const <String>[]);

  /// Reemplaza el catálogo cacheado de [provider] (llamado tras "Probar
  /// conexión y cargar modelos").
  void setCatalogo(AiProviderType provider, List<String> modelos) {
    _catalogos[provider] = List<String>.of(modelos);
    notifyListeners();
  }
  String get currentActiveKey => getApiKey(_activeProvider);
  String get currentActiveModel => getSelectedModel(_activeProvider);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      final saved = prefs.getString(_kProvider);
      if (saved != null) _activeProvider = AiProviderType.fromString(saved);
      _offlinePreferred = prefs.getBool(_kOffline) ?? false;
      _sanitizeBeforeSend = prefs.getBool(_kSanitize) ?? true;
      for (final p in AiProviderType.values) {
        final model = prefs.getString(_kModel(p));
        if (model != null && model.isNotEmpty) _selectedModels[p] = model;
        if (!p.usaApi) continue;
        final key = await _secure.read(key: _kKey(p));
        if (key != null && key.isNotEmpty) _apiKeys[p] = key;
      }
    } catch (e) {
      debugPrint('Nettia: no se pudo cargar la configuración de IA: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<SharedPreferences?> _p() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> setActiveProvider(AiProviderType provider) async {
    _activeProvider = provider;
    notifyListeners();
    await (await _p())?.setString(_kProvider, provider.name);
  }

  Future<void> setApiKey(AiProviderType provider, String key) async {
    final limpia = key.trim();
    if (limpia.isEmpty) {
      _apiKeys.remove(provider);
    } else {
      _apiKeys[provider] = limpia;
    }
    notifyListeners();
    try {
      if (limpia.isEmpty) {
        await _secure.delete(key: _kKey(provider));
      } else {
        await _secure.write(key: _kKey(provider), value: limpia);
      }
    } catch (e) {
      debugPrint('Nettia: no se pudo guardar la API Key: $e');
    }
  }

  Future<void> setSelectedModel(AiProviderType provider, String model) async {
    final limpio = model.trim();
    if (limpio.isEmpty) {
      _selectedModels.remove(provider);
    } else {
      _selectedModels[provider] = limpio;
    }
    notifyListeners();
    final prefs = await _p();
    if (limpio.isEmpty) {
      await prefs?.remove(_kModel(provider));
    } else {
      await prefs?.setString(_kModel(provider), limpio);
    }
  }

  Future<void> setOfflinePreferred(bool value) async {
    _offlinePreferred = value;
    notifyListeners();
    await (await _p())?.setBool(_kOffline, value);
  }

  Future<void> setSanitizeBeforeSend(bool value) async {
    _sanitizeBeforeSend = value;
    notifyListeners();
    await (await _p())?.setBool(_kSanitize, value);
  }
}
