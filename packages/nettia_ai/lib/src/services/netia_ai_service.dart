import 'dart:async';

import 'package:ai_core/ai_core.dart' as core;

import 'package:flutter/foundation.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:nettia_knowledge/nettia_knowledge.dart';
import '../netia_system_prompt.dart';
import '../privacy/sanitizador.dart';
import 'ai_settings_service.dart';
import 'offline_knowledge_base.dart';
import 'respuesta_local.dart';

/// Asistente NETIA de Nettia sobre el cliente de IA compartido (`ai_core`),
/// el mismo que usa PRAXIA: streaming SSE real por proveedor, errores tipados
/// y cancelación que cierra la conexión HTTP.
///
/// Sin conexión, con el modo offline forzado o con el proveedor "offline", se
/// responde desde la base de conocimiento local.
class NetiaAiService implements AiDiagnosisService, ConFuentesLocales {
  NetiaAiService({core.AiProviderFactory? factory})
      : _factory = factory ?? core.AiProviderFactory();

  final core.AiProviderFactory _factory;
  final AiSettingsService _settings = AiSettingsService.instance;
  core.ChatCompletionService? _activo;
  bool _cancelado = false;
  List<FuenteLocalUsada> _fuentes = const <FuenteLocalUsada>[];

  @override
  List<FuenteLocalUsada> get fuentesUltimaRespuesta => _fuentes;

  @override
  String sanitizarParaReporte(String texto) {
    final t = sanitizarDatosSensibles(texto).texto.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length > 160 ? '${t.substring(0, 160)}…' : t;
  }

  static List<FuenteLocalUsada> _comoFuentes(Iterable<ResultadoBusqueda> r) => [
        for (final x in r)
          FuenteLocalUsada(
            id: x.fragmento.id,
            titulo: x.fragmento.titulo,
            verificacion: x.fragmento.verificacion,
            tieneComandos: x.fragmento.tieneComandos,
            comandosProbados: x.fragmento.comandosProbados,
          ),
      ];

  /// Tiempo máximo hasta recibir la respuesta inicial del proveedor.
  static const Duration _timeoutInicial = Duration(seconds: 90);

