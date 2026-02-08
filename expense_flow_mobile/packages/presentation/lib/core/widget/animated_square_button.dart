import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';

class AnimatedSquareButtonConstants {
  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Duration iconTransitionDuration = Duration(milliseconds: 600);
  static const double defaultSize = 64.0;
  static const double defaultIconSize = 40.0;
  static const double borderRadius = 8.0;
  static const double defaultOpacity = 0.4;
}

class AnimatedSquareButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;
  final Widget icon;
  final double width;
  final double height;
  final double iconSize;
  final Color? borderColor;
  final Color? backgroundColor;
  final double opacity;

  /// Creates an animated square button with customizable properties.
  ///
  /// [isProcessing] determines if the button is in a processing state
  /// [onPressed] callback for button press
  /// [icon] widget to display in the button
  /// [width] button width (defaults to 64.0)
  /// [height] button height (defaults to 64.0)
  /// [iconSize] size of the icon (defaults to 40.0)
  /// [borderColor] color of button border (defaults to theme outline)
  /// [backgroundColor] color of button background (defaults to theme surface)
  /// [opacity] opacity of the background color (defaults to 0.4)
  const AnimatedSquareButton({
    super.key,
    required this.isProcessing,
    required this.onPressed,
    required this.icon,
    this.width = AnimatedSquareButtonConstants.defaultSize,
    this.height = AnimatedSquareButtonConstants.defaultSize,
    this.iconSize = AnimatedSquareButtonConstants.defaultIconSize,
    this.borderColor,
    this.backgroundColor,
    this.opacity = AnimatedSquareButtonConstants.defaultOpacity,
  });

  /// Creates an animated button with equal width and height.
  ///
  /// This constructor provides backward compatibility with the original implementation.
  /// [size] is used for both width and height.
  factory AnimatedSquareButton.square({
    Key? key,
    required bool isProcessing,
    required VoidCallback onPressed,
    required Widget icon,
    double size = AnimatedSquareButtonConstants.defaultSize,
    double iconSize = AnimatedSquareButtonConstants.defaultIconSize,
    Color? borderColor,
    Color? backgroundColor,
    double opacity = AnimatedSquareButtonConstants.defaultOpacity,
  }) {
    return AnimatedSquareButton(
      key: key,
      isProcessing: isProcessing,
      onPressed: onPressed,
      icon: icon,
      width: size,
      height: size,
      iconSize: iconSize,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      opacity: opacity,
    );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AnimatedSquareButtonConstants.animationDuration,
          curve: Curves.elasticOut,
          builder: _buildAnimatedButton,
        ),
      );

  Widget _buildAnimatedButton(
          BuildContext context, double value, Widget? child) =>
      Transform.scale(
        scale: value,
        child: _buildButtonContainer(context),
      );

  Widget _buildButtonContainer(BuildContext context) => Container(
        width: width,
        height: height,
        child: GlassContainer(
          width: width,
          height: height,
          blur: 16,
          tint: backgroundColor ?? Theme.of(context).colorScheme.surface,
          tintOpacity: opacity,
          borderRadius: BorderRadius.circular(
            AnimatedSquareButtonConstants.borderRadius,
          ),
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.outline,
          ),
          padding: EdgeInsets.zero,
          child: _buildButtonContent(),
        ),
      );

  Widget _buildButtonContent() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProcessing ? null : onPressed,
          borderRadius:
              BorderRadius.circular(AnimatedSquareButtonConstants.borderRadius),
          child: Center(
            child: _buildAnimatedIcon(),
          ),
        ),
      );

  Widget _buildAnimatedIcon() => AnimatedSwitcher(
        duration: AnimatedSquareButtonConstants.iconTransitionDuration,
        transitionBuilder: _buildIconTransition,
        child: icon,
      );

  Widget _buildIconTransition(Widget child, Animation<double> animation) {
    final scaleCurve =
        CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    final scaleValue = Tween<double>(begin: 0.8, end: 1.0).animate(scaleCurve);

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: scaleValue,
        child: child,
      ),
    );
  }
}
