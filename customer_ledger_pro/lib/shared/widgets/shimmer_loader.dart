import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:customer_ledger_pro/core/theme/app_theme.dart';

/// Shimmer loading placeholder
class ShimmerLoader extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE5E7EB),
        highlightColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
