import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FeedbackService.instance.load();
  });

  test('registra, persiste y recupera al recargar', () async {
    await FeedbackService.instance.registrar(EntradaFeedback(
      fecha: DateTime(2026, 9, 20),
      fragmentoId: 'ipv6-eui64',
      veredicto: VeredictoFragmento.noFunciono,
      pregunta: 'como funciona eui-64',
      nota: 'el ejemplo no coincide',
    ));
    expect(FeedbackService.instance.entradas, hasLength(1));

    await FeedbackService.instance.load(); // simula reiniciar la app
    final e = FeedbackService.instance.entradas.single;
    expect(e.fragmentoId, 'ipv6-eui64');
    expect(e.veredicto, VeredictoFragmento.noFunciono);
    expect(e.nota, 'el ejemplo no coincide');
  });

  test('el reporte lista un renglón por comentario', () async {
    await FeedbackService.instance.registrar(EntradaFeedback(
      fecha: DateTime(2026, 9, 20),
      fragmentoId: 'router-on-a-stick',
      veredicto: VeredictoFragmento.probadoEnPt,
    ));
    final r = FeedbackService.instance.reporte();
    expect(r, contains('Comentarios de Nettia (1)'));
    expect(r, contains('2026-09-20 | router-on-a-stick | Lo probé en Packet Tracer y funciona'));
  });

  test('borrar limpia también lo guardado', () async {
    await FeedbackService.instance.registrar(EntradaFeedback(
      fecha: DateTime(2026, 9, 20),
      fragmentoId: 'x',
      veredicto: VeredictoFragmento.funciono,
    ));
    await FeedbackService.instance.borrarTodo();
    await FeedbackService.instance.load();
    expect(FeedbackService.instance.entradas, isEmpty);
  });

  test('ignora entradas guardadas con formato inválido', () async {
    SharedPreferences.setMockInitialValues({
      'nettia_feedback_v1':
          '[{"fecha":"basura","fragmento":"a","veredicto":"funciono"},{"fecha":"2026-09-20T00:00:00.000","fragmento":"b","veredicto":"funciono"}]',
    });
    await FeedbackService.instance.load();
    expect(FeedbackService.instance.entradas.map((e) => e.fragmentoId), ['b']);
  });

  test('un valor guardado que no es JSON válido deja la lista vacía sin lanzar', () async {
    SharedPreferences.setMockInitialValues({'nettia_feedback_v1': 'no es json'});
    await FeedbackService.instance.load();
    expect(FeedbackService.instance.entradas, isEmpty);
  });

  test('una entrada con un veredicto desconocido o ausente se ignora', () async {
    SharedPreferences.setMockInitialValues({
      'nettia_feedback_v1':
          '[{"fecha":"2026-09-20T00:00:00.000","fragmento":"a","veredicto":"no-existe"},'
          '{"fecha":"2026-09-20T00:00:00.000","fragmento":"b"}]',
    });
    await FeedbackService.instance.load();
    expect(FeedbackService.instance.entradas, isEmpty);
  });

  test('una entrada sin id de fragmento se ignora', () async {
    SharedPreferences.setMockInitialValues({
      'nettia_feedback_v1':
          '[{"fecha":"2026-09-20T00:00:00.000","veredicto":"funciono"}]',
    });
    await FeedbackService.instance.load();
    expect(FeedbackService.instance.entradas, isEmpty);
  });

  test('pregunta y nota ausentes en el JSON guardado se leen como cadena vacía', () async {
    SharedPreferences.setMockInitialValues({
      'nettia_feedback_v1':
          '[{"fecha":"2026-09-20T00:00:00.000","fragmento":"c","veredicto":"funciono"}]',
    });
    await FeedbackService.instance.load();
    final e = FeedbackService.instance.entradas.single;
    expect(e.pregunta, '');
    expect(e.nota, '');
  });

  test('al superar el máximo de 500 entradas se descartan las más viejas', () async {
    for (var i = 0; i < 501; i++) {
      await FeedbackService.instance.registrar(EntradaFeedback(
        fecha: DateTime(2026, 1, 1),
        fragmentoId: 'f$i',
        veredicto: VeredictoFragmento.funciono,
      ));
    }
    expect(FeedbackService.instance.entradas, hasLength(500));
    expect(FeedbackService.instance.entradas.first.fragmentoId, 'f1');
    expect(FeedbackService.instance.entradas.last.fragmentoId, 'f500');
  });

  test('un JSON no válido se reporta con debugPrint', () async {
    final mensajes = <String>[];
    final original = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => mensajes.add(m ?? '');
    addTearDown(() => debugPrint = original);

    SharedPreferences.setMockInitialValues({'nettia_feedback_v1': 'no es json'});
    await FeedbackService.instance.load();

    expect(mensajes, hasLength(1));
    expect(mensajes.single, startsWith('Nettia: no se pudieron cargar los comentarios: '));
  });

  test('el renglón del reporte empieza con guion y sin pregunta ni nota no las muestra', () async {
    await FeedbackService.instance.registrar(EntradaFeedback(
      fecha: DateTime(2026, 9, 20),
      fragmentoId: 'x',
      veredicto: VeredictoFragmento.funciono,
    ));
    final r = FeedbackService.instance.reporte();
    expect(r, 'Comentarios de Nettia (1)\n- 2026-09-20 | x | Me funcionó\n');
  });

  test('el reporte incluye la pregunta y la nota cuando están presentes', () async {
    await FeedbackService.instance.registrar(EntradaFeedback(
      fecha: DateTime(2026, 9, 20),
      fragmentoId: 'x',
      veredicto: VeredictoFragmento.funciono,
      pregunta: '¿cómo se hace?',
      nota: 'una nota',
    ));
    final r = FeedbackService.instance.reporte();
    expect(r, contains('pregunta: ¿cómo se hace?'));
    expect(r, contains('nota: una nota'));
  });
}
