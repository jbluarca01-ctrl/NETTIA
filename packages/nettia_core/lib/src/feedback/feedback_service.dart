import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Qué opinó el usuario de un fragmento de la base local.
enum VeredictoFragmento {
  funciono('Me funcionó'),
  noFunciono('No funcionó'),
  probadoEnPt('Lo probé en Packet Tracer y funciona');

  const VeredictoFragmento(this.etiqueta);
  final String etiqueta;

  static VeredictoFragmento? fromName(String? n) {
    for (final v in VeredictoFragmento.values) {
      if (v.name == n) return v;
    }
    return null;
  }
}

/// Un comentario sobre un fragmento. **No** guarda la pregunta completa: solo
/// una versión sanitizada y recortada, para que el reporte pueda compartirse.
class EntradaFeedback {
  const EntradaFeedback({
    required this.fecha,
    required this.fragmentoId,
    required this.veredicto,
    this.pregunta = '',
    this.nota = '',
  });

  final DateTime fecha;
  final String fragmentoId;
  final VeredictoFragmento veredicto;
  final String pregunta;
  final String nota;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fecha': fecha.toIso8601String(),
        'fragmento': fragmentoId,
        'veredicto': veredicto.name,
        'pregunta': pregunta,
        'nota': nota,
      };

  static EntradaFeedback? fromJson(Map<String, dynamic> j) {
    final v = VeredictoFragmento.fromName(j['veredicto'] as String?);
    final f = DateTime.tryParse(_texto(j, 'fecha'));
    final id = j['fragmento'] as String?;
    if (v == null || f == null || id == null) return null;
    return EntradaFeedback(
      fecha: f,
      fragmentoId: id,
      veredicto: v,
      pregunta: _texto(j, 'pregunta'),
      nota: _texto(j, 'nota'),
    );
  }

  static String _texto(Map<String, dynamic> j, String clave) => j[clave] as String? ?? '';
}

/// Comentarios del usuario sobre las respuestas, guardados en el teléfono. El
/// autor los recibe cuando el usuario **copia el reporte y se lo envía**; nada
/// sale solo de la app.
class FeedbackService extends ChangeNotifier {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  static const String _kEntradas = 'nettia_feedback_v1';
  static const int _maxEntradas = 500;

  final List<EntradaFeedback> _entradas = <EntradaFeedback>[];
  SharedPreferences? _prefs;

  List<EntradaFeedback> get entradas => List<EntradaFeedback>.unmodifiable(_entradas);

  Future<void> load() async {
    _entradas.clear();
    try {
      final prefs = _prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kEntradas);
      if (raw != null) {
        for (final e in jsonDecode(raw) as List<dynamic>) {
          final x = EntradaFeedback.fromJson(e as Map<String, dynamic>);
          if (x != null) _entradas.add(x);
        }
      }
    } catch (e) {
      debugPrint('Nettia: no se pudieron cargar los comentarios: $e');
    }
    notifyListeners();
  }

  Future<void> registrar(EntradaFeedback entrada) async {
    _entradas.add(entrada);
    if (_entradas.length > _maxEntradas) {
      _entradas.removeRange(0, _entradas.length - _maxEntradas);
    }
    notifyListeners();
    await _guardar();
  }

  Future<void> borrarTodo() async {
    _entradas.clear();
    notifyListeners();
    await _guardar();
  }

  Future<void> _guardar() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _kEntradas,
      jsonEncode(_entradas.map((e) => e.toJson()).toList()),
    );
  }

  /// Texto listo para pegar en un mensaje al autor: un renglón por comentario.
  String reporte() {
    final b = StringBuffer('Comentarios de Nettia (${_entradas.length})\n');
    for (final e in _entradas) {
      final f = e.fecha.toIso8601String().substring(0, 10);
      b.write('- $f | ${e.fragmentoId} | ${e.veredicto.etiqueta}');
      if (e.pregunta.isNotEmpty) b.write(' | pregunta: ${e.pregunta}');
      if (e.nota.isNotEmpty) b.write(' | nota: ${e.nota}');
      b.writeln();
    }
    return b.toString();
  }
}
