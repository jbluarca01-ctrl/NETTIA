import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_ai/nettia_ai.dart';
import 'package:nettia_ai/src/services/offline_knowledge_base.dart';
import 'package:nettia_ai/src/services/respuesta_local.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:nettia_knowledge/nettia_knowledge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la base offline responde con contenido', () {
    expect(generateOfflineResponse('vlan trunk').trim(), isNotEmpty);
  });

  test('sin API Key el asistente pide configurarla y no llama a la red', () async {
    SharedPreferences.setMockInitialValues({});
    await AiSettingsService.instance.load();
    await AiSettingsService.instance.setActiveProvider(AiProviderType.nvidiaNim);

    final texto = await NetiaAiService()
        .diagnosticarFallaStream(consultaUsuario: 'hola')
        .join();
    expect(texto, contains('Falta la API Key'));
  });

  test('modo offline forzado responde desde la base local', () async {
    SharedPreferences.setMockInitialValues({});
    await AiSettingsService.instance.setOfflinePreferred(true);

    final texto = await NetiaAiService()
        .diagnosticarFallaStream(consultaUsuario: 'que es una vlan')
        .join();
    expect(texto.trim(), isNotEmpty);
    await AiSettingsService.instance.setOfflinePreferred(false);
  });

  test('el proveedor offline no tiene equivalente en ai_core', () {
    expect(AiProviderType.offline.aiCore, isNull);
    expect(AiProviderType.nvidiaNim.aiCore, isNotNull);
  });

  test('el prompt cambia de tono según el perfil', () {
    final estudiante = netiaSystemPromptPara(UserProfile.estudiante);
    final profesional = netiaSystemPromptPara(UserProfile.profesional);
    expect(estudiante, contains('PERFIL DEL USUARIO: estudiante'));
    expect(profesional, contains('PERFIL DEL USUARIO: profesional'));
    expect(profesional, isNot(contains('estudiante.')));
    // Sin perfil se usa el tono de estudiante.
    expect(netiaSystemPromptPara(null), estudiante);
  });

  testWidgets('el logo de OpenAI usa la imagen aportada, no un dibujo', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ProviderLogo(AiProviderType.openAi, size: 24)),
    ));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CustomPaint).evaluate().where((e) => e.widget.runtimeType.toString().contains('OpenAi')), isEmpty);
  });

  group('base local (RAG)', () {
    Future<String> preguntarOffline(String q) async {
      SharedPreferences.setMockInitialValues({});
      await AiSettingsService.instance.setOfflinePreferred(true);
      addTearDown(() => AiSettingsService.instance.setOfflinePreferred(false));
      return NetiaAiService().diagnosticarFallaStream(consultaUsuario: q).join();
    }

    test('offline responde desde el corpus y cita la fuente', () async {
      final texto = await preguntarOffline('¿Cómo se abrevia una dirección IPv6?');
      expect(texto, contains('RFC 5952'));
      expect(texto, contains('Fuente'));
      expect(texto, contains('2001:db8::2:1'));
    });

    test('un fragmento con comandos avisa que no se probaron en equipo', () async {
      final texto = await preguntarOffline('¿Cómo configuro router-on-a-stick?');
      expect(texto, contains('encapsulation dot1Q'));
      expect(texto, contains('no se han probado en un equipo'));
    });

    test('lo que el corpus no cubre cae a la base heurística antigua', () async {
      final texto = await preguntarOffline('modbus tcp en la red industrial');
      expect(texto, contains('Modbus'));
    });

    test('"protocolo" ya no dispara la rama industrial por contener "ot"', () {
      expect(generateOfflineResponse('cual protocolo usar'),
          isNot(contains('Segmentación OT')));
    });

    test('expone los fragmentos que respaldaron la respuesta (para la insignia)', () async {
      SharedPreferences.setMockInitialValues({});
      await AiSettingsService.instance.setOfflinePreferred(true);
      addTearDown(() => AiSettingsService.instance.setOfflinePreferred(false));
      final ia = NetiaAiService();
      await ia.diagnosticarFallaStream(consultaUsuario: '¿Cómo configuro router-on-a-stick?').join();
      expect(ia.fuentesUltimaRespuesta.map((f) => f.id), ['router-on-a-stick']);
      expect(ia.fuentesUltimaRespuesta.single.tieneComandos, isTrue);
      expect(ia.fuentesUltimaRespuesta.single.comandosProbados, isFalse);
      // Una pregunta sin cobertura no deja fuentes de la anterior.
      await ia.diagnosticarFallaStream(consultaUsuario: 'receta de pizza').join();
      expect(ia.fuentesUltimaRespuesta, isEmpty);
      expect(ia.sanitizarParaReporte('enable password secreto123'), contains('<OCULTO>'));
    });

    test('contextoRag: con fragmentos cita id y fuente; sin ellos avisa', () async {
      final base = await BaseConocimiento.instancia();
      final r = base.buscar('¿Qué es SLAAC?');
      final con = contextoRag(r);
      expect(con, startsWith('[FUENTES_LOCALES_RAG:'));
      expect(con, contains('[ipv6-slaac-y-dhcpv6]'));
      expect(con, contains('RFC 4862'));

      final sin = contextoRag(const <ResultadoBusqueda>[]);
      expect(sin, startsWith('[SIN_MANUALES_LOCALES:'));
      expect(sin, contains('NO inventes'));
    });

    test('el estudiante no recibe fragmentos solo para profesionales (filtro por perfil)', () async {
      final base = await BaseConocimiento.instancia();
      for (final r in base.buscar('ospf', perfil: UserProfile.estudiante)) {
        expect(r.fragmento.audiencia, contains('estudiante'));
      }
    });
  });
}
