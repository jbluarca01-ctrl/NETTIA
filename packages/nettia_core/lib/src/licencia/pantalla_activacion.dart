import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'guardian_licencia.dart';

/// Envuelve toda la app (`MaterialApp.builder`): sin licencia activa no deja
/// ver nada más que la activación o el bloqueo (SPEC-005 RF8, RF13).
class PuertaLicencia extends StatefulWidget {
  const PuertaLicencia({
    super.key,
    required this.guardian,
    required this.contacto,
    required this.child,
  });

  final GuardianLicencia guardian;

  /// Cómo comprar o pedir soporte; vacío = no se muestra.
  final String contacto;
  final Widget child;

  @override
  State<PuertaLicencia> createState() => _PuertaLicenciaState();
}

class _PuertaLicenciaState extends State<PuertaLicencia> {
  @override
  void initState() {
    super.initState();
    _revisarSiHaceFalta();
  }

  @override
  void didUpdateWidget(PuertaLicencia anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.guardian != widget.guardian) _revisarSiHaceFalta();
  }

  void _revisarSiHaceFalta() {
    if (widget.guardian.estado == EstadoLicencia.sinRevisar) {
      widget.guardian.revisar();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.guardian,
    builder:
        (_, _) => switch (widget.guardian.estado) {
          EstadoLicencia.activa => widget.child,
          EstadoLicencia.sinRevisar => const Scaffold(),
          EstadoLicencia.sinActivar => _aislada(
            PantallaActivacion(
              guardian: widget.guardian,
              contacto: widget.contacto,
            ),
          ),
          EstadoLicencia.noActivable => _aislada(
            const _Aviso(
              'No se pudo leer este teléfono. Cierra Nettia y vuelve a abrirla.',
            ),
          ),
          EstadoLicencia.bloqueada => _aislada(
            const _Aviso('Nettia no puede abrirse en este teléfono.'),
          ),
        },
  );

  /// Navegador propio: la puerta está por encima del de la app, y el cuadro
  /// de texto necesita un Overlay para seleccionar y pegar. La clave lo
  /// rehace cuando cambia lo que muestra.
  Widget _aislada(Widget pantalla) => Navigator(
    key: ValueKey((widget.guardian, widget.guardian.estado, widget.contacto)),
    onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => pantalla),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    ),
  );
}

/// Código del teléfono, botón Copiar, cuadro para pegar y botón Activar.
class PantallaActivacion extends StatefulWidget {
  const PantallaActivacion({
    super.key,
    required this.guardian,
    required this.contacto,
  });

  final GuardianLicencia guardian;
  final String contacto;

  @override
  State<PantallaActivacion> createState() => _PantallaActivacionState();
}

class _PantallaActivacionState extends State<PantallaActivacion> {
  final _texto = TextEditingController();
  bool _copiado = false;
  bool _error = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: widget.guardian.codigo!));
    setState(() => _copiado = true);
  }

  Future<void> _activar() async {
    final ok = await widget.guardian.activar(_texto.text);
    if (mounted) setState(() => _error = !ok);
  }

  /// Título, código del teléfono con su botón Copiar e instrucciones.
  List<Widget> _codigoTelefono(TextTheme tema) => [
    Text('Activa tu Nettia', style: tema.headlineSmall),
    const SizedBox(height: 16),
    const Text('Código de este teléfono'),
    SelectableText(widget.guardian.codigo!, style: tema.headlineMedium),
    TextButton(onPressed: _copiar, child: const Text('Copiar código')),
    if (_copiado) const Text('Código copiado'),
    const SizedBox(height: 12),
    const Text(
      'Envía este código a quien te vendió Nettia. Te devolverá tu '
      'licencia: cópiala y pégala aquí.',
    ),
    if (widget.contacto.isNotEmpty)
      Text('Compra o soporte: ${widget.contacto}'),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ..._codigoTelefono(tema),
            const SizedBox(height: 16),
            TextField(
              controller: _texto,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Pega aquí tu licencia',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error)
              const Text(
                'Ese código no corresponde a este teléfono. Revisa que lo '
                'copiaste completo.',
              ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _activar, child: const Text('Activar')),
          ],
        ),
      ),
    );
  }
}
