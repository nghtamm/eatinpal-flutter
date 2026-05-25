import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';
import 'package:eatinpal/core/di/service_locator.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:eatinpal/core/widgets/app_snackbar.dart';
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
  late final AnimationController _particlesController;
  late final AnimationController _haloController;
  late final List<_ParticleDef> _particles;

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
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..repeat();
    _particles = _ParticleDef.generate(count: 14, seed: 7);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    final storage = sl<LocalStorage>();
    final token = widget.token ?? await storage.verificationToken;

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go(RoutePaths.HOME);
      return;
    }

    await storage.clearVerificationToken();
    if (!mounted) return;
    context.read<AuthBloc>().add(AuthVerifyFromLinkRequested(token));
  }

  @override
  void dispose() {
    _arcController.dispose();
    _checkController.dispose();
    _particlesController.dispose();
    _haloController.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      context.go(RoutePaths.HOME);
    } else if (state is AuthFailure) {
      AppSnackbar.error(context, state.message);
      context.go(RoutePaths.AUTHENTICATION);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.SURFACE,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              _badge(),
              SIZED_BOX_H40,
              _title(),
              SIZED_BOX_H12,
              _subtitle(),
              const Spacer(),
              const _LoadingDots(),
              SIZED_BOX_H32,
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _particlesController,
            builder: (_, _) => CustomPaint(
              size: const Size(240, 240),
              painter: _ParticlesPainter(
                progress: _particlesController.value,
                particles: _particles,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _haloController,
            builder: (_, _) => CustomPaint(
              size: const Size(240, 240),
              painter: _HaloPainter(progress: _haloController.value),
            ),
          ),
          SizedBox(
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
                    color: AppColors.WHITE,
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
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return Text(
      'VERIFIED!',
      textAlign: TextAlign.center,
      style: AppTypography.DISPLAY_LARGE.copyWith(
        fontSize: 46,
        letterSpacing: -1,
      ),
    );
  }

  Widget _subtitle() {
    return Text(
      'Logging you in now…',
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
      ..strokeWidth = 8
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

class _HaloPainter extends CustomPainter {
  final double progress;

  _HaloPainter({required this.progress});

  static const _COUNT = 3;
  static const _ARC_OUTER = 78.0;
  static const _STROKE = 12.0;
  static const _TRAVEL = 34.0;
  static const _MAX_ALPHA = 0.13;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < _COUNT; i++) {
      final p = (progress + i / _COUNT) % 1.0;
      final innerEdge = _ARC_OUTER + _TRAVEL * p;
      final centerR = innerEdge + _STROKE / 2;
      final alpha = (1 - p).clamp(0.0, 1.0) * _MAX_ALPHA;
      final paint = Paint()
        ..color = AppColors.PRIMARY.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _STROKE;
      canvas.drawCircle(center, centerR, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ParticleDef {
  final double angle;
  final double phase;
  final double duty;
  final double innerR;
  final double outerR;
  final double size;
  final Color color;

  const _ParticleDef({
    required this.angle,
    required this.phase,
    required this.duty,
    required this.innerR,
    required this.outerR,
    required this.size,
    required this.color,
  });

  static List<_ParticleDef> generate({required int count, required int seed}) {
    final rng = math.Random(seed);
    return List.generate(count, (i) {
      final inner = 84.0 + rng.nextDouble() * 6;
      return _ParticleDef(
        angle: rng.nextDouble() * 2 * math.pi,
        phase: rng.nextDouble(),
        duty: 0.18 + rng.nextDouble() * 0.12,
        innerR: inner,
        outerR: inner + 18 + rng.nextDouble() * 14,
        size: 3.0 + rng.nextDouble() * 2.5,
        color: rng.nextBool() ? AppColors.PRIMARY : AppColors.PRIMARY_80,
      );
    });
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  final List<_ParticleDef> particles;

  _ParticlesPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final localP = (progress + p.phase) % 1.0;
      if (localP > p.duty) continue;

      final t = localP / p.duty;
      final r =
          p.innerR + (p.outerR - p.innerR) * Curves.easeOutCubic.transform(t);
      final alpha = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.6;

      final pos = Offset(
        center.dx + math.cos(p.angle) * r,
        center.dy + math.sin(p.angle) * r,
      );
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(pos, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  static const _COUNT = 3;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  double _opacityFor(int i, double t) {
    final phase = (t - i / _COUNT) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.25 + 0.75 * wave;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_COUNT, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.XS),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.PRIMARY.withValues(
                  alpha: _opacityFor(i, _ctl.value),
                ),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
