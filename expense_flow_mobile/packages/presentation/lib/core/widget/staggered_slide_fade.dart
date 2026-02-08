import 'package:flutter/material.dart';

class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;
  final int maxStaggeredItems;

  const StaggeredSlideFade({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.08),
    this.maxStaggeredItems = 8,
  });

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _offset = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.index >= widget.maxStaggeredItems) {
      _controller.value = 1.0;
    } else {
      Future.delayed(widget.delayPerItem * widget.index, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}
