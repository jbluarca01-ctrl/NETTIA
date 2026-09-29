import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un mensaje guardado de una conversación (sin el estado "en curso": solo
/// se guardan mensajes ya terminados).
class MensajeGuardado {
  const MensajeGuardado({required this.texto, required this.esUsuario});

  final String texto;
  final bool esUsuario;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'texto': texto,
        'esUsuario': esUsuario,
      };

  static MensajeGuardado? fromJson(Map<String, dynamic> j) {
    final texto = j['texto'] as String?;
    final esUsuario = j['esUsuario'] as bool?;
    if (texto == null || esUsuario == null) return null;
    return MensajeGuardado(texto: texto, esUsuario: esUsuario);
  }
}

/// Una conversación completa con NETIA: fecha de inicio, título (la primera
/// pregunta) y sus mensajes.
class Conversacion {
  const Conversacion({
    required this.id,
    required this.fecha,
    required this.titulo,
    required this.mensajes,
  });

  final String id;
  final DateTime fecha;
  final String titulo;
  final List<MensajeGuardado> mensajes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'fecha': fecha.toIso8601String(),
        'titulo': titulo,
        'mensajes': mensajes.map((m) => m.toJson()).toList(),
      };

  static Conversacion? fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String?;
    final fecha = switch (j['fecha']) {
      final String s => DateTime.tryParse(s),
      _ => null,
    };
    final titulo = j['titulo'] as String?;
    final crudos = j['mensajes'] as List?;
    if (id == null || fecha == null || titulo == null || crudos == null) {
      return null;
    }
    final mensajes = <MensajeGuardado>[
      for (final m in crudos)
        if (MensajeGuardado.fromJson(m as Map<String, dynamic>) case final x?) x,
    ];
    return Conversacion(id: id, fecha: fecha, titulo: titulo, mensajes: mensajes);
  }
}

/// Historial de conversaciones de NETIA, guardado en el teléfono
/// (`SharedPreferences`, privado de la app — no necesita ningún permiso,
/// igual que [FeedbackService]). Sobrevive a cerrar y volver a abrir la app.
class HistorialConversacionesService extends ChangeNotifier {
  HistorialConversacionesService._();
  static final HistorialConversacionesService instance =
      HistorialConversacionesService._();

  static const String _kConversaciones = 'nettia_historial_v1';
  static const int _maxConversaciones = 200;

  final List<Conversacion> _conversaciones = <Conversacion>[];
  SharedPreferences? _prefs;

  /// De la más reciente a la más vieja.
  List<Conversacion> get conversaciones {
    final copia = List<Conversacion>.of(_conversaciones)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return List<Conversacion>.unmodifiable(copia);
  }

  Future<void> load() async {
    _conversaciones.clear();
    try {
      final prefs = _prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kConversaciones);
      if (raw != null) {
        for (final c in jsonDecode(raw) as List<dynamic>) {
          final x = Conversacion.fromJson(c as Map<String, dynamic>);
          if (x != null) _conversaciones.add(x);
        }
      }
    } catch (e) {
      debugPrint('Nettia: no se pudo cargar el historial de conversaciones: $e');
    }
    notifyListeners();
  }

  /// Guarda [conversacion]: si ya existe una con el mismo id, la reemplaza
  /// (así el auto-guardado mientras la conversación sigue no duplica).
  Future<void> guardar(Conversacion conversacion) async {
    final i = _conversaciones.indexWhere((c) => c.id == conversacion.id);
    if (i >= 0) {
      _conversaciones[i] = conversacion;
    } else {
      _conversaciones.add(conversacion);
      if (_conversaciones.length > _maxConversaciones) {
        _conversaciones.removeAt(0);
      }
    }
    notifyListeners();
    await _persistir();
  }

  Future<void> eliminar(String id) async {
    _conversaciones.removeWhere((c) => c.id == id);
    notifyListeners();
    await _persistir();
  }

  Future<void> borrarTodo() async {
    _conversaciones.clear();
    notifyListeners();
    await _persistir();
  }

  Future<void> _persistir() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _kConversaciones,
      jsonEncode(_conversaciones.map((c) => c.toJson()).toList()),
    );
  }
}
