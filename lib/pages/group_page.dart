import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:provider/provider.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List<Group> _groups = [];
  bool _loading = true;
  final Map<int, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      _groups = await api.getGroups();
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

  Future<void> _deleteGroup(Group g, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete_group'),
      content: loc.t('delete_confirm', {'name': g.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteGroup(g.id);
      _loadGroups();
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

  Future<void> _showGroupDialog({Group? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final matchRegexCtl = TextEditingController(
      text: existing?.matchRegex ?? '',
    );
    final timeoutCtl = TextEditingController(
      text: existing?.firstTokenTimeOut.toString() ?? '0',
    );
    final keepTimeCtl = TextEditingController(
      text: existing?.sessionKeepTime.toString() ?? '0',
    );
    int selectedMode = existing?.mode ?? 1;
    List<_GroupItemDraft> items =
        existing?.items
            .map(
              (e) => _GroupItemDraft(
                channelId: e.channelId,
                modelName: e.modelName,
                priority: e.priority,
                weight: e.weight,
              ),
            )
            .toList() ??
        [];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: Text(isEdit ? loc.t('edit_group') : loc.t('create_group')),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoTextField(
                    controller: nameCtl,
                    placeholder: loc.t('group_name'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: matchRegexCtl,
                    placeholder: loc.t('match_regex'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: timeoutCtl,
                    placeholder:
                        '${loc.t('token_timeout')} (${loc.t('second')})',
                    padding: const EdgeInsets.all(12),
                    keyboardType: TextInputType.number,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  CupertinoTextField(
                    controller: keepTimeCtl,
                    placeholder: '${loc.t('keep_time')} (${loc.t('second')})',
                    padding: const EdgeInsets.all(12),
                    keyboardType: TextInputType.number,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.t('channels')}: ${items.length}'),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final draft = await _showChannelPicker(
                            context,
                            items.isEmpty ? 0 : items.last.channelId,
                          );
                          if (draft != null) {
                            setDialogState(() => items.add(draft));
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.add, size: 18),
                            const SizedBox(width: 4),
                            Text(loc.t('add')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (items.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeBlue.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.activeBlue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  items[i].modelName.isEmpty
                                      ? 'Channel ${items[i].channelId}'
                                      : items[i].modelName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setDialogState(() => items.removeAt(i)),
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  size: 16,
                                  color: CupertinoColors.systemRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.t('cancel')),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.t('save')),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final group = Group(
        id: existing?.id ?? 0,
        name: nameCtl.text,
        mode: selectedMode,
        createdTime: existing?.createdTime ?? DateTime.now().toIso8601String(),
        firstTokenTimeOut: int.tryParse(timeoutCtl.text) ?? 0,
        sessionKeepTime: int.tryParse(keepTimeCtl.text) ?? 0,
        matchRegex: matchRegexCtl.text,
        items: items
            .map(
              (e) => GroupItem(
                channelId: e.channelId,
                modelName: e.modelName,
                priority: e.priority,
                weight: e.weight,
              ),
            )
            .toList(),
      );

      final api = context.read<AppProvider>().api;
      if (isEdit) {
        await api.updateGroup(group);
      } else {
        await api.createGroup(group);
      }
      _loadGroups();
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

  Future<_GroupItemDraft?> _showChannelPicker(
    BuildContext context,
    int currentChannelId,
  ) async {
    final api = context.read<AppProvider>().api;

    try {
      final channels = await api.getChannels();
      if (!context.mounted) return null;

      return showDialog<_GroupItemDraft>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('选择渠道'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView.builder(
              itemCount: channels.length,
              itemBuilder: (_, i) {
                final c = channels[i];
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(
                    _GroupItemDraft(
                      channelId: c.id,
                      modelName: c.model.isNotEmpty
                          ? c.model
                          : (c.customModel.isNotEmpty ? c.customModel : c.name),
                      priority: 100,
                      weight: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(fontSize: 15),
                              ),
                              Text(
                                'ID: ${c.id}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text('加载渠道失败: $e'),
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
    return null;
  }

  String _modeLabel(int mode, AppLocalizations loc) {
    switch (mode) {
      case 1:
        return loc.t('mode_round_robin');
      case 2:
        return loc.t('mode_random');
      case 3:
        return loc.t('mode_failover');
      case 4:
        return loc.t('mode_weighted');
      default:
        return 'Unknown';
    }
  }

  Color _modeColor(int mode) {
    switch (mode) {
      case 1:
        return const Color(0xFF007AFF);
      case 2:
        return const Color(0xFFAF52DE);
      case 3:
        return const Color(0xFFFF9500);
      case 4:
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  Widget _buildChannelsSection(
    Group g,
    AppLocalizations loc,
    ColorScheme colorScheme,
    int threshold,
  ) {
    final totalChannels = g.items.length;
    final isExpanded = _expandedGroups[g.id] ?? false;
    final displayCount = isExpanded
        ? totalChannels
        : threshold.clamp(0, totalChannels);
    final displayItems = g.items.take(displayCount).toList();
    final remaining = totalChannels - displayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.layers, size: 12, color: colorScheme.primary),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                '${loc.t('channels')}: $totalChannels',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingXs,
          children: displayItems
              .map(
                (item) => _ChannelChip(
                  channelId: item.channelId,
                  modelName: item.modelName,
                  colorScheme: colorScheme,
                ),
              )
              .toList(),
        ),
        if (totalChannels > threshold)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
            child: GestureDetector(
              onTap: () => setState(() => _expandedGroups[g.id] = !isExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: isExpanded
                            ? loc.t('collapse')
                            : remaining > 0
                            ? '+$remaining'
                            : loc.t('expand'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (!isExpanded && remaining > 0)
                        TextSpan(
                          text: ' more',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = Responsive.isCompact(context);
    final foldThreshold = isCompact ? 3 : 5;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.getSurfaceLowest(colorScheme),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(loc.t('groups')),
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
                else if (_groups.isEmpty)
                  SliverFillRemaining(
                    child: AppEmptyState(
                      icon: CupertinoIcons.folder,
                      title: loc.t('no_groups'),
                      subtitle: loc.t('create_first_group'),
                      action: CupertinoButton.filled(
                        onPressed: () => _showGroupDialog(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.add, size: 18),
                            const SizedBox(width: 4),
                            Text(loc.t('create_group')),
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
                        final g = _groups[index];
                        return AppListItemCard(
                          margin: const EdgeInsets.fromLTRB(
                            AppTheme.spacingLg,
                            AppTheme.spacingSm,
                            AppTheme.spacingLg,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      g.name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  AppTypeChip(
                                    label: _modeLabel(g.mode, loc),
                                    color: _modeColor(g.mode),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  GestureDetector(
                                    onTap: () => _showGroupDialog(existing: g),
                                    child: Icon(
                                      CupertinoIcons.pencil,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  GestureDetector(
                                    onTap: () => _deleteGroup(g, loc),
                                    child: Icon(
                                      CupertinoIcons.delete,
                                      size: 18,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              if (g.firstTokenTimeOut > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTheme.spacingXs,
                                  ),
                                  child: AppInfoChip(
                                    icon: CupertinoIcons.timer,
                                    label:
                                        '${g.firstTokenTimeOut}${loc.t("second")}',
                                  ),
                                ),
                              if (g.sessionKeepTime > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTheme.spacingXs,
                                  ),
                                  child: AppInfoChip(
                                    icon: CupertinoIcons.clock,
                                    label:
                                        '${g.sessionKeepTime}${loc.t("second")}',
                                  ),
                                ),
                              if (g.items.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingSm),
                                _buildChannelsSection(
                                  g,
                                  loc,
                                  colorScheme,
                                  foldThreshold,
                                ),
                              ],
                            ],
                          ),
                        );
                      }, childCount: _groups.length),
                    ),
                  ),
              ],
            ),
            if (!_loading && _groups.isNotEmpty)
              Positioned(
                right: AppTheme.spacingLg,
                bottom: 24,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(28),
                  color: colorScheme.primary,
                  onPressed: () => _showGroupDialog(),
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
                        loc.t('create_group'),
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

class _ChannelChip extends StatelessWidget {
  final int channelId;
  final String modelName;
  final ColorScheme colorScheme;

  const _ChannelChip({
    required this.channelId,
    required this.modelName,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Text(
                '$channelId',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            modelName.isEmpty ? 'Ch$channelId' : modelName,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GroupItemDraft {
  int channelId;
  String modelName;
  int priority;
  int weight;

  _GroupItemDraft({
    this.channelId = 0,
    this.modelName = '',
    this.priority = 0,
    this.weight = 0,
  });
}