  @override
  Stream<String> diagnosticarFallaStream({
    required String consultaUsuario,
    String datosPlaca = '',
    String infoManual = '',
    String categoria = 'NETIA',
  }) async* {
    cancelarStream();
    _cancelado = false;
    _fuentes = const <FuenteLocalUsada>[];

    final proveedor = _settings.activeProvider;
    if (_settings.offlinePreferred || !proveedor.usaApi) {
      yield* _respuestaOffline(consultaUsuario);
      return;
    }

    final coreTipo = proveedor.aiCore!;
    final key = _settings.getApiKey(proveedor);
    if (key.isEmpty) {
      yield '⚠️ **Falta la API Key de ${proveedor.displayName}.**\n\n'
          'Ve a **Configuración → Motor de Inteligencia Artificial** y pega tu '
          'clave, o activa el modo Offline.';
      return;
    }
    final modelo = _settings.getSelectedModel(proveedor);
    if (modelo.isEmpty) {
      yield '⚠️ **No has elegido un modelo para ${proveedor.displayName}.**\n\n'
          'Ve a **Configuración → Motor de Inteligencia Artificial**, pulsa '
          '"Probar conexión y cargar modelos" y selecciona uno.';
      return;
    }

    final locales = await _buscarLocal(consultaUsuario);
    _fuentes = _comoFuentes(locales);
    // Privacidad: lo que sale hacia el proveedor pasa antes por el sanitizador.
    var consultaSaliente = consultaUsuario;
    if (_settings.sanitizeBeforeSend) {
      final r = sanitizarDatosSensibles(consultaUsuario);
      consultaSaliente = r.texto;
      if (r.total > 0) {
        yield '🔒 _Antes de enviar a ${proveedor.displayName} se ocultaron: '
            '${r.resumen}. Puedes desactivarlo en Configuración._\n\n';
      }
    }

    // Si el modelo elegido está saturado (límite de tasa/cuota), se
    // reintenta solo con el siguiente del catálogo ya cargado — sin que el
    // usuario tenga que hacer nada — antes de rendirse con el aviso de
    // "límite alcanzado". Nunca cambia de modelo a mitad de una respuesta
    // que ya empezó a llegar (huboToken), solo antes del primer token.
    final candidatos = <String>[
      modelo,
      for (final m in _settings.getCatalogo(proveedor))
        if (m != modelo) m,
    ];

    for (var i = 0; i < candidatos.length; i++) {
      final modeloActual = candidatos[i];
      final servicio = _factory.getService(coreTipo);
      _activo = servicio;
      var huboToken = false;
      try {
        final config = core.AiProviderConfig(
          providerType: coreTipo,
          apiKey: key,
          modelId: modeloActual,
          timeout: _timeoutInicial,
          maxTokens: 4096,
        );
        final stream = servicio.enviarMensajeStream(
          mensajes: [
            core.AiChatMessage(
              role: core.AiMessageRole.system,
              content: netiaSystemPromptPara(UserProfileService.instance.profile),
            ),
            core.AiChatMessage(
              role: core.AiMessageRole.user,
              content: '$consultaSaliente\n\n${contextoRag(locales)}',
            ),
          ],
          config: config,
        );
        await for (final chunk in stream) {
          if (!huboToken) {
            huboToken = true;
            if (i > 0) {
              yield '🔁 _"${candidatos[i - 1]}" estaba saturado; cambié '
                  'automáticamente a **$modeloActual**._\n\n';
              await _settings.setSelectedModel(proveedor, modeloActual);
            }
          }
          yield chunk;
        }
        return;
      } on core.AiModelRetiredException catch (e) {
        yield '⚠️ **El modelo "$modeloActual" ya no está disponible en '
            '${proveedor.displayName}.**\n\nElige otro en **Configuración**.\n\n'
            '_${e.message}_';
        return;
      } on core.AiAuthException catch (e) {
        yield '⚠️ **Error de autenticación con ${proveedor.displayName}.**\n\n'
            'Revisa tu API Key en **Configuración**.\n\n_${e.message}_';
        return;
      } on core.AiRateLimitException catch (e) {
        final hayOtroCandidato = i < candidatos.length - 1;
        if (huboToken || !hayOtroCandidato) {
          yield '⚠️ **Límite de uso alcanzado en ${proveedor.displayName}.**\n\n'
              'Espera unos minutos e intenta de nuevo.\n\n_${e.message}_';
          return;
        }
        continue;
      } on core.AiTimeoutException {
        yield* _errorDeRedConRespaldo(
          consultaUsuario,
          '⏱️ **${proveedor.displayName} no respondió a tiempo.** Prueba con '
          'otro modelo en Configuración.',
        );
        return;
      } on core.AiNetworkException catch (e) {
        if (_cancelado) return;
        yield* _errorDeRedConRespaldo(
          consultaUsuario,
          '⚠️ **Sin conexión con ${proveedor.displayName}.** _${e.message}_',
        );
        return;
      } on core.AiServiceException catch (e) {
        if (_cancelado) return;
        yield '⚠️ **Error del servicio ${proveedor.displayName}.**\n\n_${e.message}_';
        return;
      } catch (e) {
        if (_cancelado) return;
        yield '⚠️ **Error inesperado al contactar ${proveedor.displayName}.**\n\n_${e}_';
        return;
      } finally {
        if (_activo == servicio) _activo = null;
      }
    }
  }

  /// Avisa del fallo de red y responde desde la base local para no dejar al
  /// alumno sin respuesta.
  Stream<String> _errorDeRedConRespaldo(String consulta, String aviso) async* {
    if (_cancelado) return;
    yield '$aviso\n\n_Respondiendo desde la base local:_\n\n';
    yield* _respuestaOffline(consulta);
  }

  /// Busca en la base local según el perfil (estudiante por defecto). Si la
  /// base no puede cargarse, se responde sin ella en vez de fallar.
  Future<List<ResultadoBusqueda>> _buscarLocal(String consulta) async {
    try {
      final base = await BaseConocimiento.instancia();
      return base.buscar(
        consulta,
        perfil: UserProfileService.instance.profile ?? UserProfile.estudiante,
      );
    } catch (e) {
      debugPrint('Nettia: no se pudo consultar la base local: $e');
      return const <ResultadoBusqueda>[];
    }
  }

  /// Respuesta sin conexión: extractiva desde el corpus con su fuente; si el
  /// corpus no tiene nada, la base heurística antigua (temas aún no migrados).
  Stream<String> _respuestaOffline(String consulta) async* {
    final locales = await _buscarLocal(consulta);
    // Offline solo se muestra el primer fragmento: solo ese respalda la respuesta.
    _fuentes = _comoFuentes(locales.take(1));
    final texto = locales.isNotEmpty
        ? respuestaExtractiva(locales)
        : generateOfflineResponse(consulta);
    // Se emite línea a línea para conservar el formato Markdown.
    final lineas = texto.split('\n');
    for (var i = 0; i < lineas.length; i++) {
      if (_cancelado) return;
      yield i == lineas.length - 1 ? lineas[i] : '${lineas[i]}\n';
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  @override
  void cancelarStream() {
    _cancelado = true;
    _activo?.cancelarStream();
    _activo = null;
  }
}
