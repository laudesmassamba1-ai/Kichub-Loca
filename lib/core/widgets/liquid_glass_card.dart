import 'dart:ui';

import 'package:flutter/material.dart';

class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 18,
    this.width,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: child,
        ),
      ),
    );
  }
}
