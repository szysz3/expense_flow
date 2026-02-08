import 'package:flutter/material.dart';

import 'glass_container.dart';
import 'loading_indicator_widget.dart';

class FullScreenLoadingOverlay {
  OverlayEntry? _entry;
  final ValueNotifier<bool> _isSuccess = ValueNotifier(false);

  bool get isShowing => _entry != null;

  void show(BuildContext context) {
    if (_entry != null) return;
    _isSuccess.value = false;
    _entry = OverlayEntry(
      builder: (_) => _OverlayContent(isSuccess: _isSuccess),
    );
    Overlay.of(context).insert(_entry!);
  }

  void update({required bool isSuccess}) {
    _isSuccess.value = isSuccess;
  }

  void hide() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _isSuccess.value = false;
  }

  void dispose() {
    hide();
    _isSuccess.dispose();
  }
}

class _OverlayContent extends StatefulWidget {
  final ValueNotifier<bool> isSuccess;

  const _OverlayContent({required this.isSuccess});

  @override
  State<_OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<_OverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeController,
        child: AbsorbPointer(
          child: GlassContainer(
            blur: 30,
            tintOpacity: 0.18,
            borderRadius: BorderRadius.zero,
            border: const Border(),
            boxShadow: const [],
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.isSuccess,
                builder: (_, isSuccess, __) => LoadingIndicatorWidget(
                  isSuccess: isSuccess,
                  sizeFactor: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
