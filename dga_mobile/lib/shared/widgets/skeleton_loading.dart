import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../styles/app_styles.dart';

class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double? borderRadius;

  const SkeletonLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  // Built-in factories for common shapes
  factory SkeletonLoading.text({
    Key? key,
    double width = double.infinity,
    double height = 16.0,
  }) =>
      SkeletonLoading(
        key: key,
        width: width,
        height: height,
        borderRadius: AppRadius.small,
      );

  factory SkeletonLoading.avatar({
    Key? key,
    double size = 48.0,
  }) =>
      SkeletonLoading(
        key: key,
        width: size,
        height: size,
        borderRadius: size / 2,
      );

  factory SkeletonLoading.card({
    Key? key,
    double width = double.infinity,
    double height = 150.0,
  }) =>
      SkeletonLoading(
        key: key,
        width: width,
        height: height,
        borderRadius: AppRadius.medium,
      );

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.light
        ? AppColors.lightBorder.withValues(alpha: 0.5)
        : AppColors.darkBorder.withValues(alpha: 0.5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? AppRadius.small,
              ),
            ),
          ),
        );
      },
    );
  }
}
