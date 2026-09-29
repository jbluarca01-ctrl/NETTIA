import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:nettia_knowledge/src/base_conocimiento.dart';
import 'package:nettia_knowledge/src/fragmento.dart';

import '../tool/build_corpus.dart' show corpusComoJson, leerPublicados;

/// Pregunta del golden set con el fragmento que debe aparecer entre los 3
/// primeros resultados.
class _Caso {
  const _Caso(this.pregunta, this.esperado);
  final String pregunta;
  final String esperado;
}

const List<_Caso> _golden = <_Caso>[
  _Caso('¿Cómo se abrevia una dirección IPv6?', 'ipv6-formato-y-abreviacion'),
  _Caso('cómo comprimo ceros en ipv6 con ::', 'ipv6-formato-y-abreviacion'),
  _Caso('¿Qué es una dirección link-local IPv6?', 'ipv6-link-local'),
  _Caso('¿Qué diferencia hay entre GUA y ULA?', 'ipv6-tipos-de-direccion'),
  _Caso('¿Existe broadcast en IPv6?', 'ipv6-tipos-de-direccion'),
  _Caso('¿Cómo funciona EUI-64?', 'ipv6-eui64'),
  _Caso('¿Qué es SLAAC y en qué se diferencia de DHCPv6?',
      'ipv6-slaac-y-dhcpv6'),
  _Caso('¿Qué reemplaza a ARP en IPv6?', 'ipv6-ndp-reemplaza-arp'),
  _Caso('what replaces ARP in IPv6 neighbor discovery',
      'ipv6-ndp-reemplaza-arp'),
  _Caso('¿Cómo subneteo un /48 en /64?', 'ipv6-subneteo-48-a-64'),
  _Caso('¿Qué comando muestra las interfaces IPv6?', 'ipv6-configuracion-ios'),
  _Caso('¿Cómo creo una VLAN y asigno un puerto?',
      'vlan-crear-y-asignar-puertos'),
  _Caso('¿Qué comando configura un puerto como trunk?',
      'trunk-8021q-configuracion'),
  _Caso('¿Qué es la VLAN nativa y qué pasa si no coincide?',
      'trunk-8021q-configuracion'),
  _Caso('¿Cómo configuro router-on-a-stick?', 'router-on-a-stick'),
  _Caso('¿Cómo funciona OSPF y qué es el área 0?', 'ospf-conceptos-basicos'),
  _Caso('¿Cómo se elige el DR en OSPF?', 'ospf-conceptos-basicos'),
  _Caso('¿Cómo configuro OSPFv2 de una sola área?', 'ospf-configuracion-basica'),
  _Caso('¿Cómo elige OSPF el router id?', 'ospf-router-id'),
  _Caso('¿Por qué OSPF no forma vecinos?', 'ospf-hello-dead-y-vecinos'),
  _Caso('¿Cuál es el hello y dead interval por defecto en OSPF?',
      'ospf-hello-dead-y-vecinos'),
  _Caso('¿Por qué OSPF no distingue FastEthernet de Gigabit?',
      'ospf-costo-y-ancho-de-banda'),
  _Caso('¿Qué es una wildcard mask en una ACL?',
      'acl-conceptos-evaluacion-wildcard'),
  _Caso('¿Qué pasa con un paquete que no coincide con ninguna línea de la ACL?',
      'acl-conceptos-evaluacion-wildcard'),
  _Caso('¿Diferencia entre ACL estándar y extendida?',
      'acl-estandar-vs-extendida'),
  _Caso('¿Cómo aplico una ACL a una interfaz in o out?',
      'acl-aplicar-a-interfaz'),
  _Caso('¿Qué modos de EtherChannel negocian con LACP?',
      'etherchannel-modos-lacp-pagp'),
  _Caso('¿Por qué un puerto no entra al EtherChannel?',
      'etherchannel-requisitos-configuracion'),
  _Caso('¿Cuál es la MAC virtual de HSRP?', 'hsrp-conceptos-mac-y-estados'),
  _Caso('¿Para qué sirve standby preempt en HSRP?',
      'hsrp-configuracion-priority-preempt-track'),
  _Caso('¿Cómo configuro un pool DHCP en un router?',
      'dhcp-servidor-pool-exclusion'),
  _Caso('¿Dónde va el ip helper-address?', 'dhcp-relay-ip-helper-address'),
  _Caso('¿Por qué el router se congela cuando escribo mal un comando?',
      'dns-resolucion-en-el-router'),
  _Caso('¿Cómo aprende un switch las direcciones MAC?',
      'switching-tabla-mac-aprendizaje'),
  _Caso('¿Cómo enruto entre VLAN con un switch de capa 3?',
      'intervlan-svi-switch-capa3'),
  _Caso('¿Diferencia entre IaaS, PaaS y SaaS?', 'cloud-modelos-servicio-despliegue'),
  _Caso('¿Qué es la API northbound y southbound en SDN?', 'sdn-planos-y-apis'),
  _Caso('¿Qué hace LISP y VXLAN en SD-Access?', 'sda-fabric-roles-y-planos'),
];

