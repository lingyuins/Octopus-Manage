import 'package:flutter/material.dart';
import 'package:octopusmanage/theme/app_theme.dart';

class AppStatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onTap;

  const AppStatusChip({
    super.key,
    required this.label,
    this.isActive = true,
    this.activeColor,
    this.inactiveColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isActive
        ? (activeColor ?? colorScheme.success).withValues(alpha: 0.12)
        : (inactiveColor ?? colorScheme.error).withValues(alpha: 0.12);
    final textColor = isActive
        ? (activeColor ?? colorScheme.success)
        : (inactiveColor ?? colorScheme.error);

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );

    if (onTap != null) {
      chip = GestureDetector(onTap: onTap, child: chip);
    }

    return chip;
  }
}

class AppTypeChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const AppTypeChip({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class AppInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const AppInfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipColor = color ?? colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceHigh(colorScheme).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.caption?.copyWith(color: chipColor),
          ),
        ],
      ),
    );
  }
}

class AppLegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const AppLegendChip({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.brightness == Brightness.light
            ? const Color(0xFFE5E5EA).withValues(alpha: 0.7)
            : const Color(0xFF3A3A3C).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.caption),
        ],
      ),
    );
  }
}
