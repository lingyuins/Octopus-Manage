import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final bool isDanger;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      content: Text(
        content,
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText ?? 'Cancel',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDanger,
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText ?? 'Confirm',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDanger
                  ? colorScheme.error
                  : (confirmColor ?? colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
      ),
    );
    return result == true;
  }
}

class AppInputDialog extends StatefulWidget {
  final String title;
  final String? hint;
  final String? initialValue;
  final String? confirmText;
  final String? cancelText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const AppInputDialog({
    super.key,
    required this.title,
    this.hint,
    this.initialValue,
    this.confirmText,
    this.cancelText,
    this.keyboardType,
    this.maxLines,
    this.validator,
  });

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? hint,
    String? initialValue,
    String? confirmText,
    String? cancelText,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => AppInputDialog(
        title: title,
        hint: hint,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}

class _AppInputDialogState extends State<AppInputDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(widget.title),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CupertinoTextField(
                controller: _controller,
                placeholder: widget.hint,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines ?? 1,
                autofocus: true,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.brightness == Brightness.light
                      ? const Color(0xFFE5E5EA)
                      : const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelText ?? 'Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            if (_formKey.currentState?.validate() ?? true) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: Text(widget.confirmText ?? 'Save'),
        ),
      ],
    );
  }
}

class AppTextDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? buttonText;
  final bool selectable;

  const AppTextDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: selectable
            ? SelectableText(
                content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                // 允许长字符串（如 API Key）自动换行，防止横向溢出
                textAlign: TextAlign.start,
              )
            : Text(content, softWrap: true),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText ?? 'OK'),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    bool selectable = true,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AppTextDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        selectable: selectable,
      ),
    );
  }
}

class AppActionSheet extends StatelessWidget {
  final String? title;
  final List<AppActionItem> actions;

  const AppActionSheet({super.key, this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = context.read<AppProvider>().loc;

    return CupertinoActionSheet(
      title: title != null
          ? Text(
              title!,
              style: theme.textTheme.footnote?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      actions: actions.map((action) {
        return CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            action.onTap?.call();
          },
          isDestructiveAction: action.isDestructive,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (action.icon != null) ...[
                Icon(
                  action.icon,
                  color: action.isDestructive
                      ? colorScheme.error
                      : colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                action.label,
                style: TextStyle(
                  color: action.isDestructive
                      ? colorScheme.error
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: Text(
          loc.t('cancel'),
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    String? title,
    required List<AppActionItem> actions,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => AppActionSheet(title: title, actions: actions),
    );
  }
}

class AppActionItem {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;
  final VoidCallback? onTap;

  const AppActionItem({
    required this.label,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    this.onTap,
  });
}
