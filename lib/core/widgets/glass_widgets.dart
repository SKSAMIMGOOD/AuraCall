import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted glass card using BackdropFilter for a premium blur effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassCard({
    Key? key,
    required this.child,
    this.blur = 16.0,
    this.borderRadius = 28.0,
    this.backgroundColor = AppColors.glassSurface,
    this.borderColor = AppColors.glassBorder,
    this.padding = const EdgeInsets.all(20.0),
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A premium glassmorphic button supporting subtle scale animations.
class GlassButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget? child;
  final IconData? icon;
  final String? label;
  final Color? color;
  final double size;
  final bool isCircle;
  final double borderRadius;

  const GlassButton({
    Key? key,
    required this.onTap,
    this.child,
    this.icon,
    this.label,
    this.color,
    this.size = 56.0,
    this.isCircle = true,
    this.borderRadius = 28.0,
  }) : super(key: key);

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultBg = widget.color ?? AppColors.glassSurface;
    final defaultBorder = widget.color != null ? widget.color!.withOpacity(0.3) : AppColors.glassBorder;

    Widget buttonBody = InkWell(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapCancel: () => _controller.reverse(),
      onTapUp: (_) => _controller.reverse(),
      borderRadius: BorderRadius.circular(widget.isCircle ? widget.size : widget.borderRadius),
      child: Center(
        child: widget.child ?? (widget.icon != null
            ? Icon(widget.icon, color: Colors.white, size: widget.size * 0.45)
            : Text(widget.label ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ),
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.isCircle ? widget.size : widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: widget.isCircle ? widget.size : null,
            height: widget.size,
            decoration: BoxDecoration(
              color: defaultBg,
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: defaultBorder, width: 1.2),
            ),
            child: buttonBody,
          ),
        ),
      ),
    );
  }
}

/// Dynamic pulsating ring waves radiating from a central avatar.
class RippleEffect extends StatefulWidget {
  final Widget child;
  final Color color;

  const RippleEffect({
    Key? key,
    required this.child,
    this.color = AppColors.blue,
  }) : super(key: key);

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...List.generate(3, (index) {
          final animation = Tween<double>(begin: 1.0, end: 2.2).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(index * 0.25, 1.0, curve: Curves.easeOut),
            ),
          );

          final opacity = Tween<double>(begin: 0.35, end: 0.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(index * 0.25, 1.0, curve: Curves.easeOut),
            ),
          );

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: animation.value,
                child: Opacity(
                  opacity: opacity.value.clamp(0.0, 1.0),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.color, width: 2.5),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        widget.child,
      ],
    );
  }
}

/// An animated audio waveform simulation utilizing sine waves.
class WaveformWidget extends StatefulWidget {
  final bool isAnimated;
  final Color color;
  final int count;

  const WaveformWidget({
    Key? key,
    this.isAnimated = true,
    this.color = AppColors.green,
    this.count = 25,
  }) : super(key: key);

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.count; i++) {
      _heights.add(_random.nextDouble() * 0.7 + 0.1);
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.count, (index) {
              // Create dynamic wave offsets using sine
              double phase = (_controller.value * 2 * math.pi) + (index * 0.35);
              double multiplier = widget.isAnimated ? (math.sin(phase).abs() * 0.7 + 0.3) : 0.2;
              double currentHeight = 50.0 * _heights[index] * multiplier;

              return Container(
                width: 3.5,
                height: currentHeight.clamp(4.0, 50.0),
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(widget.isAnimated ? 0.95 : 0.4),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
