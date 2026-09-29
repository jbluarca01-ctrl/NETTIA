import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pulso suave 0..1 centrado en [centro] (ancho [ancho]) sobre un ciclo `x`
/// en `[0, 1)`. Expuesta para tests: es la única lógica no visual de
/// [_AvatarPainter].
@visibleForTesting
double pulsoAvatar(double x, double centro, double ancho) {
  var d = (x - centro).abs();
  d = math.min(d, 1 - d);
  return d >= ancho ? 0 : (1 - d / ancho);
}

/// `true` si algún color del avatar cambió entre el painter viejo y el
/// nuevo (usado por `shouldRepaint`). Expuesta para tests: es la única
/// lógica no visual de esa comparación.
@visibleForTesting
bool coloresDeAvatarCambiaron({
  required Color fondoAntes,
  required Color fondoAhora,
  required Color bordeAntes,
  required Color bordeAhora,
  required Color lineaAntes,
  required Color lineaAhora,
  required Color acentoAntes,
  required Color acentoAhora,
  required Color acento2Antes,
  required Color acento2Ahora,
}) =>
    fondoAntes != fondoAhora ||
    bordeAntes != bordeAhora ||
    lineaAntes != lineaAhora ||
    acentoAntes != acentoAhora ||
    acento2Antes != acento2Ahora;

/// Avatar de NETIA: el logo de Nettia (la N de malla de red) dentro de un
/// círculo. Con [pensando] se anima: un anillo giratorio, los nodos laten en
/// secuencia, una señal recorre la diagonal y el logo flota suavemente.
class NettiaAvatar extends StatefulWidget {
  const NettiaAvatar({super.key, this.size = 28, this.pensando = false});

  final double size;
  final bool pensando;

  @override
  State<NettiaAvatar> createState() => _NettiaAvatarState();
}

class _NettiaAvatarState extends State<NettiaAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pensando) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant NettiaAvatar old) {
    super.didUpdateWidget(old);
    if (widget.pensando && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.pensando && _c.isAnimating) {
      _c.animateTo(1.0, duration: const Duration(milliseconds: 300)).then((_) {
        if (mounted) _c.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _AvatarPainter(
          repaint: _c,
          t: _c,
          pensando: () => widget.pensando,
          fondo: scheme.surfaceContainerHighest,
          borde: scheme.outline,
          linea: theme.textTheme.bodyLarge?.color ?? Colors.white,
          acento: scheme.primary,
          acento2: scheme.tertiary,
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required Listenable repaint,
    required this.t,
    required this.pensando,
    required this.fondo,
    required this.borde,
    required this.linea,
    required this.acento,
    required this.acento2,
  }) : super(repaint: repaint);

  final Animation<double> t;
  final bool Function() pensando;
  final Color fondo;
  final Color borde;
  final Color linea;
  final Color acento;
  final Color acento2;

  void _pintarFondo(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = fondo);
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borde,
    );
  }

  void _pintarAnillo(Canvas canvas, Offset c, double r, double sizeAncho, double v) {
    final rect = Rect.fromCircle(center: c, radius: r - 1.5);
    canvas.drawArc(
      rect,
      v * 2 * math.pi,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.5, sizeAncho * 0.05)
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 0.9,
          colors: <Color>[acento.withValues(alpha: 0), acento],
          transform: GradientRotation(v * 2 * math.pi),
        ).createShader(rect),
    );
  }

  void _pintarLogo(Canvas canvas, Offset Function(double, double) p, double s) {
    final trazo = Paint()
      ..color = linea
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    final diagonal = Paint()
      ..color = acento
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(8, 8), p(8, 32), trazo);
    canvas.drawLine(p(32, 8), p(32, 32), trazo);
    canvas.drawLine(p(8, 32), p(32, 8), diagonal);
  }

  void _pintarSenal(Canvas canvas, Offset Function(double, double) p, double s, double v) {
    final f = (v * 1.0) % 1.0;
    final sx = 8 + 24 * f;
    final sy = 32 - 24 * f;
    canvas.drawCircle(p(sx, sy), 3.2 * s, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _pintarNodos(Canvas canvas, Offset Function(double, double) p, double s, double v, bool activo) {
    final nodos = <(double, double, Color)>[
      (8, 8, acento),
      (32, 8, acento2),
      (32, 32, acento),
      (8, 32, acento2),
    ];
    for (var i = 0; i < nodos.length; i++) {
      final k = activo ? 1 + 0.45 * pulsoAvatar(v, i * 0.25, 0.22) : 1.0;
      canvas.drawCircle(p(nodos[i].$1, nodos[i].$2), 5 * s * k, Paint()..color = nodos[i].$3);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final activo = pensando() || t.value > 0;
    final v = activo ? t.value : 0.0;
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    _pintarFondo(canvas, c, r);
    if (activo) _pintarAnillo(canvas, c, r, size.width, v);

    // Logo: misma geometría que NettiaLogo (rejilla de 40).
    final lado = size.width * 0.58;
    final flota = activo ? math.sin(v * 2 * math.pi) * size.width * 0.025 : 0.0;
    canvas.save();
    canvas.translate(c.dx - lado / 2, c.dy - lado / 2 + flota);
    final s = lado / 40;
    Offset p(double x, double y) => Offset(x * s, y * s);

    _pintarLogo(canvas, p, s);
    if (activo) _pintarSenal(canvas, p, s, v);
    _pintarNodos(canvas, p, s, v, activo);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => coloresDeAvatarCambiaron(
        fondoAntes: old.fondo,
        fondoAhora: fondo,
        bordeAntes: old.borde,
        bordeAhora: borde,
        lineaAntes: old.linea,
        lineaAhora: linea,
        acentoAntes: old.acento,
        acentoAhora: acento,
        acento2Antes: old.acento2,
        acento2Ahora: acento2,
      );
}
