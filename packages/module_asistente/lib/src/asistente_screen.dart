import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'historial_screen.dart';
import 'pie_verificacion.dart';
import 'respuesta_formateada.dart';
import 'typing_dots.dart';

/// Un turno de la conversación con NETIA (pregunta del técnico o respuesta
/// de la IA, esta última acumulándose token a token mientras `enCurso`).
class _NetiaMessage {
  String texto;
  final bool esUsuario;
  bool enCurso;

  /// Fragmentos de la base local que respaldaron esta respuesta y la pregunta
  /// (sanitizada) que la originó, para la insignia y los comentarios.
  List<FuenteLocalUsada> fuentes = const <FuenteLocalUsada>[];
  String preguntaOriginal = '';

  _NetiaMessage({
    required this.texto,
    required this.esUsuario,
    this.enCurso = false,
  });
}

/// Módulo independiente: chat con el asistente NETIA (IA).
///
/// Recibe el servicio de IA por contrato ([AiDiagnosisService]); no conoce
/// proveedores ni claves.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key, required this.aiService});

  final AiDiagnosisService aiService;

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final TextEditingController _netiaInputController = TextEditingController();
  final ScrollController _netiaScrollController = ScrollController();
  final List<_NetiaMessage> _netiaMessages = <_NetiaMessage>[];
  StreamSubscription<String>? _netiaSub;
  bool _netiaGenerando = false;
  _NetiaMessage? _netiaRespuestaActual;
  Timer? _netiaTicker;
  int _netiaSegundos = 0;

  /// `true` mientras el usuario está leyendo más arriba en la conversación:
  /// evita que cada token nuevo lo regrese al fondo a la fuerza.
  bool _netiaUsuarioSubioElScroll = false;

  /// Identidad de la conversación actual para el historial: nace con la
  /// primera pregunta (o al reabrir una guardada) y se conserva mientras
  /// dure, para que el auto-guardado actualice la misma entrada en vez de
  /// duplicarla.
  String? _conversacionId;
  DateTime? _conversacionFecha;

  @override
  void initState() {
    super.initState();
    _netiaScrollController.addListener(() {
      if (!_netiaScrollController.hasClients) return;
      final distanciaAlFondo = _netiaScrollController.position.maxScrollExtent -
          _netiaScrollController.offset;
      if (distanciaAlFondo > 100 && !_netiaUsuarioSubioElScroll) {
        setState(() => _netiaUsuarioSubioElScroll = true);
      } else if (distanciaAlFondo <= 30 && _netiaUsuarioSubioElScroll) {
        setState(() => _netiaUsuarioSubioElScroll = false);
      }
    });
  }

  @override
  void dispose() {
    _netiaInputController.dispose();
    _netiaScrollController.dispose();
    _netiaSub?.cancel();
    _netiaTicker?.cancel();
    widget.aiService.cancelarStream();
    super.dispose();
  }

  void _enviarPreguntaNetia() {
    final pregunta = _netiaInputController.text.trim();
    if (pregunta.isEmpty || _netiaGenerando) return;

    FocusScope.of(context).unfocus();
    _netiaInputController.clear();

    final respuestaIA = _NetiaMessage(
      texto: '',
      esUsuario: false,
      enCurso: true,
    );
    setState(() {
      _netiaMessages.add(_NetiaMessage(texto: pregunta, esUsuario: true));
      _netiaMessages.add(respuestaIA);
      _netiaGenerando = true;
      _netiaRespuestaActual = respuestaIA;
      _netiaSegundos = 0;
    });
    _conversacionId ??= DateTime.now().microsecondsSinceEpoch.toString();
    _conversacionFecha ??= DateTime.now();
    _netiaTicker?.cancel();
    _netiaTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _netiaSegundos++);
    });
    _scrollNetiaAlFinal(forzado: true);

    _netiaSub = widget.aiService
        .diagnosticarFallaStream(consultaUsuario: pregunta, categoria: 'NETIA')
        .listen(
          (token) {
            if (!mounted) return;
            setState(() => respuestaIA.texto += token);
            _scrollNetiaAlFinal();
          },
          onDone: () {
            _netiaTicker?.cancel();
            if (!mounted) return;
            final Object svc = widget.aiService;
            if (svc is ConFuentesLocales) {
              respuestaIA.fuentes = List<FuenteLocalUsada>.of(
                svc.fuentesUltimaRespuesta,
              );
              respuestaIA.preguntaOriginal = svc.sanitizarParaReporte(pregunta);
            }
            setState(() {
              respuestaIA.enCurso = false;
              _netiaGenerando = false;
            });
            _guardarConversacion();
          },
          onError: (Object e) {
            _netiaTicker?.cancel();
            if (!mounted) return;
            setState(() {
              respuestaIA.texto += '\n⚠️ Error al consultar a NETIA: $e';
              respuestaIA.enCurso = false;
              _netiaGenerando = false;
            });
            _guardarConversacion();
          },
        );
  }

  /// Guarda (o actualiza) la conversación actual en el historial persistente
  /// del teléfono. El título es la primera pregunta del usuario.
  void _guardarConversacion() {
    final id = _conversacionId;
    final fecha = _conversacionFecha;
    if (id == null || fecha == null || _netiaMessages.isEmpty) return;
    final primeraPregunta = _netiaMessages.firstWhere(
      (m) => m.esUsuario,
      orElse: () => _netiaMessages.first,
    );
    HistorialConversacionesService.instance.guardar(
      Conversacion(
        id: id,
        fecha: fecha,
        titulo: primeraPregunta.texto,
        mensajes: [
          for (final m in _netiaMessages)
            MensajeGuardado(texto: m.texto, esUsuario: m.esUsuario),
        ],
      ),
    );
  }

  /// Cierra la conversación actual (sin borrarla del historial) y deja el
  /// chat listo para empezar una nueva.
  void _nuevaConversacion() {
    if (_netiaGenerando) _detenerNetia();
    setState(() {
      _netiaMessages.clear();
      _conversacionId = null;
      _conversacionFecha = null;
    });
  }

  /// Abre el historial y, si el usuario elige una conversación, la recarga
  /// completa en el chat (el auto-guardado seguirá actualizando esa misma
  /// entrada, no una nueva).
  Future<void> _abrirHistorial() async {
    if (_netiaGenerando) _detenerNetia();
    final elegida = await Navigator.of(context).push<Conversacion>(
      MaterialPageRoute(builder: (_) => const HistorialScreen()),
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _netiaMessages
        ..clear()
        ..addAll([
          for (final m in elegida.mensajes)
            _NetiaMessage(texto: m.texto, esUsuario: m.esUsuario),
        ]);
      _conversacionId = elegida.id;
      _conversacionFecha = elegida.fecha;
    });
  }

  /// Detiene la generación en curso: cierra la conexión HTTP real (no solo la
  /// suscripción Dart) y deja la conversación lista para otra pregunta.
  void _detenerNetia() {
    if (!_netiaGenerando) return;
    widget.aiService.cancelarStream();
    _netiaSub?.cancel();
    _netiaSub = null;
    _netiaTicker?.cancel();
    final respuesta = _netiaRespuestaActual;
    setState(() {
      if (respuesta != null) {
        respuesta.enCurso = false;
        respuesta.texto = respuesta.texto.isEmpty
            ? '⚠️ Respuesta detenida por el usuario.'
            : '${respuesta.texto}\n\n⚠️ Respuesta detenida por el usuario.';
      }
      _netiaGenerando = false;
    });
  }

  /// Baja al fondo, salvo que el usuario haya subido a leer algo anterior:
  /// en ese caso solo se fuerza cuando [forzado] es `true` (pregunta nueva
  /// del propio usuario), nunca por un token que va llegando solo.
  void _scrollNetiaAlFinal({bool forzado = false}) {
    if (_netiaUsuarioSubioElScroll && !forzado) return;
    if (forzado) _netiaUsuarioSubioElScroll = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_netiaScrollController.hasClients) return;
      _netiaScrollController.animateTo(
        _netiaScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildNetiaTab(Theme.of(context)),
    );
  }

  Widget _buildNetiaTab(ThemeData theme) {
    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.add_comment_outlined, size: 20),
                tooltip: 'Nueva conversación',
                onPressed: _netiaMessages.isEmpty ? null : _nuevaConversacion,
              ),
              IconButton(
                icon: const Icon(Icons.history, size: 20),
                tooltip: 'Historial de conversaciones',
                onPressed: _abrirHistorial,
              ),
            ],
          ),
        ),
        _buildAvisoIa(theme),
        Expanded(
          child: _netiaMessages.isEmpty
              ? _buildBienvenida(theme)
              : ListView.builder(
                  controller: _netiaScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _netiaMessages.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _buildNetiaBubble(theme, _netiaMessages[index]),
                ),
        ),
        const SizedBox(height: 8),
        _buildCampoEntrada(theme),
      ],
    );
  }

  Widget _buildAvisoIa(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            NettiaIcons.aviso,
            size: 13,
            color: NetworkTheme.amberAlert,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Respuestas generadas por IA. Verifica siempre antes de aplicar en producción.',
              style: TextStyle(
                fontSize: 10.5,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBienvenida(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const NettiaAvatar(size: 56),
            const SizedBox(height: 16),
            Text(
              'Hola, soy NETIA',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pregúntame sobre VLANs, subneteo, enrutamiento o su convivencia '
              'con protocolos industriales (Modbus TCP, EtherNet/IP, Profinet).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(170),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo en forma de píldora con botón de envío circular (que pasa a
  /// "Detener" mientras NETIA responde).
  Widget _buildCampoEntrada(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _netiaInputController,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviarPreguntaNetia(),
              decoration: const InputDecoration(
                hintText: 'Escribe tu consulta de redes…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: IconButton.filled(
              tooltip: _netiaGenerando ? 'Detener' : 'Enviar',
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                minimumSize: const Size(44, 44),
              ),
              icon: Icon(
                _netiaGenerando ? NettiaIcons.detener : NettiaIcons.enviar,
                size: 22,
              ),
              onPressed: _netiaGenerando ? _detenerNetia : _enviarPreguntaNetia,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetiaBubble(ThemeData theme, _NetiaMessage msg) {
    if (msg.esUsuario) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(46),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: SelectableText(
            msg.texto,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
        ),
      );
    }

    // Respuesta de NETIA: texto plano con avatar "N" (sin burbuja).
    final esperando = msg.texto.isEmpty && msg.enCurso;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NettiaAvatar(size: 32, pensando: msg.enCurso),
          const SizedBox(width: 10),
          Expanded(
            child: esperando
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: <Widget>[
                        TypingDots(color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          '${_netiaSegundos}s',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(
                              140,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RespuestaFormateada(texto: msg.texto),
                      if (!msg.enCurso && msg.fuentes.isNotEmpty)
                        PieVerificacion(
                          fuentes: msg.fuentes,
                          pregunta: msg.preguntaOriginal,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
