import 'package:flutter/cupertino.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Shows a simple error dialog with the given message.
/// This is a convenience method to reduce repetitive error dialog code.
Future<void> showErrorDialog(
  BuildContext context,
  String message, {
  String? title,
}) {
  final loc = context.read<AppLocalizations?>() ?? AppLocalizations(AppLocale.en);
  return showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: title != null ? Text(title) : null,
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          child: Text(loc.t('ok')),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

/// Shows a confirmation dialog and returns true if confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String? confirmText,
  String? cancelText,
  bool isDanger = false,
}) async {
  final loc = context.read<AppLocalizations?>() ?? AppLocalizations(AppLocale.en);
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          child: Text(cancelText ?? loc.t('cancel')),
          onPressed: () => Navigator.pop(context, false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDanger,
          child: Text(confirmText ?? loc.t('ok')),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return result == true;
}
