import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum InteractiveButtonStyle {
  primary,
  secondary,
  accent,
  success,
  warning,
  error,
}

class InteractiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final InteractiveButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool isEnabled;

  const InteractiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = InteractiveButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.isEnabled = true,
  });

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (!widget.isEnabled) return AppColors.gray300;

    switch (widget.style) {
      case InteractiveButtonStyle.primary:
        return AppColors.primaryBrown;
      case InteractiveButtonStyle.secondary:
        return AppColors.gray200;
      case InteractiveButtonStyle.accent:
        return AppColors.accentBlue;
      case InteractiveButtonStyle.success:
        return AppColors.success;
      case InteractiveButtonStyle.warning:
        return AppColors.warning;
      case InteractiveButtonStyle.error:
        return AppColors.error;
    }
  }

  Color _getTextColor() {
    if (!widget.isEnabled) return AppColors.gray500;

    switch (widget.style) {
      case InteractiveButtonStyle.primary:
      case InteractiveButtonStyle.accent:
      case InteractiveButtonStyle.success:
      case InteractiveButtonStyle.warning:
      case InteractiveButtonStyle.error:
        return Colors.white;
      case InteractiveButtonStyle.secondary:
        return AppColors.textPrimary;
    }
  }

  List<Color> _getGradientColors() {
    final baseColor = _getBackgroundColor();
    return [
      baseColor,
      baseColor.withOpacity(0.8),
    ];
  }

  void _handleTapDown() {
    if (!widget.isEnabled || widget.isLoading) return;

    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
    _rippleController.forward();
  }

  void _handleTapUp() {
    if (!widget.isEnabled || widget.isLoading) return;

    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();

    // Reset ripple after animation completes
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _rippleController.reset();
      }
    });
  }

  void _handleTap() {
    if (!widget.isEnabled || widget.isLoading || widget.onPressed == null) return;

    // Add haptic feedback
    // HapticFeedback.lightImpact();

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapUp(),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getGradientColors(),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isEnabled && !widget.isLoading
                    ? [
                        BoxShadow(
                          color: _getBackgroundColor().withOpacity(0.3),
                          blurRadius: _isPressed ? 4 : 8,
                          offset: Offset(0, _isPressed ? 2 : 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Ripple effect
                  if (_isPressed)
                    AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, child) {
                        return Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomPaint(
                              painter: RipplePainter(
                                animation: _rippleAnimation,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Button content
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _getTextColor(),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.icon != null) ...[
                                      Icon(
                                        widget.icon,
                                        color: _getTextColor(),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      widget.text,
                                      style: TextStyle(
                                        color: _getTextColor(),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  RipplePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width > size.height ? size.width : size.height;
    final radius = maxRadius * animation.value;

    if (radius > 0) {
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}