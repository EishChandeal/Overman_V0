import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

/// A custom button widget for habit completion featuring a fluid, colourful smoke-boom
/// animation upon touch and a smooth fade back to dark upon reversal.
class HabitCompletionButton extends StatefulWidget {
  final bool isCompleted;
  final bool isBoolean;
  final Color habitColor;
  final Color onHabitColor;
  final Color uncompletedColor;
  final double? numericValue;
  final String? numericUnit;
  final String formattedNumber;
  final VoidCallback? onTap;
  final double size;
  final double borderRadius;
  final Duration duration;
  final bool enableAnimation;

  const HabitCompletionButton({
    super.key,
    required this.isCompleted,
    required this.isBoolean,
    required this.habitColor,
    required this.onHabitColor,
    required this.uncompletedColor,
    this.numericValue,
    this.numericUnit,
    this.formattedNumber = '',
    this.onTap,
    this.size = 72.0,
    this.borderRadius = 14.0,
    this.duration = const Duration(milliseconds: 1000),
    this.enableAnimation = true,
  });

  @override
  State<HabitCompletionButton> createState() => _HabitCompletionButtonState();
}

class _HabitCompletionButtonState extends State<HabitCompletionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isCompleted ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant HabitCompletionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (!widget.enableAnimation) {
        _controller.value = widget.isCompleted ? 1.0 : 0.0;
      } else if (widget.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableAnimation && widget.isBoolean) {
      // Immediately start animating in the appropriate direction so the user feels
      // instant, silky-smooth responsiveness even before the DB transaction resolves.
      if (_controller.value > 0.5 || _controller.status == AnimationStatus.forward) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasNumericValue = !widget.isBoolean &&
        widget.numericValue != null &&
        widget.numericValue! > 0;

    if (!widget.enableAnimation) {
      final currentColor =
          widget.isCompleted ? widget.habitColor : widget.uncompletedColor;
      return Semantics(
        button: true,
        label: widget.isBoolean
            ? (widget.isCompleted ? 'Mark habit as incomplete' : 'Mark habit as complete')
            : (hasNumericValue ? 'Logged ${widget.numericValue}' : 'Log numeric value'),
        child: Material(
          color: currentColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: widget.isBoolean
                    ? _buildStaticBooleanContent()
                    : _buildStaticNumericContent(hasNumericValue),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: widget.isBoolean
          ? (widget.isCompleted ? 'Mark habit as incomplete' : 'Mark habit as complete')
          : (hasNumericValue ? 'Logged ${widget.numericValue}' : 'Log numeric value'),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final currentColor = Color.lerp(widget.uncompletedColor, widget.habitColor, t);

          return Material(
            color: currentColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: CustomPaint(
                painter: FluidSmokeBoomPainter(
                  progress: t,
                  habitColor: widget.habitColor,
                  uncompletedColor: widget.uncompletedColor,
                  borderRadius: widget.borderRadius,
                ),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Center(
                    child: widget.isBoolean
                        ? _buildBooleanContent(t)
                        : _buildNumericContent(t, hasNumericValue),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticBooleanContent() {
    return widget.isCompleted
        ? Icon(
            Icons.check,
            size: 32,
            color: widget.onHabitColor,
          )
        : Text(
            '—',
            style: TextStyle(
              color: widget.habitColor.withValues(alpha: 0.7),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          );
  }

  Widget _buildStaticNumericContent(bool hasValue) {
    if (!hasValue) {
      return Text(
        '—',
        style: TextStyle(
          color: widget.habitColor.withValues(alpha: 0.7),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.formattedNumber,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isCompleted ? widget.onHabitColor : widget.habitColor,
              fontFamily: AppTheme.fontPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.numericUnit != null && widget.numericUnit!.isNotEmpty)
            Text(
              widget.numericUnit!,
              style: TextStyle(
                fontSize: 11,
                color: widget.isCompleted
                    ? widget.onHabitColor.withValues(alpha: 0.85)
                    : widget.habitColor.withValues(alpha: 0.8),
                fontFamily: AppTheme.fontPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildBooleanContent(double t) {
    // Dynamic text/icon color adapting fluidly across the progress
    final dynamicIconColor = Color.lerp(
      widget.habitColor,
      widget.onHabitColor,
      (t * 1.3).clamp(0.0, 1.0),
    )!;

    // Dash fades out early (0.0 -> 0.30)
    final dashOpacity = (1.0 - (t / 0.30)).clamp(0.0, 1.0);

    // Checkmark springs in with an elastic curve (0.15 -> 1.0)
    final checkRaw = ((t - 0.15) / 0.85).clamp(0.0, 1.0);
    final checkScale = Curves.easeOutBack.transform(checkRaw);
    final checkOpacity = checkRaw.clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (dashOpacity > 0.0)
          Opacity(
            opacity: dashOpacity,
            child: Text(
              '—',
              style: TextStyle(
                color: widget.habitColor.withValues(alpha: 0.7),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (checkOpacity > 0.0)
          Transform.scale(
            scale: checkScale,
            child: Opacity(
              opacity: checkOpacity,
              child: Icon(
                Icons.check,
                size: 32,
                color: dynamicIconColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNumericContent(double t, bool hasValue) {
    if (!hasValue) {
      return Text(
        '—',
        style: TextStyle(
          color: widget.habitColor.withValues(alpha: 0.7),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Font color adapts so it remains 100% visible across the whole fluid smoke bloom
    final valueColor = Color.lerp(
      widget.habitColor,
      widget.onHabitColor,
      (t * 1.3).clamp(0.0, 1.0),
    )!;

    final unitColor = Color.lerp(
      widget.habitColor.withValues(alpha: 0.8),
      widget.onHabitColor.withValues(alpha: 0.85),
      t,
    )!;

    // Subtle celebration punch scale when completed
    final bounceScale = 1.0 + (0.10 * sin(t * pi));

    return Transform.scale(
      scale: bounceScale,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.formattedNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontFamily: AppTheme.fontPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.numericUnit != null && widget.numericUnit!.isNotEmpty)
              Text(
                widget.numericUnit!,
                style: TextStyle(
                  fontSize: 11,
                  color: unitColor,
                  fontFamily: AppTheme.fontPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering the explosive shockwave boom and swirling fluid smoke billows.
class FluidSmokeBoomPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final Color habitColor;
  final Color uncompletedColor;
  final double borderRadius;

  FluidSmokeBoomPainter({
    required this.progress,
    required this.habitColor,
    required this.uncompletedColor,
    this.borderRadius = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Clip all fluid smoke effects strictly inside the button container
    canvas.clipRRect(rrect);

    // 1. Base dark background
    final baseBg = Color.lerp(
      uncompletedColor,
      habitColor,
      (progress * 0.4).clamp(0.0, 1.0),
    )!;
    canvas.drawRect(rect, Paint()..color = baseBg);

    if (progress > 0.001) {
      final center = Offset(size.width / 2, size.height / 2);
      final maxRadius = sqrt(size.width * size.width + size.height * size.height) * 0.75;

      // 2. Initial Explosive Shockwave Boom (Progress 0.0 -> 0.45)
      final boomT = (progress / 0.45).clamp(0.0, 1.0);
      final boomCurve = Curves.easeOutCubic.transform(boomT);
      final boomRadius = maxRadius * boomCurve * 1.1;
      final boomAlpha = (1.0 - boomT) * (progress > 0 ? 1.0 : 0.0);

      if (boomAlpha > 0.01) {
        final boomPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(habitColor, Colors.white, 0.7)!.withValues(alpha: boomAlpha * 0.95),
              habitColor.withValues(alpha: boomAlpha * 0.8),
              habitColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: boomRadius));
        canvas.drawCircle(center, boomRadius, boomPaint);
      }

      // 3. Fluid Colourful Smoke Billows (Multi-layer organic swirling plumes)
      const plumeCount = 6;
      final baseAngles = [
        0.0,
        pi / 3,
        2 * pi / 3,
        pi,
        4 * pi / 3,
        5 * pi / 3,
      ];
      final speedModifiers = [1.15, 0.90, 1.20, 0.95, 1.10, 0.85];

      for (int i = 0; i < plumeCount; i++) {
        final stagger = i * 0.03;
        final pProgress = ((progress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);
        if (pProgress <= 0.0) continue;

        final pCurve = Curves.easeOutQuart.transform(pProgress);
        final swirlAngle = baseAngles[i] + sin(pProgress * pi * 2 + i * 1.5) * 0.45;
        final dist = (maxRadius * 0.65) * pCurve * speedModifiers[i];
        final plumeCenter = center + Offset(cos(swirlAngle) * dist, sin(swirlAngle) * dist);
        final plumeRadius = (size.width * 0.38) + (size.width * 0.60) * pCurve;

        // Rich colorful tone variations for multi-chromatic smoke depth
        final isHighlight = i % 2 == 0;
        final plumeTone = isHighlight
            ? Color.lerp(habitColor, Colors.white, 0.30)!
            : Color.lerp(habitColor, const Color(0xFF64FFDA), 0.18)!;

        final plumeAlpha = (pProgress * (progress < 0.88 ? 0.82 : 1.0 - (progress - 0.88) * 0.4))
            .clamp(0.0, 0.85);

        final plumePaint = Paint()
          ..shader = RadialGradient(
            colors: [
              plumeTone.withValues(alpha: plumeAlpha),
              habitColor.withValues(alpha: plumeAlpha * 0.65),
              habitColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: plumeCenter, radius: plumeRadius));

        canvas.drawCircle(plumeCenter, plumeRadius, plumePaint);
      }

      // 4. Coalescing Fluid Box Flood (Progress 0.15 -> 1.0)
      final floodT = Curves.easeInOutCubic.transform(progress);
      canvas.drawRect(
        rect,
        Paint()..color = habitColor.withValues(alpha: floodT),
      );
    }

    // 5. Border glow transitioning to solid filled edge
    final borderColor = Color.lerp(
      habitColor.withValues(alpha: 0.35),
      habitColor,
      progress,
    )!;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FluidSmokeBoomPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.habitColor != habitColor ||
        oldDelegate.uncompletedColor != uncompletedColor;
  }
}
