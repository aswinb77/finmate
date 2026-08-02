import 'package:flutter/material.dart';

/// A smooth, subtle shimmer container widget for skeleton loading states.
class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 14.0,
    this.margin,
  });

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _colorAnim = ColorTween(
      begin: const Color(0xFFEDE5D2),
      end: const Color(0xFFE2D6C1),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: _colorAnim.value,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// A wrapper widget that displays a skeleton shimmer while image/font is loading.
class SkeletonIconLoader extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonIconLoader({
    super.key,
    required this.child,
    this.width = 48.0,
    this.height = 48.0,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return FrameLoader(
      placeholder: SkeletonContainer(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

/// Utility widget to handle deferred frame loading
class FrameLoader extends StatefulWidget {
  final Widget placeholder;
  final Widget child;

  const FrameLoader({
    super.key,
    required this.placeholder,
    required this.child,
  });

  @override
  State<FrameLoader> createState() => _FrameLoaderState();
}

class _FrameLoaderState extends State<FrameLoader> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Warm up next frame for zero-flicker render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return widget.placeholder;
    }
    return widget.child;
  }
}
