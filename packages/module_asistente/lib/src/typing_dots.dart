import 'package:flutter/material.dart';

/// Indicador "escribiendo…": tres puntos con rebote escalonado.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, required this.color});

  final Color color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (i) {
            // Cada punto sube en su tramo de la animación.
            final t = (_controller.value - i * 0.18) % 1.0;
            final salto = t < 0.4
                ? (1 - (t / 0.2 - 1).abs()).clamp(0.0, 1.0)
                : 0.0;
            return Container(
              width: 7,
              height: 7,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 4, bottom: salto * 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.55 + 0.45 * salto),
              ),
            );
          }),
        );
      },
    );
  }
}
