import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/theme/app_theme.dart';

class AppListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final int? titleMaxLines;
  final int? subtitleMaxLines;
  final bool dense;

  const AppListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.titleMaxLines,
    this.subtitleMaxLines,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Container(
      margin:
          margin ??
          const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingXs,
            AppTheme.spacingLg,
            0,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.getSurfaceLow(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: dense ? AppTheme.spacingSm : AppTheme.spacingMd,
                ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(
                    width: dense ? AppTheme.spacingSm : AppTheme.spacingMd,
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        DefaultTextStyle(
                          style:
                              theme.textTheme.body?.copyWith(
                                fontWeight: FontWeight.w500,
                              ) ??
                              const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: titleMaxLines ?? (dense ? 1 : 2),
                          overflow: TextOverflow.ellipsis,
                          child: title!,
                        ),
                      if (subtitle != null) ...[
                        SizedBox(
                          height: dense
                              ? AppTheme.spacingXs
                              : AppTheme.spacingSm,
                        ),
                        DefaultTextStyle(
                          style:
                              theme.textTheme.caption ??
                              const TextStyle(fontSize: 13, color: Colors.grey),
                          maxLines: subtitleMaxLines ?? (dense ? 1 : 3),
                          overflow: TextOverflow.ellipsis,
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(
                    width: dense ? AppTheme.spacingSm : AppTheme.spacingMd,
                  ),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return content;
  }
}

class AppSwitchListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppSwitchListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.backgroundColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      backgroundColor: backgroundColor,
      padding: padding,
      margin: margin,
      onTap: () => onChanged(!value),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    );
  }
}

class AppActionListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final Widget? trailing;

  const AppActionListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.margin,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppListTile(
      margin: margin,
      backgroundColor: backgroundColor,
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.heading?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.caption)
          : null,
      trailing:
          trailing ??
          Icon(
            CupertinoIcons.chevron_right,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            size: 18,
          ),
    );
  }
}

class AppSettingItem extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? valueWidget;
  final VoidCallback? onTap;
  final bool showArrow;
  final EdgeInsetsGeometry? margin;

  const AppSettingItem({
    super.key,
    required this.title,
    this.value,
    this.valueWidget,
    this.onTap,
    this.showArrow = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppListTile(
      margin: margin,
      onTap: onTap,
      title: Text(title, style: theme.textTheme.body?.copyWith(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: theme.textTheme.caption?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          if (valueWidget != null) valueWidget!,
          if (showArrow) ...[
            const SizedBox(width: AppTheme.spacingSm),
            Icon(
              CupertinoIcons.chevron_right,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}

class AppExpandableControl extends StatelessWidget {
  final bool isExpanded;
  final int collapsedCount;
  final int totalCount;
  final VoidCallback onToggle;

  const AppExpandableControl({
    super.key,
    required this.isExpanded,
    required this.collapsedCount,
    required this.totalCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remaining = totalCount - collapsedCount;

    if (remaining <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingSm,
          horizontal: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isExpanded ? '收起' : '+$remaining more',
              style: theme.textTheme.footnote?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
            Icon(
              isExpanded
                  ? CupertinoIcons.chevron_up
                  : CupertinoIcons.chevron_down,
              size: 14,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
