import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_list_tile.dart';
import 'package:provider/provider.dart';

class ChannelPage extends StatefulWidget {
  const ChannelPage({super.key});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  List<Channel> _channels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      _channels = await api.getChannels();
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

  Future<void> _toggleEnabled(Channel ch) async {
    try {
      final api = context.read<AppProvider>().api;
      await api.enableChannel(ch.id, !ch.enabled);
      _loadChannels();
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

  Future<void> _deleteChannel(Channel ch, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete_channel'),
      content: loc.t('delete_confirm', {'name': ch.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteChannel(ch.id);
      _loadChannels();
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

  Future<void> _showChannelDialog({Channel? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final modelCtl = TextEditingController(text: existing?.model ?? '');
    final customModelCtl = TextEditingController(
      text: existing?.customModel ?? '',
    );
    final urlCtl = TextEditingController(
      text: existing?.baseUrls.isNotEmpty == true
          ? existing!.baseUrls.first.url
          : '',
    );
    final keyCtl = TextEditingController(
      text: existing?.keys.isNotEmpty == true
          ? existing!.keys.first.channelKey
          : '',
    );
    int selectedType = existing?.type ?? 1;
    bool enabled = existing?.enabled ?? true;
    bool proxy = existing?.proxy ?? false;
    bool autoSync = existing?.autoSync ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: Text(isEdit ? loc.t('edit_channel') : loc.t('create_channel')),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoTextField(
                    controller: nameCtl,
                    placeholder: loc.t('channel_name'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: urlCtl,
                    placeholder: loc.t('base_url'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: keyCtl,
                    placeholder: loc.t('api_key'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: modelCtl,
                    placeholder: loc.t('model'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: customModelCtl,
                    placeholder: loc.t('custom_model'),
                    padding: const EdgeInsets.all(12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('proxy')),
                      CupertinoSwitch(
                        value: proxy,
                        onChanged: (v) => setDialogState(() => proxy = v),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('auto_sync')),
                      CupertinoSwitch(
                        value: autoSync,
                        onChanged: (v) => setDialogState(() => autoSync = v),
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
    modelCtl.dispose();
    customModelCtl.dispose();
    urlCtl.dispose();
    keyCtl.dispose();

    if (result != true) return;

    try {
      final api = context.read<AppProvider>().api;
      final channel = Channel(
        id: existing?.id ?? 0,
        name: nameCtl.text.trim(),
        type: selectedType,
        enabled: enabled,
        baseUrls: urlCtl.text.trim().isNotEmpty
            ? [BaseUrl(url: urlCtl.text.trim())]
            : [],
        keys: keyCtl.text.trim().isNotEmpty
            ? [
                ChannelKey(
                  id: 0,
                  channelId: existing?.id ?? 0,
                  channelKey: keyCtl.text.trim(),
                ),
              ]
            : [],
        model: modelCtl.text.trim(),
        customModel: customModelCtl.text.trim(),
        proxy: proxy,
        autoSync: autoSync,
      );
      if (isEdit) {
        await api.updateChannel(channel);
      } else {
        await api.createChannel(channel);
      }
      _loadChannels();
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

  String _channelTypeName(int type, AppLocalizations loc) {
    switch (type) {
      case 1:
        return loc.t('type_openai_chat');
      case 2:
        return loc.t('type_openai_response');
      case 3:
        return loc.t('type_openai_embedding');
      case 4:
        return loc.t('type_anthropic');
      case 5:
        return loc.t('type_gemini');
      case 6:
        return loc.t('type_volcengine');
      default:
        return 'Type $type';
    }
  }

  Color _channelTypeColor(int type) {
    switch (type) {
      case 1:
        return const Color(0xFF007AFF);
      case 2:
        return const Color(0xFF5AC8FA);
      case 3:
        return const Color(0xFF34C759);
      case 4:
        return const Color(0xFF5856D6);
      case 5:
        return const Color(0xFFFF9500);
      case 6:
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
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
                  largeTitle: Text(loc.t('channels')),
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
                else if (_channels.isEmpty)
                  SliverFillRemaining(
                    child: AppEmptyState(
                      icon: CupertinoIcons.arrow_3_trianglepath,
                      title: loc.t('no_channels'),
                      subtitle: loc.t('create_first_channel'),
                      action: CupertinoButton.filled(
                        onPressed: () => _showChannelDialog(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.add, size: 18),
                            const SizedBox(width: 4),
                            Text(loc.t('create_channel')),
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
                        final ch = _channels[index];
                        return AppListTile(
                          margin: const EdgeInsets.fromLTRB(
                            AppTheme.spacingLg,
                            AppTheme.spacingSm,
                            AppTheme.spacingLg,
                            0,
                          ),
                          leading: CupertinoSwitch(
                            value: ch.enabled,
                            onChanged: (_) => _toggleEnabled(ch),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ch.name,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              AppTypeChip(
                                label: _channelTypeName(ch.type, loc),
                                color: _channelTypeColor(ch.type),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ch.keys.isNotEmpty)
                                AppInfoChip(
                                  icon: CupertinoIcons.tag,
                                  label:
                                      '${ch.keys.where((k) => k.enabled).length}/${ch.keys.length}',
                                ),
                              if (ch.stats != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTheme.spacingXs,
                                  ),
                                  child: Wrap(
                                    spacing: AppTheme.spacingSm,
                                    children: [
                                      AppInfoChip(
                                        icon: CupertinoIcons.checkmark_circle,
                                        label: '${ch.stats!.requestSuccess}',
                                      ),
                                      AppInfoChip(
                                        icon: CupertinoIcons.xmark_circle,
                                        label: '${ch.stats!.requestFailed}',
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _showChannelDialog(existing: ch),
                                child: Icon(
                                  CupertinoIcons.pencil,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              GestureDetector(
                                onTap: () => _deleteChannel(ch, loc),
                                child: Icon(
                                  CupertinoIcons.delete,
                                  size: 20,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: _channels.length),
                    ),
                  ),
              ],
            ),
            if (!_loading && _channels.isNotEmpty)
              Positioned(
                right: AppTheme.spacingLg,
                bottom: 24,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(28),
                  color: colorScheme.primary,
                  onPressed: () => _showChannelDialog(),
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
                        loc.t('create_channel'),
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
