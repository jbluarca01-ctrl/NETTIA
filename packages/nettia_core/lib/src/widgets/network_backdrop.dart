import 'package:flutter/material.dart';
import '../theme/network_theme.dart';

/// Fondo ambiental reactivo para la suite de redes.
///
/// Implementa un degradado profundo de datacenter con un sutil resplandor
/// radial cian/fibra óptica y un pulso animado cuando [isProcessing] es true.
class NetworkBackdrop extends StatefulWidget {
  const NetworkBackdrop({
    super.key,
    this.isProcessing = false,
    required this.child,
  });

  final bool isProcessing;
  final Widget child;

  @override
  State<NetworkBackdrop> createState() => _NetworkBackdropState();
}

class _NetworkBackdropState extends State<NetworkBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Fondo base degradado (colores distintos claro/oscuro).
  Widget _fondoBase(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF04070C), Color(0xFF060A10), Color(0xFF0C1322)]
              : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        ),
      ),
    );
  }

  /// Resplandor ambiental de red (Cian y Fibra Óptica), solo en modo oscuro.
  Widget _resplandor() {
    return Positioned(
      top: -120,
      right: -60,
      child: IgnorePointer(
        child: Container(
          width: 360,
          height: 360,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x1800E5FF), Color(0x060070F3), Colors.transparent],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  /// Pulso reactivo cuando la IA o la calculadora están procesando.
  Widget _pulso() {
    return AnimatedBuilder(
      key: const Key('network-backdrop-pulso'),
      animation: _pulseController,
      builder: (context, _) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.3),
                  radius: 1.0 + (_pulseController.value * 0.2),
                  colors: [
                    NetworkTheme.cyanOptical.withValues(
                      alpha: 0.04 + (_pulseController.value * 0.05),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        _fondoBase(isDark),
        if (isDark) _resplandor(),
        if (widget.isProcessing && isDark) _pulso(),
        widget.child,
      ],
    );
  }
}
