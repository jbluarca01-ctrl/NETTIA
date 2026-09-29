import 'package:flutter/material.dart';

/// Progreso 0..1 de un tramo `[start, end]` del reloj de animación `t`.
/// Expuesta para tests: es la única lógica no visual de
/// [_AnimatedNettiaPainter].
@visibleForTesting
double segmentoLogo(double t, double start, double end) =>
    ((t - start) / (end - start)).clamp(0.0, 1.0);

/// `true` si algún color del logo estático cambió entre el painter viejo y
/// el nuevo (usado por `shouldRepaint`). Expuesta para tests.
@visibleForTesting
bool coloresDeLogoCambiaron({
  required Color lineColorAntes,
  required Color lineColorAhora,
  required Color accentAntes,
  required Color accentAhora,
  required Color accent2Antes,
  required Color accent2Ahora,
}) =>
    lineColorAntes != lineColorAhora ||
    accentAntes != accentAhora ||
    accent2Antes != accent2Ahora;

/// Marca "Nettia": una malla de red con forma de N, en dos colores de
/// acento. Original, sin depender de iconos genéricos.
class NettiaLogo extends StatelessWidget {
  const NettiaLogo({super.key, this.size = 28, this.color, this.accent, this.accent2});

  final double size;
  final Color? color;
  final Color? accent;
  final Color? accent2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size(size, size),
      painter: _NettiaLogoPainter(
        lineColor: color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
        accent: accent ?? scheme.primary,
        accent2: accent2 ?? scheme.tertiary,
      ),
    );
  }
}

class _NettiaLogoPainter extends CustomPainter {
  _NettiaLogoPainter({required this.lineColor, required this.accent, required this.accent2});
  final Color lineColor;
  final Color accent;
  final Color accent2;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    final diagPaint = Paint()
      ..color = accent
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p(8, 8), p(8, 32), linePaint);
    canvas.drawLine(p(32, 8), p(32, 32), linePaint);
    canvas.drawLine(p(8, 32), p(32, 8), diagPaint);

    canvas.drawCircle(p(8, 8), 5 * s, Paint()..color = accent);
    canvas.drawCircle(p(8, 32), 5 * s, Paint()..color = accent2);
    canvas.drawCircle(p(32, 8), 5 * s, Paint()..color = accent2);
    canvas.drawCircle(p(32, 32), 5 * s, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _NettiaLogoPainter oldDelegate) => coloresDeLogoCambiaron(
        lineColorAntes: oldDelegate.lineColor,
        lineColorAhora: lineColor,
        accentAntes: oldDelegate.accent,
        accentAhora: accent,
        accent2Antes: oldDelegate.accent2,
        accent2Ahora: accent2,
      );
}

/// Versión animada (dibujo de líneas + nodos apareciendo) para el splash.
class AnimatedNettiaLogo extends StatefulWidget {
  const AnimatedNettiaLogo({super.key, this.size = 64, this.color, this.accent, this.accent2});

  final double size;
  final Color? color;
  final Color? accent;
  final Color? accent2;

  @override
  State<AnimatedNettiaLogo> createState() => _AnimatedNettiaLogoState();
}

class _AnimatedNettiaLogoState extends State<AnimatedNettiaLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = widget.color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final accent = widget.accent ?? scheme.primary;
    final accent2 = widget.accent2 ?? scheme.tertiary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _AnimatedNettiaPainter(
          t: _controller.value,
          lineColor: lineColor,
          accent: accent,
          accent2: accent2,
        ),
      ),
    );
  }
}

class _AnimatedNettiaPainter extends CustomPainter {
  _AnimatedNettiaPainter({
    required this.t,
    required this.lineColor,
    required this.accent,
    required this.accent2,
  });

  final double t;
  final Color lineColor;
  final Color accent;
  final Color accent2;

  double _seg(double start, double end) => segmentoLogo(t, start, end);

  void _drawPartial(Canvas canvas, Offset a, Offset b, double progress, Paint paint) {
    if (progress <= 0) return;
    canvas.drawLine(a, Offset(a.dx + (b.dx - a.dx) * progress, a.dy + (b.dy - a.dy) * progress), paint);
  }

  void _node(Canvas canvas, Offset center, double start, double radius, Color color) {
    final k = _seg(start, start + 0.35);
    if (k <= 0) return;
    final scale = Curves.easeOutBack.transform(k).clamp(0.0, 1.3);
    canvas.drawCircle(center, radius * scale, Paint()..color = color.withValues(alpha: k.clamp(0.0, 1.0)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final lp = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    final dp = Paint()
      ..color = accent
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;

    _drawPartial(canvas, p(8, 8), p(8, 32), _seg(0.05, 0.55), lp);
    _drawPartial(canvas, p(32, 8), p(32, 32), _seg(0.15, 0.65), lp);
    _drawPartial(canvas, p(8, 32), p(32, 8), _seg(0.30, 0.85), dp);

    _node(canvas, p(8, 8), 0.0, 5 * s, accent);
    _node(canvas, p(8, 32), 0.10, 5 * s, accent2);
    _node(canvas, p(32, 8), 0.20, 5 * s, accent2);
    _node(canvas, p(32, 32), 0.55, 5 * s, accent);
  }

  @override
  bool shouldRepaint(covariant _AnimatedNettiaPainter oldDelegate) => oldDelegate.t != t;
}
