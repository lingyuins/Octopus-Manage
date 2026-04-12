import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/theme/app_theme.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool floating;
  final double toolbarHeight;
  final EdgeInsetsGeometry? titlePadding;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.floating = true,
    this.toolbarHeight = 92,
    this.titlePadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      floating: floating,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppTheme.getSurfaceLowest(colorScheme),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      titleSpacing: AppTheme.spacingLg,
      leading: leading,
      title: Padding(
        padding: titlePadding ?? EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.37,
                color: colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.footnote?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: actions,
    );
  }
}

class AppPageHeaderWithBack extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool floating;

  const AppPageHeaderWithBack({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.floating = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppPageHeader(
      title: title,
      subtitle: subtitle,
      floating: floating,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      actions: actions,
    );
  }
}

class AppHeroSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> highlights;
  final Widget? actionWidget;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;

  const AppHeroSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.highlights,
    this.actionWidget,
    this.gradient,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              0,
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
              gradient:
                  gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.primaryContainer.withValues(alpha: 0.5),
                      colorScheme.surfaceContainerLowest,
                    ],
                  ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppTheme.spacingXs),
                            Text(
                              subtitle!,
                              style: theme.textTheme.body?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actionWidget != null) actionWidget!,
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: highlights,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppHighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const AppHighlightChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.85)
            : const Color(0xFF2C2C2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: AppTheme.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.caption?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.footnote?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
