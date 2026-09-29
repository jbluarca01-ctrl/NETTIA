import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nettia_core/nettia_core.dart';

/// Pantalla de inicio ("splash") animada: el logo se dibuja, aparece el
/// nombre con un cursor parpadeante estilo terminal, y navega sola a [next].
class NettiaSplashScreen extends StatefulWidget {
  const NettiaSplashScreen({super.key, required this.next});

  final WidgetBuilder next;

  @override
  State<NettiaSplashScreen> createState() => _NettiaSplashScreenState();
}

class _NettiaSplashScreenState extends State<NettiaSplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _texto = 'Nettia';

  /// Cuánto tarda en revelarse cada letra desde que aparece la anterior (o
  /// desde el arranque, para la primera): una pausa antes de la "N", una
  /// pausa larga "pensando" tras la "N", y el resto rápido, letra a letra.
  static const List<Duration> _retrasosPorLetra = <Duration>[
    Duration(milliseconds: 400),
    Duration(milliseconds: 650),
    Duration(milliseconds: 70),
    Duration(milliseconds: 70),
    Duration(milliseconds: 70),
    Duration(milliseconds: 70),
  ];

  /// Cuánto se queda parpadeando el cursor, con el nombre ya completo, antes
  /// de entrar a la app.
  static const Duration _pausaFinal = Duration(milliseconds: 700);

  late final AnimationController _caret;
  int _letrasVisibles = 0;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _caret = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _programarPaso(0);
  }

  /// Encadena un `Timer` cancelable por letra (y uno final antes de navegar)
  /// en vez de `Future.delayed`: así `dispose()` puede detener de verdad el
  /// temporizador pendiente (con `Future.delayed` el temporizador interno
  /// sigue "vivo" aunque se ignore su resultado).
  void _programarPaso(int paso) {
    if (paso < _retrasosPorLetra.length) {
      _temporizador = Timer(_retrasosPorLetra[paso], () {
        setState(() => _letrasVisibles++);
        _programarPaso(paso + 1);
      });
      return;
    }
    _temporizador = Timer(_pausaFinal, () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: widget.next));
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedNettiaLogo(size: 64),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _texto.substring(0, _letrasVisibles),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                FadeTransition(
                  opacity: _caret,
                  child: Text(
                    '_',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
