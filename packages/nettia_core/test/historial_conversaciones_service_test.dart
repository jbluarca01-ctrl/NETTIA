import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await HistorialConversacionesService.instance.load();
  });

  group('HistorialConversacionesService', () {
    test('sin conversaciones guardadas, la lista está vacía', () {
      expect(HistorialConversacionesService.instance.conversaciones, isEmpty);
    });

    test('guardar una conversación nueva la agrega a la lista', () async {
      final servicio = HistorialConversacionesService.instance;
      await servicio.guardar(
        Conversacion(
          id: 'c1',
          fecha: DateTime(2026, 9, 25),
          titulo: '¿Cómo configuro una VLAN?',
          mensajes: const [
            MensajeGuardado(texto: '¿Cómo configuro una VLAN?', esUsuario: true),
            MensajeGuardado(texto: 'Con vlan 10...', esUsuario: false),
          ],
        ),
      );

      expect(servicio.conversaciones, hasLength(1));
      expect(servicio.conversaciones.single.titulo, '¿Cómo configuro una VLAN?');
      expect(servicio.conversaciones.single.mensajes, hasLength(2));
    });

    test('guardar de nuevo con el mismo id actualiza en vez de duplicar '
        '(auto-guardado mientras la conversación sigue)', () async {
      final servicio = HistorialConversacionesService.instance;
      final fecha = DateTime(2026, 9, 25);
      await servicio.guardar(
        Conversacion(id: 'c1', fecha: fecha, titulo: 'hola', mensajes: const [
          MensajeGuardado(texto: 'hola', esUsuario: true),
        ]),
      );
      await servicio.guardar(
        Conversacion(id: 'c1', fecha: fecha, titulo: 'hola', mensajes: const [
          MensajeGuardado(texto: 'hola', esUsuario: true),
          MensajeGuardado(texto: 'respuesta', esUsuario: false),
        ]),
      );

      expect(servicio.conversaciones, hasLength(1));
      expect(servicio.conversaciones.single.mensajes, hasLength(2));
    });

    test('actualizar una conversación que no es la primera no duplica ni mueve las demás', () async {
      final servicio = HistorialConversacionesService.instance;
      final fecha = DateTime(2026, 9, 25);
      Conversacion conv(String id, String titulo) =>
          Conversacion(id: id, fecha: fecha, titulo: titulo, mensajes: const []);
      await servicio.guardar(conv('a', 'a'));
      await servicio.guardar(conv('b', 'b'));
      await servicio.guardar(conv('c', 'c'));

      await servicio.guardar(conv('c', 'c editada'));

      final porId = {for (final c in servicio.conversaciones) c.id: c.titulo};
      expect(porId, {'a': 'a', 'b': 'b', 'c': 'c editada'});
    });

    test('un JSON no válido se reporta con debugPrint', () async {
      final mensajes = <String>[];
      final original = debugPrint;
      debugPrint = (String? m, {int? wrapWidth}) => mensajes.add(m ?? '');
      addTearDown(() => debugPrint = original);

      SharedPreferences.setMockInitialValues({'nettia_historial_v1': 'no es json'});
      await HistorialConversacionesService.instance.load();

      expect(mensajes, hasLength(1));
      expect(
        mensajes.single,
        startsWith('Nettia: no se pudo cargar el historial de conversaciones: '),
      );
    });

    test('una conversación con fecha que no es texto se ignora', () async {
      SharedPreferences.setMockInitialValues({
        'nettia_historial_v1': '[{"id":"c1","fecha":20260925,"titulo":"x","mensajes":[]}]',
      });
      await HistorialConversacionesService.instance.load();
      expect(HistorialConversacionesService.instance.conversaciones, isEmpty);
    });

    test('las conversaciones se listan de la más reciente a la más vieja', () async {
      final servicio = HistorialConversacionesService.instance;
      await servicio.guardar(Conversacion(
        id: 'vieja',
        fecha: DateTime(2026, 1, 1),
        titulo: 'vieja',
        mensajes: const [],
      ));
      await servicio.guardar(Conversacion(
        id: 'nueva',
        fecha: DateTime(2026, 9, 25),
        titulo: 'nueva',
        mensajes: const [],
      ));

      expect(servicio.conversaciones.map((c) => c.id), ['nueva', 'vieja']);
    });

    test('eliminar quita solo esa conversación', () async {
      final servicio = HistorialConversacionesService.instance;
      await servicio.guardar(Conversacion(id: 'a', fecha: DateTime(2026), titulo: 'a', mensajes: const []));
      await servicio.guardar(Conversacion(id: 'b', fecha: DateTime(2026), titulo: 'b', mensajes: const []));

      await servicio.eliminar('a');

      expect(servicio.conversaciones.map((c) => c.id), ['b']);
    });

    test('lo guardado sobrevive a "reabrir la app" (recargar el servicio)', () async {
      await HistorialConversacionesService.instance.guardar(
        Conversacion(
          id: 'persistente',
          fecha: DateTime(2026, 9, 25),
          titulo: 'persistente',
          mensajes: const [MensajeGuardado(texto: 'x', esUsuario: true)],
        ),
      );

      // Simula reabrir la app: instancia nueva, misma SharedPreferences.
      await HistorialConversacionesService.instance.load();

      expect(HistorialConversacionesService.instance.conversaciones, hasLength(1));
      expect(
        HistorialConversacionesService.instance.conversaciones.single.id,
        'persistente',
      );
    });

    test('borrarTodo limpia también lo guardado', () async {
      final servicio = HistorialConversacionesService.instance;
      await servicio.guardar(Conversacion(id: 'a', fecha: DateTime(2026), titulo: 'a', mensajes: const []));

      await servicio.borrarTodo();
      await servicio.load();

      expect(servicio.conversaciones, isEmpty);
    });

    test('un valor guardado que no es JSON válido deja la lista vacía sin lanzar', () async {
      SharedPreferences.setMockInitialValues({'nettia_historial_v1': 'no es json'});
      await HistorialConversacionesService.instance.load();
      expect(HistorialConversacionesService.instance.conversaciones, isEmpty);
    });

    test('una conversación guardada sin id, fecha, título o mensajes se ignora', () async {
      SharedPreferences.setMockInitialValues({
        'nettia_historial_v1': '[{"fecha":"2026-09-25T00:00:00.000","titulo":"x","mensajes":[]}]',
      });
      await HistorialConversacionesService.instance.load();
      expect(HistorialConversacionesService.instance.conversaciones, isEmpty);
    });

    test('un mensaje guardado sin texto o sin esUsuario se descarta pero la conversación se conserva', () async {
      SharedPreferences.setMockInitialValues({
        'nettia_historial_v1': '[{"id":"c1","fecha":"2026-09-25T00:00:00.000","titulo":"x",'
            '"mensajes":[{"texto":"hola"},{"texto":"ok","esUsuario":true}]}]',
      });
      await HistorialConversacionesService.instance.load();
      final c = HistorialConversacionesService.instance.conversaciones.single;
      expect(c.mensajes, hasLength(1));
      expect(c.mensajes.single.texto, 'ok');
    });

    test('al superar el máximo de 200 conversaciones se descarta la más vieja de la lista interna', () async {
      final servicio = HistorialConversacionesService.instance;
      for (var i = 0; i < 201; i++) {
        await servicio.guardar(Conversacion(
          id: 'c$i',
          fecha: DateTime(2026),
          titulo: 'c$i',
          mensajes: const [],
        ));
      }
      final ids = servicio.conversaciones.map((c) => c.id).toSet();
      expect(ids, hasLength(200));
      expect(ids.contains('c0'), isFalse);
      expect(ids.contains('c200'), isTrue);
    });
  });
}
