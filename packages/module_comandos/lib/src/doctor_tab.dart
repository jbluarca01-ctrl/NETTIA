import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

import 'logic/doctor_consola.dart';

/// Lo pegado en el Doctor y su último diagnóstico. Lo crea y lo libera
/// la pantalla de Comandos, así sobrevive al cambiar de pestaña.
class DoctorConsolaControlador extends ChangeNotifier {
  final texto = TextEditingController();
  List<Diagnostico>? _diagnosticos;

  /// `null` hasta el primer diagnóstico.
  List<Diagnostico>? get diagnosticos {
    return _diagnosticos;
  }

  void diagnosticar() {
    _diagnosticos = diagnosticarConsola(texto.text);
    notifyListeners();
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }
}

/// Pestaña "Doctor": se pegan mensajes de la consola (errores de IOS,
/// syslog o el ping de una PC) y muestra cada problema con su causa y los
/// pasos que lo corrigen. Todo se analiza en el teléfono.
class DoctorConsolaTab extends StatelessWidget {
  const DoctorConsolaTab(this.controlador, {super.key});

  final DoctorConsolaControlador controlador;

  static const double _hueco = 12;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: controlador, builder: _contenido);

  Widget _contenido(BuildContext context, Widget? _) {
    final texto = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(_hueco),
      children: [
        Text('Doctor de consola', style: texto.titleMedium),
        Text(
          'Pega errores de IOS, mensajes de syslog o el resultado de un ping: '
          'te digo la causa y cómo corregirlo. Se analiza en tu teléfono.',
          style: texto.bodySmall,
        ),
        const SizedBox(height: _hueco),
        TextField(
          key: const ValueKey('doctor_texto'),
          controller: controlador.texto,
          minLines: 5,
          maxLines: 12,
          style: const TextStyle(fontFamilyFallback: kMonoFallback),
          decoration: const InputDecoration(
            labelText: 'Mensajes de la consola',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: _hueco),
        FilledButton.icon(
          onPressed: controlador.diagnosticar,
          icon: const Icon(NettiaIcons.validado),
          label: const Text('Diagnosticar'),
        ),
        ..._resultado(context, texto),
      ],
    );
  }

  List<Widget> _resultado(BuildContext context, TextTheme texto) {
    final d = controlador.diagnosticos;
    if (d == null) return const [];
    if (d.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: _hueco),
          child: Text(
            'No reconozco ningún mensaje de IOS, syslog ni ping. Pega el '
            'texto tal como salió en la consola.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ];
    }
    final n = d.length;
    return [
      Padding(
        padding: const EdgeInsets.only(top: _hueco),
        child: Text(
          '$n ${n == 1 ? 'problema encontrado' : 'problemas encontrados'}',
          style: texto.titleSmall,
        ),
      ),
      for (final x in d) _TarjetaDiagnostico(x),
    ];
  }
}

/// Un problema: título, causa y pasos de corrección en letra de consola.
class _TarjetaDiagnostico extends StatelessWidget {
  const _TarjetaDiagnostico(this.d);

  final Diagnostico d;

  static const double _margen = 8;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: _margen),
      child: Padding(
        padding: const EdgeInsets.all(_margen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.titulo, style: texto.titleSmall),
            SelectableText(d.causa, style: texto.bodyMedium),
            const SizedBox(height: _margen),
            for (final paso in d.solucion)
              SelectableText(
                paso,
                style: const TextStyle(fontFamilyFallback: kMonoFallback),
              ),
          ],
        ),
      ),
    );
  }
}
