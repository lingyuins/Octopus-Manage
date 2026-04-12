import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';

import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_list_tile.dart';
import 'package:provider/provider.dart';

class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({super.key});

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  List<APIKey> _keys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      _keys = await api.getApiKeys();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleEnabled(APIKey key) async {
    try {
      final api = context.read<AppProvider>().api;
      await api.updateApiKey(
        APIKey(
          id: key.id,
          name: key.name,
          enabled: !key.enabled,
          expireAt: key.expireAt,
          maxCost: key.maxCost,
          supportedModels: key.supportedModels,
        ),
      );
      _loadKeys();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteKey(APIKey key, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete_api_key'),
      content: loc.t('delete_confirm', {'name': key.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteApiKey(key.id);
      _loadKeys();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showApiKeyDialog({APIKey? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final maxCostCtl = TextEditingController(
      text: existing?.maxCost.toString() ?? '0',
    );
    final expireAtCtl = TextEditingController(
      text: existing?.expireAt.toString() ?? '0',
    );
    final supportedModelsCtl = TextEditingController(
      text: existing?.supportedModels ?? '',
    );
    bool enabled = existing?.enabled ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: Text(isEdit ? loc.t('edit_api_key') : loc.t('create_api_key')),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoTextField(
                    controller: nameCtl,
                    placeholder: loc.t('name'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: maxCostCtl,
                    placeholder: loc.t('max_cost'),
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        '\$',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey.resolveFrom(ctx),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    keyboardType: TextInputType.number,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: expireAtCtl,
                    placeholder: loc.t('expire_at'),
                    padding: const EdgeInsets.all(12),
                    keyboardType: TextInputType.number,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: supportedModelsCtl,
                    placeholder: loc.t('supported_models'),
                    padding: const EdgeInsets.all(12),
                    maxLines: 2,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('enabled')),
                      CupertinoSwitch(
                        value: enabled,
                        onChanged: (v) => setDialogState(() => enabled = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.t('cancel')),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.t('save')),
            ),
          ],
        ),
      ),
    );

    nameCtl.dispose();
    maxCostCtl.dispose();
    expireAtCtl.dispose();
    supportedModelsCtl.dispose();

    if (result != true) return;

    try {
      final api = context.read<AppProvider>().api;
      final key = APIKey(
        id: existing?.id ?? 0,
        name: nameCtl.text.trim(),
        enabled: enabled,
        expireAt: int.tryParse(expireAtCtl.text) ?? 0,
        maxCost: double.tryParse(maxCostCtl.text) ?? 0,
        supportedModels: supportedModelsCtl.text.trim(),
      );
      if (isEdit) {
        await api.updateApiKey(key);
      } else {
        final newKey = await api.createApiKey(key);
        if (mounted && newKey.apiKey.isNotEmpty) {
          await AppTextDialog.show(
            context: context,
            title: loc.t('api_key_created'),
            content: newKey.apiKey,
            buttonText: loc.t('ok'),
            selectable: true,
          );
        }
      }
      _loadKeys();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.getSurfaceLowest(colorScheme),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(loc.t('api_keys')),
                  backgroundColor: AppTheme.getSurfaceLowest(
                    colorScheme,
                  ).withValues(alpha: 0.85),
                  border: null,
                ),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoadingState(),
                  )
                else if (_keys.isEmpty)
                  SliverFillRemaining(
                    child: AppEmptyState(
                      icon: CupertinoIcons.tag,
                      title: loc.t('no_api_keys'),
                      subtitle: loc.t('create_first_api_key'),
                      action: CupertinoButton.filled(
                        onPressed: () => _showApiKeyDialog(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.add, size: 18),
                            const SizedBox(width: 4),
                            Text(loc.t('create_api_key')),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final key = _keys[index];
                        return AppListTile(
                          margin: const EdgeInsets.fromLTRB(
                            AppTheme.spacingLg,
                            AppTheme.spacingSm,
                            AppTheme.spacingLg,
                            0,
                          ),
                          leading: CupertinoSwitch(
                            value: key.enabled,
                            onChanged: (_) => _toggleEnabled(key),
                          ),
                          title: Text(
                            key.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                key.apiKey.length > 16
                                    ? '${key.apiKey.substring(0, 16)}...'
                                    : key.apiKey,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                              if (key.supportedModels.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTheme.spacingXs,
                                  ),
                                  child: Wrap(
                                    spacing: AppTheme.spacingSm,
                                    children: key.supportedModels
                                        .split(',')
                                        .take(3)
                                        .map(
                                          (m) => AppInfoChip(
                                            icon: CupertinoIcons.cube_box,
                                            label: m.trim(),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _showApiKeyDialog(existing: key),
                                child: Icon(
                                  CupertinoIcons.pencil,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              GestureDetector(
                                onTap: () => _deleteKey(key, loc),
                                child: Icon(
                                  CupertinoIcons.delete,
                                  size: 20,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: _keys.length),
                    ),
                  ),
              ],
            ),
            if (!_loading && _keys.isNotEmpty)
              Positioned(
                right: AppTheme.spacingLg,
                bottom: 24,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(28),
                  color: colorScheme.primary,
                  onPressed: () => _showApiKeyDialog(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        CupertinoIcons.add,
                        size: 22,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loc.t('create_api_key'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
