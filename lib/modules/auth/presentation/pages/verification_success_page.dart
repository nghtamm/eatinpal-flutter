import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
import 'package:eatinpal/core/widgets/basic_appbar.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_bloc.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_event.dart';
import 'package:eatinpal/modules/auth/presentation/bloc/auth_state.dart';

class VerificationSuccessPage extends StatelessWidget {
  final String? token;

  const VerificationSuccessPage({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: _VerificationSuccessView(token: token),
    );
  }
}

class _VerificationSuccessView extends StatefulWidget {
  final String? token;

  const _VerificationSuccessView({required this.token});

  @override
  State<_VerificationSuccessView> createState() =>
      _VerificationSuccessViewState();
}

class _VerificationSuccessViewState extends State<_VerificationSuccessView>
    with TickerProviderStateMixin {
  late final AnimationController _arcController;
  late final AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkController.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthVerifiedLoginRequested());
      }
    });
  }

  @override
  void dispose() {
    _arcController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      context.go(RoutePaths.WELCOME);
    } else if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
      context.go(RoutePaths.WELCOME);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.NEUTRAL_95,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBadge(),
                SIZED_BOX_H40,
                _buildTitle(),
                SIZED_BOX_H12,
                _buildSubtitle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return SizedBox(
      width: 156,
      height: 156,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _arcController,
            builder: (_, _) => CustomPaint(
              size: const Size(156, 156),
              painter: _ArcPainter(progress: _arcController.value),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: AppColors.NEUTRAL_90,
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _checkController,
              builder: (_, _) => CustomPaint(
                size: const Size(140, 140),
                painter: _CheckPainter(
                  progress: Curves.easeOutCubic.transform(
                    _checkController.value,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'VERIFIED!',
      textAlign: TextAlign.center,
      style: AppTypography.DISPLAY_LARGE.copyWith(fontSize: 48),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Logging you in now...',
      textAlign: TextAlign.center,
      style: AppTypography.BODY_MEDIUM.copyWith(color: AppColors.NEUTRAL_40),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;

  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.PRIMARY
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const base = -math.pi / 2;
    const full = 2 * math.pi;
    const minSweep = math.pi * 0.15;
    const maxSweep = math.pi * 1.4;
    const curve = Curves.easeInOutCubic;

    double head;
    double tail;
    if (progress < 0.5) {
      final p = curve.transform(progress * 2);
      tail = 0;
      head = minSweep + (maxSweep - minSweep) * p;
    } else {
      final p = curve.transform((progress - 0.5) * 2);
      tail = (maxSweep - minSweep) * p;
      head = maxSweep;
    }

    final rotation = progress * (full - (maxSweep - minSweep));
    final start = base + rotation + tail;
    final sweep = head - tail;

    canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CheckPainter extends CustomPainter {
  final double progress;

  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = AppColors.PRIMARY
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.27, size.height * 0.50)
      ..lineTo(size.width * 0.44, size.height * 0.65)
      ..lineTo(size.width * 0.73, size.height * 0.35);

    final metric = path.computeMetrics().first;
    final extracted = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );
    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
