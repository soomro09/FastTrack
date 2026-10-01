import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Shared card surface — bordered container matching the app's card theme,
/// used by both the Profile and Settings screens.
class CardContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;

  const CardContainer({
    super.key,
    required this.child,
    required this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border(isDark)),
        boxShadow: isDark ? [] : AppTheme.shadowSm(isDark),
      ),
      child: child,
    );
  }
}
