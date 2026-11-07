import 'package:ai_core/ai_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import '../models/ai_config_models.dart';
import '../provider_logo.dart';
import '../provider_style.dart';
import '../services/ai_settings_service.dart';
import 'aviso.dart';
import 'guia_api_key_card.dart';

/// Tarjeta del motor de IA: proveedor activo, API Key, guía, modelo y
/// "Probar conexión y cargar modelos".
class MotorIaCard extends StatefulWidget {
  const MotorIaCard({super.key, this.fabrica});

  /// Fábrica de adaptadores de `ai_core`; los tests inyectan una falsa.
  final core.AiProviderFactory? fabrica;

  @override
  State<MotorIaCard> createState() => _MotorIaCardState();
}

class _MotorIaCardState extends State<MotorIaCard> {
  final _settings = AiSettingsService.instance;
  late final TextEditingController _keyController;
  bool _obscureKey = true;
  bool _probandoConexion = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: _settings.getApiKey(_settings.activeProvider));
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _keyController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    final currentKey = _settings.getApiKey(_settings.activeProvider);
    if (_keyController.text != currentKey) {
      _keyController.text = currentKey;
    }
    setState(() {});
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

  /// Ids de los modelos de chat del proveedor, ordenados y sin repetir.
  Future<List<String>> _cargarCatalogo(AiProviderType proveedor, String key) async {
    final catalogo = await (widget.fabrica ?? core.AiProviderFactory())
        .getService(proveedor.aiCore!)
        .listarModelos(apiKey: key)
        .timeout(const Duration(seconds: 20));
    return catalogo
        .where((m) => m.funcion == core.FuncionIa.chat)
        .map((m) => m.modelId)
        .toSet()
        .toList()
      ..sort();
  }

  /// La clave con la que probar (guardada si cambió), o `null` si no hay que
  /// probar nada: modo local o campo vacío (ya avisado).
  Future<String?> _claveParaProbar(AiProviderType proveedor) async {
    if (!proveedor.usaApi) {
      avisar(context, '✅ Base de conocimiento local activa y lista.');
      return null;
    }
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      avisar(context, '⚠️ Ingresa una API Key para probar la conexión.');
      return null;
    }
    await _settings.setApiKey(proveedor, key);
    return key;
  }

  Future<void> _probarConexion() async {
    final proveedor = _settings.activeProvider;
    final key = await _claveParaProbar(proveedor);
    if (key == null) return;
    setState(() => _probandoConexion = true);
    final mensaje = await _resultadoDePrueba(proveedor, key);
    if (!mounted) return;
    avisar(context, mensaje);
    setState(() => _probandoConexion = false);
  }

  /// Mensaje con el resultado de probar [key]; si conecta, guarda el catálogo.
  Future<String> _resultadoDePrueba(AiProviderType proveedor, String key) async {
    try {
      final ids = await _cargarCatalogo(proveedor, key);
      _settings.setCatalogo(proveedor, ids);
      return ids.isEmpty
          ? '⚠️ Conexión correcta, pero el proveedor no devolvió modelos de chat.'
          : '✅ Conexión correcta: ${ids.length} modelos disponibles. Elige uno.';
    } on core.AiAuthException {
      return '⚠️ La API Key no es válida para ${proveedor.displayName}.';
    } catch (e) {
      return '⚠️ No se pudo conectar con ${proveedor.displayName}: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentProvider = _settings.activeProvider;
    return Card(
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
            _selectorProveedor(currentProvider),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (currentProvider != AiProviderType.offline)
              ..._camposApi(currentProvider)
            else
              _bannerOffline(colorDeProveedor(currentProvider)),
            const SizedBox(height: 16),
            Row(children: [_botonProbar()]),
          ],
        ),
      ),
    );
  }

  Widget _selectorProveedor(AiProviderType currentProvider) {
    return Wrap(
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
          onSelected: (_) => _settings.setActiveProvider(provider),
        );
      }).toList(),
    );
  }

  List<Widget> _camposApi(AiProviderType currentProvider) {
    return [
      _estadoClave(currentProvider),
      const SizedBox(height: 8),
      _campoClave(currentProvider),
      const SizedBox(height: 12),
      GuiaApiKeyCard(currentProvider),
      const SizedBox(height: 14),
      const Text('Modelo seleccionado:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      _selectorModelo(currentProvider),
    ];
  }

  Widget _estadoClave(AiProviderType currentProvider) {
    final configurada = _settings.currentActiveKey.isNotEmpty;
    final color = configurada ? NetworkTheme.ledGreen : NetworkTheme.amberAlert;
    return Row(
      children: [
        Expanded(
          child: Text('API Key de ${currentProvider.displayName}:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(NetworkTheme.radiusSm),
          ),
          child: Text(
            configurada ? 'CONFIGURADA' : 'SIN CLAVE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _campoClave(AiProviderType currentProvider) {
    return TextField(
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
    );
  }

  Widget _selectorModelo(AiProviderType currentProvider) {
    final currentModel = _settings.getSelectedModel(currentProvider);
    return DropdownButtonFormField<String>(
      key: ValueKey(currentProvider),
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
    );
  }

  Widget _bannerOffline(Color providerColor) {
    return Container(
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
    );
  }

  Widget _botonProbar() {
    return FilledButton.tonalIcon(
      icon: _probandoConexion
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(NettiaIcons.conexion, size: 16),
      label: const Text('Probar conexión y cargar modelos'),
      onPressed: _probandoConexion ? null : _probarConexion,
    );
  }
}