void main() {
  final publicados = leerPublicados('.');
  final base = BaseConocimiento.desdeFragmentos(publicados);

  group('puertas de calidad del corpus', () {
    test('todos los fragmentos publicados cumplen las puertas', () {
      expect(publicados, isNotEmpty);
      for (final f in publicados) {
        expect(f.validarParaPublicar(), isEmpty, reason: f.id);
      }
    });

    test('assets/corpus.json está sincronizado con corpus/publicado', () {
      final enDisco = File('assets/corpus.json').readAsStringSync();
      expect(
        enDisco.replaceAll('\r\n', '\n'),
        corpusComoJson(publicados),
        reason: 'Ejecuta: dart run tool/build_corpus.dart',
      );
    });

    test('nada de borradores en el asset', () {
      final borradores = Directory('corpus/borradores')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .map((f) => parseFragmentoMarkdown(f.readAsStringSync()).id)
          .toSet();
      expect(borradores, isNotEmpty);
      final ids = (jsonDecode(File('assets/corpus.json').readAsStringSync())
              as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toSet();
      expect(ids.intersection(borradores), isEmpty);
    });

    test('un fragmento sin revisar no entra a la base', () {
      final malo = parseFragmentoMarkdown('''
---
id: malo
tema: ipv6
subtema: x
titulo: Malo
nivel: basico
plataforma: generico
version: -
protocolo: ipv6
audiencia: estudiante
idioma: es
estado: borrador
verificacion: sin-verificar
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por:
palabras_clave: x
fuente: A | s | https://a.example
---
Texto suficientemente largo para pasar la longitud mínima del contenido.
''');
      expect(malo.validarParaPublicar(), isNotEmpty);
      expect(() => BaseConocimiento.desdeFragmentos(<Fragmento>[malo]),
          throwsStateError);
    });

    test('fuentes-cruzadas exige dos fuentes', () {
      final f = publicados.first;
      final una = Fragmento(
        id: f.id,
        tema: f.tema,
        subtema: f.subtema,
        titulo: f.titulo,
        nivel: f.nivel,
        plataforma: f.plataforma,
        version: f.version,
        protocolo: f.protocolo,
        audiencia: f.audiencia,
        idioma: f.idioma,
        estado: f.estado,
        verificacion: 'fuentes-cruzadas',
        comandosProbados: false,
        fechaRevision: f.fechaRevision,
        revisadoPor: f.revisadoPor,
        fuentes: <FuenteFragmento>[f.fuentes.first],
        palabrasClave: f.palabrasClave,
        contenido: f.contenido,
      );
      expect(una.validarParaPublicar().join(), contains('al menos 2 fuentes'));
    });
  });

  group('búsqueda', () {
    test('golden set: el fragmento esperado está entre los 3 primeros', () {
      final fallos = <String>[];
      for (final c in _golden) {
        final ids = base
            .buscar(c.pregunta, k: 3)
            .map((r) => r.fragmento.id)
            .toList();
        if (!ids.contains(c.esperado)) {
          fallos.add('"${c.pregunta}" → esperado ${c.esperado}, salió $ids');
        }
      }
      final aciertos = _golden.length - fallos.length;
      // ignore: avoid_print
      print('golden recall@3: $aciertos/${_golden.length}');
      expect(fallos, isEmpty, reason: fallos.join('\n'));
    });

    test('las preguntas clave tienen el fragmento correcto en 1.er lugar', () {
      // La respuesta offline muestra solo el primer resultado.
      const top1 = <_Caso>[
        _Caso('¿Cómo se abrevia una dirección IPv6?',
            'ipv6-formato-y-abreviacion'),
        _Caso('¿Qué es una dirección link-local IPv6?', 'ipv6-link-local'),
        _Caso('¿Cómo funciona EUI-64?', 'ipv6-eui64'),
        _Caso('¿Qué es SLAAC?', 'ipv6-slaac-y-dhcpv6'),
        _Caso('¿Qué reemplaza a ARP en IPv6?', 'ipv6-ndp-reemplaza-arp'),
        _Caso('¿Cómo subneteo un /48 en /64?', 'ipv6-subneteo-48-a-64'),
        _Caso('¿Cómo configuro router-on-a-stick?', 'router-on-a-stick'),
        _Caso('¿Qué comando configura un puerto como trunk?',
            'trunk-8021q-configuracion'),
        _Caso('¿Cómo se elige el DR en OSPF?', 'ospf-conceptos-basicos'),
        _Caso('¿Por qué OSPF no forma vecinos?', 'ospf-hello-dead-y-vecinos'),
        _Caso('¿Cómo elige OSPF el router id?', 'ospf-router-id'),
      ];
      for (final c in top1) {
        final r = base.buscar(c.pregunta, k: 1);
        expect(r.single.fragmento.id, c.esperado, reason: c.pregunta);
      }
    });

    test('lo que no está en la base devuelve vacío (no inventa)', () {
      expect(base.buscar('receta de pizza napolitana'), isEmpty);
      expect(base.buscar('¿cómo configuro BGP con dos ISP?'), isEmpty);
      expect(base.buscar(''), isEmpty);
      expect(base.buscar('¿qué es?'), isEmpty);
    });

    test('el estudiante no recibe fragmentos solo profesionales', () {
      Fragmento f(String id, String aud) => Fragmento(
            id: id,
            tema: 'seguridad',
            subtema: 'x',
            titulo: 'Endurecimiento de producción',
            nivel: 'avanzado',
            plataforma: 'ios',
            version: '-',
            protocolo: 'aaa',
            audiencia: aud.split(',').toSet(),
            idioma: 'es',
            estado: 'publicado',
            verificacion: 'fuentes-cruzadas',
            comandosProbados: false,
            fechaRevision: '2026-09-20',
            revisadoPor: 'prueba',
            fuentes: const <FuenteFragmento>[
              FuenteFragmento('A', 's', 'https://a.example'),
              FuenteFragmento('B', 's', 'https://b.example'),
            ],
            palabrasClave: const <String>['endurecimiento', 'aaa'],
            contenido:
                'Contenido de prueba sobre endurecimiento de dispositivos en producción.',
          );
      final b = BaseConocimiento.desdeFragmentos(<Fragmento>[
        f('solo-prof', 'profesional'),
        f('ambos', 'estudiante,profesional'),
      ]);
      final est = b
          .buscar('endurecimiento producción', perfil: UserProfile.estudiante)
          .map((r) => r.fragmento.id);
      final pro = b
          .buscar('endurecimiento producción', perfil: UserProfile.profesional)
          .map((r) => r.fragmento.id);
      expect(est, <String>['ambos']);
      expect(pro.toSet(), <String>{'solo-prof', 'ambos'});
    });

    test('todo fragmento publicado se encuentra buscando su propio título', () {
      for (final f in publicados) {
        final ids = base.buscar(f.titulo, k: 3).map((r) => r.fragmento.id);
        expect(ids, contains(f.id), reason: f.titulo);
      }
    });
  });
}
