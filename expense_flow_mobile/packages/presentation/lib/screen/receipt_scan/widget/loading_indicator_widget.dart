import 'package:flutter/material.dart';

class LoadingIndicatorWidget extends StatefulWidget {
  final bool isSuccess;
  final Duration transitionDuration;
  final double sizeFactor;

  const LoadingIndicatorWidget({
    super.key,
    this.isSuccess = false,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.sizeFactor = 0.25,
  });

  @override
  State<LoadingIndicatorWidget> createState() =>
      _CyberpunkLoadingIndicatorState();
}

class _CyberpunkLoadingIndicatorState extends State<LoadingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _loadingOpacity;
  late Animation<double> _successOpacity;

  late AnimationController _rotationController;
  late Animation<double> _outerRotation;
  late Animation<double> _middleRotation;
  late Animation<double> _innerRotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _loadingOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    _successOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _outerRotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _middleRotation = Tween<double>(begin: 2 * 3.14159, end: 0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _innerRotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: const Interval(0, 1, curve: Curves.linear),
      ),
    );

    if (widget.isSuccess) {
      _controller.value = 1.0;
      _rotationController.stop();
    }
  }

  @override
  void didUpdateWidget(LoadingIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _controller.forward();
      _rotationController.stop();
    } else if (!widget.isSuccess && oldWidget.isSuccess) {
      _controller.reverse();
      _rotationController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth * widget.sizeFactor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Loading State
          FadeTransition(
            opacity: _loadingOpacity,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: LoadingPainter(
                    outerRotation: _outerRotation.value,
                    middleRotation: _middleRotation.value,
                    innerRotation: _innerRotation.value,
                  ),
                  size: Size(size, size),
                );
              },
            ),
          ),

          // Success State
          FadeTransition(
            opacity: _successOpacity,
            child: CustomPaint(
              painter: SuccessPainter(),
              size: Size(size, size),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

class LoadingPainter extends CustomPainter {
  final double outerRotation;
  final double middleRotation;
  final double innerRotation;

  LoadingPainter({
    required this.outerRotation,
    required this.middleRotation,
    required this.innerRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 100;

    final outerPaint = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * scale;

    final middlePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * scale;

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    final accentPaint = Paint()
      ..color = const Color(0xFF00FF99)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.save();
    canvas.rotate(outerRotation);
    canvas.drawCircle(Offset.zero, 35 * scale, outerPaint);
    canvas.restore();

    canvas.save();
    canvas.rotate(middleRotation);
    canvas.drawCircle(Offset.zero, 30 * scale, middlePaint);
    canvas.restore();

    canvas.save();
    canvas.rotate(innerRotation);
    canvas.drawCircle(Offset.zero, 25 * scale, innerPaint);
    canvas.restore();

    canvas.save();
    canvas.rotate(outerRotation);
    _drawAccentPoints(canvas, accentPaint, 35 * scale, scale);
    canvas.restore();

    canvas.restore();
  }

  void _drawAccentPoints(
      Canvas canvas, Paint paint, double radius, double scale) {
    final pointRadius = 4.0 * scale;
    final points = [
      Offset(0, -radius),
      Offset(radius, 0),
      Offset(0, radius),
      Offset(-radius, 0),
    ];

    for (final point in points) {
      canvas.drawCircle(point, pointRadius, paint);
    }
  }

  @override
  bool shouldRepaint(LoadingPainter oldDelegate) =>
      oldDelegate.outerRotation != outerRotation ||
      oldDelegate.middleRotation != middleRotation ||
      oldDelegate.innerRotation != innerRotation;
}

class SuccessPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 100;

    final outerCheckmark = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * scale;

    final middleCheckmark = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * scale;

    final mainCheckmark = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    final accentPaint = Paint()
      ..color = const Color(0xFF00FF99)
      ..style = PaintingStyle.fill;

    _drawCheckmark(canvas, center, -5 * scale, outerCheckmark, scale);
    _drawCheckmark(canvas, center, -3 * scale, middleCheckmark, scale);
    _drawCheckmark(canvas, center, 0, mainCheckmark, scale);

    final points = _getCheckmarkPoints(center, 0, scale);
    for (final point in points) {
      canvas.drawCircle(point, 4 * scale, accentPaint);
    }
  }

  void _drawCheckmark(
      Canvas canvas, Offset center, double offset, Paint paint, double scale) {
    final points = _getCheckmarkPoints(center, offset, scale);
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy);

    canvas.drawPath(path, paint);
  }

  List<Offset> _getCheckmarkPoints(Offset center, double offset, double scale) {
    return [
      Offset(center.dx - 20 * scale + offset, center.dy),
      Offset(center.dx - 5 * scale + offset, center.dy + 15 * scale),
      Offset(center.dx + 25 * scale + offset, center.dy - 15 * scale),
    ];
  }

  @override
  bool shouldRepaint(SuccessPainter oldDelegate) => false;
}
