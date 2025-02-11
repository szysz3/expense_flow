import 'package:flutter/material.dart';

// purely AI generated

class LoadingIndicatorWidget extends StatefulWidget {
  final bool isLoading;
  final Duration transitionDuration;

  const LoadingIndicatorWidget({
    Key? key,
    this.isLoading = true,
    this.transitionDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _LoadingIndicatorWidgetState createState() => _LoadingIndicatorWidgetState();
}

class _LoadingIndicatorWidgetState extends State<LoadingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _successOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _successOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(LoadingIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.transitionDuration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: SizedBox(
        key: ValueKey<bool>(widget.isLoading),
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: LoadingIndicatorPainter(
            isLoading: widget.isLoading,
            rotationValue: _rotationAnimation.value,
            opacityValue: _opacityAnimation.value,
            successOpacity: _successOpacityAnimation.value,
            transitionProgress: widget.isLoading ? 0.0 : 1.0,
          ),
        ),
      ),
    );
  }
}

class LoadingIndicatorPainter extends CustomPainter {
  final bool isLoading;
  final double rotationValue;
  final double opacityValue;
  final double successOpacity;
  final double transitionProgress;

  LoadingIndicatorPainter({
    required this.isLoading,
    required this.rotationValue,
    required this.opacityValue,
    required this.successOpacity,
    required this.transitionProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (isLoading) {
      _drawLoadingState(canvas, size, center);
    } else {
      _drawSuccessState(canvas, size, center);
    }
  }

  void _drawLoadingState(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationValue);
    canvas.translate(-center.dx, -center.dy);

    // Outer circle with transition
    paint.color = const Color(0xFFFF00FF)
        .withOpacity(opacityValue * (1 - transitionProgress));
    canvas.drawCircle(center, 35, paint);

    // Middle circle with transition
    paint.color = const Color(0xFF00FFFF)
        .withOpacity(opacityValue * (1 - transitionProgress));
    paint.strokeWidth = 6.0;
    canvas.drawCircle(center, 30, paint);

    // Inner circle with transition
    paint.color = Colors.white.withOpacity(1 - transitionProgress);
    paint.strokeWidth = 4.0;
    canvas.drawCircle(center, 25, paint);

    // Accent points with transition
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF00FF99).withOpacity(1 - transitionProgress);
    canvas.drawCircle(Offset(center.dx, center.dy - 35), 4, paint);
    canvas.drawCircle(Offset(center.dx + 35, center.dy), 4, paint);
    canvas.drawCircle(Offset(center.dx, center.dy + 35), 4, paint);
    canvas.drawCircle(Offset(center.dx - 35, center.dy), 4, paint);

    canvas.restore();
  }

  void _drawSuccessState(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    // Animate checkmark appearance
    final successProgress = Curves.easeInOut.transform(transitionProgress);

    // Outer checkmark with transition
    paint.color = const Color(0xFFFF00FF).withOpacity(0.4 * successProgress);
    _drawCheckmark(canvas, center, 0, paint, successProgress);

    // Middle checkmark with transition
    paint.color = const Color(0xFF00FFFF).withOpacity(0.6 * successProgress);
    paint.strokeWidth = 6.0;
    _drawCheckmark(canvas, center, 2, paint, successProgress);

    // Inner checkmark with transition
    paint.color = Colors.white.withOpacity(successProgress);
    paint.strokeWidth = 4.0;
    _drawCheckmark(canvas, center, 5, paint, successProgress);

    // Accent points with transition
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF00FF99).withOpacity(successProgress);
    final pointProgress = successProgress * 4;
    if (pointProgress > 1) {
      canvas.drawCircle(Offset(center.dx - 15, center.dy), 4, paint);
    }
    if (pointProgress > 2) {
      canvas.drawCircle(Offset(center.dx - 5, center.dy + 10), 4, paint);
    }
    if (pointProgress > 3) {
      canvas.drawCircle(Offset(center.dx + 20, center.dy - 15), 4, paint);
    }
  }

  void _drawCheckmark(Canvas canvas, Offset center, double offset, Paint paint,
      double progress) {
    final path = Path();

    // Calculate checkmark points
    final start = Offset(center.dx - 20 + offset, center.dy);
    final mid = Offset(center.dx - 5 + offset, center.dy + 15);
    final end = Offset(center.dx + 25 + offset, center.dy - 15);

    // Animate checkmark drawing
    if (progress < 0.5) {
      // Draw first line
      final firstLineProgress = progress * 2;
      path.moveTo(start.dx, start.dy);
      path.lineTo(
        lerpDouble(start.dx, mid.dx, firstLineProgress),
        lerpDouble(start.dy, mid.dy, firstLineProgress),
      );
    } else {
      // Draw complete first line and animate second line
      final secondLineProgress = (progress - 0.5) * 2;
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);
      path.lineTo(
        lerpDouble(mid.dx, end.dx, secondLineProgress),
        lerpDouble(mid.dy, end.dy, secondLineProgress),
      );
    }

    canvas.drawPath(path, paint);
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(LoadingIndicatorPainter oldDelegate) {
    return oldDelegate.isLoading != isLoading ||
        oldDelegate.rotationValue != rotationValue ||
        oldDelegate.opacityValue != opacityValue ||
        oldDelegate.successOpacity != successOpacity ||
        oldDelegate.transitionProgress != transitionProgress;
  }
}
