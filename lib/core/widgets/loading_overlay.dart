import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:eatinpal/core/constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color barrierColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.barrierColor = AppColors.SCRIM,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: Stack(
        children: [
          AbsorbPointer(absorbing: isLoading, child: child),
          if (isLoading) ...[
            Positioned.fill(
              child: ColoredBox(
                color: barrierColor,
                child: const Center(child: AppCircularProgress()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppCircularProgress extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final Duration duration;

  const AppCircularProgress({
    super.key,
    this.size = 48,
    this.strokeWidth = 6,
    this.color = AppColors.WHITE,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<AppCircularProgress> createState() => _AppCircularProgressState();
}

class _AppCircularProgressState extends State<AppCircularProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          painter: _ChaseArcPainter(
            progress: _controller.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _ChaseArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ChaseArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    const base = -math.pi / 2;
    const full = 2 * math.pi;
    const curve = Curves.easeInOutCubic;

    double start;
    double sweep;

    if (progress < 0.5) {
      final p = curve.transform(progress * 2);
      start = base;
      sweep = p * full;
    } else {
      final p = curve.transform((progress - 0.5) * 2);
      start = base + p * full;
      sweep = (1 - p) * full;
    }

    if (sweep > 0) canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_ChaseArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
