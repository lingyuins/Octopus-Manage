import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/ai_route.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/models/group_probe.dart';
import 'package:octopusmanage/models/llm.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/ai_route_progress_sheet.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List<Group> _groups = [];
  List<LLMChannel> _modelChannels = [];
  bool _loading = true;
  bool _autoGrouping = false;
  int? _testingGroupId;
  bool _startingTableAIRoute = false;
  int? _startingAIRouteGroupId;
  final Map<int, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      final groupsFuture = api.getGroups();
      final modelChannelsFuture = api.getModelChannels();
      final groups = await groupsFuture;
      final modelChannels = await modelChannelsFuture;

      final dedupedChannels = <String, LLMChannel>{};
      for (final item in modelChannels) {
        dedupedChannels.putIfAbsent(
          _modelChannelKey(item.channelId, item.name),
          () => item,
        );
      }

      groups.sort((a, b) => a.name.compareTo(b.name));
      _groups = groups;
      _modelChannels = dedupedChannels.values.toList()
        ..sort((a, b) {
          final channelCompare = _channelDisplayName(
            a.channelId,
            a.channelName,
          ).compareTo(_channelDisplayName(b.channelId, b.channelName));
          if (channelCompare != 0) return channelCompare;
          return a.name.compareTo(b.name);
        });
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteGroup(Group group, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete_group'),
      content: loc.t('delete_confirm', {'name': group.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      await api.deleteGroup(group.id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _autoGroupModels(AppLocalizations loc) async {
    if (_autoGrouping) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('auto_group_confirm_title'),
      content: loc.t('auto_group_confirm_content'),
      confirmText: loc.t('auto_group_models'),
      cancelText: loc.t('cancel'),
    );
    if (!confirmed || !mounted) return;

    setState(() => _autoGrouping = true);
    try {
      final api = context.read<AppProvider>().api;
      final result = await api.autoGroupModels();
      await _loadData();
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('auto_group_success'),
        content: _formatAutoGroupResult(result, loc),
        buttonText: loc.t('ok'),
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          e.toString(),
          title: loc.t('auto_group_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _autoGrouping = false);
    }
  }

  Future<void> _testGroup(Group group, AppLocalizations loc) async {
    if (_testingGroupId != null) return;

    setState(() => _testingGroupId = group.id);
    try {
      final api = context.read<AppProvider>().api;
      var progress = await api.startGroupTest(group.id);

      while (!progress.done) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        progress = await api.getGroupTestProgress(progress.id);
      }

      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('test_group'),
        content: _formatGroupTestProgress(group, progress, loc),
        buttonText: loc.t('ok'),
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          e.toString(),
          title: loc.t('test_group_request_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _testingGroupId = null);
    }
  }

  Future<void> _showGroupEditor({Group? existing}) async {
    final group = await showModalBottomSheet<Group>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _GroupEditorSheet(existing: existing, modelChannels: _modelChannels),
    );
    if (group == null || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      if (existing == null) {
        await api.createGroup(group);
      } else {
        final update = GroupUpdateRequest.fromDiff(existing, group);
        if (!update.hasChanges) return;
        await api.updateGroup(update);
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _startAIRoute(AppLocalizations loc, {Group? group}) async {
    final scope = group == null ? AIRouteScope.table : AIRouteScope.group;
    final groupId = group?.id ?? 0;
    final isGroupScope = scope == AIRouteScope.group;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('ai_route_confirm_title'),
      content: isGroupScope
          ? loc.t('ai_route_confirm_group', {'name': group!.name})
          : loc.t('ai_route_confirm_table'),
      confirmText: isGroupScope
          ? loc.t('ai_route_generate_group')
          : loc.t('ai_route_generate_table'),
      cancelText: loc.t('cancel'),
    );
    if (!confirmed || !mounted) return;

    setState(() {
      if (isGroupScope) {
        _startingAIRouteGroupId = groupId;
      } else {
        _startingTableAIRoute = true;
      }
    });

    try {
      final api = context.read<AppProvider>().api;
      final progress = await api.generateAIRoute(
        scope: scope,
        groupId: isGroupScope ? groupId : null,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AIRouteProgressSheet(
          initialProgress: progress,
          onCompleted: _loadData,
        ),
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          e.toString(),
          title: loc.t('ai_route_start_failed'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _startingTableAIRoute = false;
          _startingAIRouteGroupId = null;
        });
      }
    }
  }

  String _formatAutoGroupResult(AutoGroupResult result, AppLocalizations loc) {
    final buffer = StringBuffer();
    buffer.writeln(loc.t('auto_group_summary'));
    buffer.writeln();
    buffer.writeln('${loc.t('channels')}: ${result.totalChannels}');
    buffer.writeln('${loc.t('models')}: ${result.totalModelsSeen}');
    buffer.writeln('${loc.t('created')}: ${result.createdGroups}');
    buffer.writeln('${loc.t('skipped')}: ${result.skippedExistingGroups}');
    if (result.skippedCoveredModels > 0) {
      buffer.writeln('${loc.t('show_less')}: ${result.skippedCoveredModels}');
    }
    if (result.failedGroups > 0) {
      buffer.writeln('${loc.t('failed')}: ${result.failedGroups}');
    }

    if (result.created.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${loc.t('created')}:');
      for (final item in result.created.take(12)) {
        buffer.writeln(
          '- ${item.name} [${_endpointTypeLabel(item.endpointType, loc)}]',
        );
      }
    }

    if (result.skipped.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${loc.t('skipped')}:');
      for (final item in result.skipped.take(12)) {
        buffer.writeln('- ${item.name}: ${item.reason}');
      }
    }

    return buffer.toString().trim();
  }

  String _formatGroupTestProgress(
    Group group,
    GroupModelTestProgress progress,
    AppLocalizations loc,
  ) {
    if (progress.message.isNotEmpty && progress.results.isEmpty) {
      return progress.message;
    }

    if (progress.results.isEmpty) {
      return loc.t('no_data');
    }

    final buffer = StringBuffer();
    buffer.writeln(
      progress.passed ? loc.t('test_group_passed') : loc.t('test_group_failed'),
    );
    buffer.writeln('${group.name}  ${progress.completed}/${progress.total}');
    buffer.writeln();

    for (final result in progress.results) {
      final status = result.passed ? 'PASS' : 'FAIL';
      final channelName = result.channelName.isNotEmpty
          ? result.channelName
          : _channelDisplayName(result.channelId, '');
      buffer.writeln('$status  $channelName / ${result.modelName}');
      buffer.writeln('HTTP ${result.statusCode}  #${result.attempts}');
      if (result.message.isNotEmpty) {
        buffer.writeln(result.message);
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
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
      case 5:
        return loc.t('mode_auto');
      default:
        return 'Mode $mode';
    }
  }

  Color _modeColor(int mode) {
    switch (mode) {
      case 1:
        return AppTheme.colorBlue;
      case 2:
        return AppTheme.colorPurple;
      case 3:
        return AppTheme.colorOrange;
      case 4:
        return AppTheme.colorGreen;
      case 5:
        return AppTheme.colorTeal;
      default:
        return AppTheme.colorGray;
    }
  }

  String _endpointTypeLabel(String endpointType, AppLocalizations loc) {
    switch (normalizeGroupEndpointType(endpointType)) {
      case '*':
        return loc.t('endpoint_all');
      case 'chat':
        return loc.t('endpoint_chat');
      case 'embeddings':
        return loc.t('endpoint_embeddings');
      case 'rerank':
        return loc.t('endpoint_rerank');
      case 'moderations':
        return loc.t('endpoint_moderations');
      case 'image_generation':
        return loc.t('endpoint_image_generation');
      case 'audio_speech':
        return loc.t('endpoint_audio_speech');
      case 'audio_transcription':
        return loc.t('endpoint_audio_transcription');
      case 'video_generation':
        return loc.t('endpoint_video_generation');
      case 'music_generation':
        return loc.t('endpoint_music_generation');
      case 'search':
        return loc.t('endpoint_search');
      default:
        return endpointType;
    }
  }

  Color _endpointTypeColor(String endpointType) {
    switch (normalizeGroupEndpointType(endpointType)) {
      case '*':
        return AppTheme.colorGray;
      case 'chat':
        return AppTheme.colorBlue;
      case 'embeddings':
        return AppTheme.colorGreen;
      case 'rerank':
        return AppTheme.colorOrange;
      case 'moderations':
        return AppTheme.colorPurple;
      case 'image_generation':
        return AppTheme.colorRed;
      case 'audio_speech':
        return AppTheme.colorTeal;
      case 'audio_transcription':
        return AppTheme.colorIndigo;
      case 'video_generation':
        return AppTheme.colorPink;
      case 'music_generation':
        return AppTheme.colorOrange;
      case 'search':
        return AppTheme.colorBlue;
      default:
        return AppTheme.colorGray;
    }
  }

  Widget _buildItemsSection(
    Group group,
    AppLocalizations loc,
    ColorScheme colorScheme,
    int threshold,
  ) {
    final totalItems = group.items.length;
    final isExpanded = _expandedGroups[group.id] ?? false;
    final displayCount = isExpanded
        ? totalItems
        : threshold.clamp(0, totalItems);
    final displayItems = group.items.take(displayCount).toList();
    final remaining = totalItems - displayCount;
    final channelMap = _modelChannelsByKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingXs,
          children: displayItems.map((item) {
            final channel =
                channelMap[_modelChannelKey(item.channelId, item.modelName)];
            return _GroupItemChip(
              channelId: item.channelId,
              channelName: _channelDisplayName(
                item.channelId,
                channel?.channelName ?? '',
              ),
              modelName: item.modelName,
              enabled: channel?.enabled ?? true,
              colorScheme: colorScheme,
            );
          }).toList(),
        ),
        if (totalItems > threshold)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSm),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _expandedGroups[group.id] = !isExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
                child: Text(
                  isExpanded
                      ? loc.t('collapse')
                      : '+$remaining ${loc.t('show_more')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Map<String, LLMChannel> _modelChannelsByKey() => {
    for (final item in _modelChannels)
      _modelChannelKey(item.channelId, item.name): item,
  };

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = Responsive.isCompact(context);
    final foldThreshold = isCompact ? 4 : 6;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.getSurfaceLowest(colorScheme),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(loc.t('groups')),
                  backgroundColor: AppTheme.getSurfaceLowest(
                    colorScheme,
                  ).withValues(alpha: 0.85),
                  border: null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _startingTableAIRoute
                            ? null
                            : () => _startAIRoute(loc),
                        child: _startingTableAIRoute
                            ? const CupertinoActivityIndicator(radius: 10)
                            : Icon(
                                Icons.auto_awesome,
                                size: 21,
                                color: colorScheme.primary,
                              ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      GestureDetector(
                        onTap: _autoGrouping
                            ? null
                            : () => _autoGroupModels(loc),
                        child: _autoGrouping
                            ? const CupertinoActivityIndicator(radius: 10)
                            : Icon(
                                CupertinoIcons.sparkles,
                                size: 22,
                                color: colorScheme.primary,
                              ),
                      ),
                    ],
                  ),
                ),
                CupertinoSliverRefreshControl(onRefresh: _loadData),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoadingState(),
                  )
                else if (_groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: CupertinoIcons.folder,
                      title: loc.t('no_groups'),
                      subtitle: loc.t('create_first_group'),
                      action: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton.filled(
                            onPressed: () => _showGroupEditor(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.add, size: 18),
                                const SizedBox(width: 4),
                                Text(loc.t('create_group')),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          CupertinoButton(
                            onPressed: _startingTableAIRoute
                                ? null
                                : () => _startAIRoute(loc),
                            child: _startingTableAIRoute
                                ? const CupertinoActivityIndicator()
                                : Text(loc.t('ai_route_generate_table')),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          CupertinoButton(
                            onPressed: _autoGrouping
                                ? null
                                : () => _autoGroupModels(loc),
                            child: _autoGrouping
                                ? const CupertinoActivityIndicator()
                                : Text(loc.t('auto_group_models')),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final group = _groups[index];
                        final isTesting = _testingGroupId == group.id;
                        final isStartingAIRoute =
                            _startingAIRouteGroupId == group.id;

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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppTheme.spacingXs,
                                        ),
                                        Wrap(
                                          spacing: AppTheme.spacingSm,
                                          runSpacing: AppTheme.spacingXs,
                                          children: [
                                            AppTypeChip(
                                              label: _endpointTypeLabel(
                                                group.endpointType,
                                                loc,
                                              ),
                                              color: _endpointTypeColor(
                                                group.endpointType,
                                              ),
                                            ),
                                            AppTypeChip(
                                              label: _modeLabel(
                                                group.mode,
                                                loc,
                                              ),
                                              color: _modeColor(group.mode),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  GestureDetector(
                                    onTap: isTesting
                                        ? null
                                        : () => _testGroup(group, loc),
                                    child: isTesting
                                        ? const CupertinoActivityIndicator(
                                            radius: 9,
                                          )
                                        : Icon(
                                            CupertinoIcons.play_circle,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  GestureDetector(
                                    onTap: isStartingAIRoute
                                        ? null
                                        : () =>
                                              _startAIRoute(loc, group: group),
                                    child: isStartingAIRoute
                                        ? const CupertinoActivityIndicator(
                                            radius: 9,
                                          )
                                        : Icon(
                                            Icons.auto_awesome,
                                            size: 20,
                                            color: colorScheme.primary,
                                          ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  GestureDetector(
                                    onTap: () =>
                                        _showGroupEditor(existing: group),
                                    child: Icon(
                                      CupertinoIcons.pencil,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  GestureDetector(
                                    onTap: () => _deleteGroup(group, loc),
                                    child: Icon(
                                      CupertinoIcons.delete,
                                      size: 20,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Wrap(
                                spacing: AppTheme.spacingSm,
                                runSpacing: AppTheme.spacingXs,
                                children: [
                                  AppInfoChip(
                                    icon: CupertinoIcons.layers,
                                    label:
                                        '${loc.t('group_items')}: ${group.items.length}',
                                  ),
                                  if (group.matchRegex.trim().isNotEmpty)
                                    AppInfoChip(
                                      icon: CupertinoIcons.search,
                                      label:
                                          '${loc.t('match_regex')}: ${group.matchRegex.trim()}',
                                    ),
                                  if (group.firstTokenTimeOut > 0)
                                    AppInfoChip(
                                      icon: CupertinoIcons.timer,
                                      label:
                                          '${group.firstTokenTimeOut}${loc.t('second')}',
                                    ),
                                  if (group.sessionKeepTime > 0)
                                    AppInfoChip(
                                      icon: CupertinoIcons.clock,
                                      label:
                                          '${group.sessionKeepTime}${loc.t('second')}',
                                    ),
                                ],
                              ),
                              if (group.items.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingMd),
                                _buildItemsSection(
                                  group,
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
            if (!_loading)
              Positioned(
                right: AppTheme.spacingLg,
                bottom: 24,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.getShadowMedium(colorScheme),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(28),
                    color: colorScheme.primary,
                    onPressed: () => _showGroupEditor(),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupEditorSheet extends StatefulWidget {
  final Group? existing;
  final List<LLMChannel> modelChannels;

  const _GroupEditorSheet({this.existing, required this.modelChannels});

  @override
  State<_GroupEditorSheet> createState() => _GroupEditorSheetState();
}

class _GroupEditorSheetState extends State<_GroupEditorSheet> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _matchRegexCtl;
  late final TextEditingController _timeoutCtl;
  late final TextEditingController _keepTimeCtl;
  late final TextEditingController _searchCtl;
  late final List<_GroupMemberDraft> _selectedMembers;
  late int _mode;
  late String _endpointType;
  String _regexError = '';

  bool get _showWeight => _mode == 4 || _mode == 5;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final channelMap = {
      for (final item in widget.modelChannels)
        _modelChannelKey(item.channelId, item.name): item,
    };

    _nameCtl = TextEditingController(text: existing?.name ?? '');
    _matchRegexCtl = TextEditingController(text: existing?.matchRegex ?? '');
    _timeoutCtl = TextEditingController(
      text: existing?.firstTokenTimeOut.toString() ?? '0',
    );
    _keepTimeCtl = TextEditingController(
      text: existing?.sessionKeepTime.toString() ?? '0',
    );
    _searchCtl = TextEditingController();
    _mode = existing?.mode ?? 5;
    _endpointType = normalizeGroupEndpointType(existing?.endpointType ?? '*');
    _selectedMembers =
        existing?.items
            .toList()
            .map(
              (item) => _GroupMemberDraft.fromGroupItem(
                item,
                channel:
                    channelMap[_modelChannelKey(
                      item.channelId,
                      item.modelName,
                    )],
              ),
            )
            .toList() ??
        [];
    _selectedMembers.sort((a, b) => a.priority.compareTo(b.priority));
    _regexError = _validateRegex(_matchRegexCtl.text.trim());
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _matchRegexCtl.dispose();
    _timeoutCtl.dispose();
    _keepTimeCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _addMember(LLMChannel channel) {
    final key = _modelChannelKey(channel.channelId, channel.name);
    final exists = _selectedMembers.any((item) => item.key == key);
    if (exists) return;

    setState(() {
      _selectedMembers.add(_GroupMemberDraft.fromChannel(channel));
    });
  }

  void _autoAddMembers() {
    final selectedKeys = {for (final item in _selectedMembers) item.key};
    final candidates = _matchingMembers.where(
      (item) =>
          !selectedKeys.contains(_modelChannelKey(item.channelId, item.name)),
    );

    setState(() {
      for (final item in candidates) {
        _selectedMembers.add(_GroupMemberDraft.fromChannel(item));
      }
    });
  }

  void _moveMember(int index, int delta) {
    final nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= _selectedMembers.length) return;
    setState(() {
      final item = _selectedMembers.removeAt(index);
      _selectedMembers.insert(nextIndex, item);
    });
  }

  void _changeWeight(int index, int delta) {
    final current = _selectedMembers[index];
    setState(() {
      _selectedMembers[index] = current.copyWith(
        weight: (current.weight + delta).clamp(1, 999),
      );
    });
  }

  String _validateRegex(String value) {
    if (value.isEmpty) return '';
    try {
      RegExp(value);
      return '';
    } catch (e) {
      return e.toString();
    }
  }

  Group _buildGroup() {
    return Group(
      id: widget.existing?.id ?? 0,
      name: _nameCtl.text.trim(),
      endpointType: _endpointType,
      mode: _mode,
      matchRegex: _matchRegexCtl.text.trim(),
      firstTokenTimeOut: int.tryParse(_timeoutCtl.text.trim()) ?? 0,
      sessionKeepTime: int.tryParse(_keepTimeCtl.text.trim()) ?? 0,
      createdTime: widget.existing?.createdTime ?? '',
      items: [
        for (var index = 0; index < _selectedMembers.length; index++)
          _selectedMembers[index].toGroupItem(priority: index + 1),
      ],
    );
  }

  void _save() {
    final group = _buildGroup();
    if (group.name.isEmpty || group.items.isEmpty || _regexError.isNotEmpty) {
      return;
    }
    Navigator.pop(context, group);
  }

  List<LLMChannel> get _availableMembers {
    final selectedKeys = {for (final item in _selectedMembers) item.key};
    final keyword = _searchCtl.text.trim().toLowerCase();

    return widget.modelChannels.where((item) {
      if (selectedKeys.contains(_modelChannelKey(item.channelId, item.name))) {
        return false;
      }
      if (keyword.isEmpty) return true;

      final channelName = _channelDisplayName(
        item.channelId,
        item.channelName,
      ).toLowerCase();
      return item.name.toLowerCase().contains(keyword) ||
          channelName.contains(keyword);
    }).toList();
  }

  List<LLMChannel> get _matchingMembers {
    if (_regexError.isNotEmpty) return const [];

    final regex = _matchRegexCtl.text.trim();
    if (regex.isNotEmpty) {
      final re = RegExp(regex);
      return widget.modelChannels
          .where((item) => re.hasMatch(item.name))
          .toList();
    }

    final groupName = _nameCtl.text.trim().toLowerCase();
    if (groupName.isEmpty) return const [];
    return widget.modelChannels
        .where((item) => item.name.toLowerCase().contains(groupName))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
    final endpointOptions = _endpointTypeOptions(loc);
    final matchingAddable = _matchingMembers.where((item) {
      final key = _modelChannelKey(item.channelId, item.name);
      return !_selectedMembers.any((member) => member.key == key);
    }).length;

    return AnimatedPadding(
      duration: AppTheme.animFast,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceLowest(colorScheme),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXXLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  AppTheme.spacingMd,
                  AppTheme.spacingLg,
                  AppTheme.spacingSm,
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.t('cancel')),
                    ),
                    Expanded(
                      child: Text(
                        isEdit ? loc.t('edit_group') : loc.t('create_group'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _save,
                      child: Text(loc.t('save')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    0,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                  ),
                  children: [
                    _SectionTitle(title: loc.t('overview')),
                    _SheetField(
                      controller: _nameCtl,
                      placeholder: loc.t('group_name'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _PickerField<String>(
                      label: loc.t('endpoint_type'),
                      value: _endpointType,
                      items: endpointOptions,
                      onChanged: (value) =>
                          setState(() => _endpointType = value),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _SheetField(
                      controller: _matchRegexCtl,
                      placeholder: loc.t('match_regex'),
                      onChanged: (value) => setState(
                        () => _regexError = _validateRegex(value.trim()),
                      ),
                    ),
                    if (_regexError.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        '${loc.t('regex_invalid')}: $_regexError',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetField(
                            controller: _timeoutCtl,
                            placeholder: loc.t('first_token_timeout'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: _SheetField(
                            controller: _keepTimeCtl,
                            placeholder: loc.t('session_keep'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(title: loc.t('mode')),
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingSm,
                      children: [
                        for (final entry in _groupModeOptions(loc).entries)
                          _ModeChip(
                            label: entry.value,
                            selected: _mode == entry.key,
                            color: _modeChipColor(entry.key),
                            onTap: () => setState(() => _mode = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(
                      title:
                          '${loc.t('selected_models')} (${_selectedMembers.length})',
                      actionLabel: _selectedMembers.isEmpty
                          ? null
                          : loc.t('clear_selection'),
                      onAction: _selectedMembers.isEmpty
                          ? null
                          : () => setState(() => _selectedMembers.clear()),
                    ),
                    if (_selectedMembers.isEmpty)
                      Text(
                        loc.t('empty'),
                        style: theme.textTheme.caption?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...List.generate(_selectedMembers.length, (index) {
                        final member = _selectedMembers[index];
                        return _SelectedGroupMemberCard(
                          index: index,
                          member: member,
                          showWeight: _showWeight,
                          canMoveUp: index > 0,
                          canMoveDown: index < _selectedMembers.length - 1,
                          onMoveUp: () => _moveMember(index, -1),
                          onMoveDown: () => _moveMember(index, 1),
                          onDecreaseWeight: () => _changeWeight(index, -1),
                          onIncreaseWeight: () => _changeWeight(index, 1),
                          onRemove: () =>
                              setState(() => _selectedMembers.removeAt(index)),
                        );
                      }),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed:
                                matchingAddable > 0 && _regexError.isEmpty
                                ? _autoAddMembers
                                : null,
                            child: Text(
                              '${loc.t('auto_add')} ($matchingAddable)',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: _SheetField(
                            controller: _searchCtl,
                            placeholder: loc.t('search_models'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(
                      title:
                          '${loc.t('available_models')} (${_availableMembers.length})',
                    ),
                    SizedBox(
                      height: 280,
                      child: _availableMembers.isEmpty
                          ? Center(
                              child: Text(
                                loc.t('no_matching_models'),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _availableMembers.length,
                              itemBuilder: (context, index) {
                                final item = _availableMembers[index];
                                return _AvailableModelCard(
                                  model: item,
                                  onTap: () => _addMember(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.footnote?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _SheetField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      onChanged: onChanged,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
    );
  }
}

class _PickerField<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  const _PickerField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
          child: Text(
            label,
            style: theme.textTheme.caption?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5.resolveFrom(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items.entries
                  .map(
                    (entry) => DropdownMenuItem<T>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (nextValue) {
                if (nextValue != null) onChanged(nextValue);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.getSurfaceLow(colorScheme),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
            color: selected
                ? color
                : colorScheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SelectedGroupMemberCard extends StatelessWidget {
  final int index;
  final _GroupMemberDraft member;
  final bool showWeight;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDecreaseWeight;
  final VoidCallback onIncreaseWeight;
  final VoidCallback onRemove;

  const _SelectedGroupMemberCard({
    required this.index,
    required this.member,
    required this.showWeight,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDecreaseWeight,
    required this.onIncreaseWeight,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (!member.enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Text(
                          context.read<AppProvider>().loc.t('disabled'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (showWeight) ...[
            const SizedBox(width: AppTheme.spacingSm),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniIconButton(
                    icon: CupertinoIcons.minus,
                    onTap: onDecreaseWeight,
                  ),
                  Text(
                    '${member.weight}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  _MiniIconButton(
                    icon: CupertinoIcons.add,
                    onTap: onIncreaseWeight,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: AppTheme.spacingSm),
          _MiniIconButton(
            icon: CupertinoIcons.chevron_up,
            onTap: canMoveUp ? onMoveUp : null,
          ),
          _MiniIconButton(
            icon: CupertinoIcons.chevron_down,
            onTap: canMoveDown ? onMoveDown : null,
          ),
          _MiniIconButton(
            icon: CupertinoIcons.delete,
            onTap: onRemove,
            color: colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _AvailableModelCard extends StatelessWidget {
  final LLMChannel model;
  final VoidCallback onTap;

  const _AvailableModelCard({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _channelDisplayName(model.channelId, model.channelName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Icon(
            CupertinoIcons.add_circled_solid,
            size: 22,
            color: model.enabled ? colorScheme.primary : colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _MiniIconButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = color ?? colorScheme.primary;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: const Size(28, 28),
      onPressed: onTap,
      child: Icon(
        icon,
        size: 16,
        color: onTap == null
            ? colorScheme.outline.withValues(alpha: 0.6)
            : foregroundColor,
      ),
    );
  }
}

class _GroupItemChip extends StatelessWidget {
  final int channelId;
  final String channelName;
  final String modelName;
  final bool enabled;
  final ColorScheme colorScheme;

  const _GroupItemChip({
    required this.channelId,
    required this.channelName,
    required this.modelName,
    required this.enabled,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? colorScheme.primary : colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: enabled ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$channelId',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            '$channelName · $modelName',
            style: TextStyle(
              fontSize: 12,
              color: enabled ? colorScheme.onSurfaceVariant : accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GroupMemberDraft {
  final int itemId;
  final int groupId;
  final int channelId;
  final String channelName;
  final String modelName;
  final int priority;
  final int weight;
  final bool enabled;

  const _GroupMemberDraft({
    this.itemId = 0,
    this.groupId = 0,
    required this.channelId,
    required this.channelName,
    required this.modelName,
    this.priority = 0,
    this.weight = 1,
    this.enabled = true,
  });

  String get key => _modelChannelKey(channelId, modelName);

  factory _GroupMemberDraft.fromChannel(LLMChannel channel) {
    return _GroupMemberDraft(
      channelId: channel.channelId,
      channelName: _channelDisplayName(channel.channelId, channel.channelName),
      modelName: channel.name,
      weight: 1,
      enabled: channel.enabled,
    );
  }

  factory _GroupMemberDraft.fromGroupItem(
    GroupItem item, {
    LLMChannel? channel,
  }) {
    return _GroupMemberDraft(
      itemId: item.id,
      groupId: item.groupId,
      channelId: item.channelId,
      channelName: _channelDisplayName(
        item.channelId,
        channel?.channelName ?? '',
      ),
      modelName: item.modelName,
      priority: item.priority,
      weight: item.weight > 0 ? item.weight : 1,
      enabled: channel?.enabled ?? false,
    );
  }

  _GroupMemberDraft copyWith({
    int? itemId,
    int? groupId,
    int? channelId,
    String? channelName,
    String? modelName,
    int? priority,
    int? weight,
    bool? enabled,
  }) {
    return _GroupMemberDraft(
      itemId: itemId ?? this.itemId,
      groupId: groupId ?? this.groupId,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      modelName: modelName ?? this.modelName,
      priority: priority ?? this.priority,
      weight: weight ?? this.weight,
      enabled: enabled ?? this.enabled,
    );
  }

  GroupItem toGroupItem({required int priority}) {
    return GroupItem(
      id: itemId,
      groupId: groupId,
      channelId: channelId,
      modelName: modelName,
      priority: priority,
      weight: weight > 0 ? weight : 1,
    );
  }
}

Map<int, String> _groupModeOptions(AppLocalizations loc) => {
  1: loc.t('mode_round_robin'),
  2: loc.t('mode_random'),
  3: loc.t('mode_failover'),
  4: loc.t('mode_weighted'),
  5: loc.t('mode_auto'),
};

Map<String, String> _endpointTypeOptions(AppLocalizations loc) => {
  '*': loc.t('endpoint_all'),
  'chat': loc.t('endpoint_chat'),
  'embeddings': loc.t('endpoint_embeddings'),
  'rerank': loc.t('endpoint_rerank'),
  'moderations': loc.t('endpoint_moderations'),
  'image_generation': loc.t('endpoint_image_generation'),
  'audio_speech': loc.t('endpoint_audio_speech'),
  'audio_transcription': loc.t('endpoint_audio_transcription'),
  'video_generation': loc.t('endpoint_video_generation'),
  'music_generation': loc.t('endpoint_music_generation'),
  'search': loc.t('endpoint_search'),
};

Color _modeChipColor(int mode) {
  switch (mode) {
    case 1:
      return AppTheme.colorBlue;
    case 2:
      return AppTheme.colorPurple;
    case 3:
      return AppTheme.colorOrange;
    case 4:
      return AppTheme.colorGreen;
    case 5:
      return AppTheme.colorTeal;
    default:
      return AppTheme.colorGray;
  }
}

String _modelChannelKey(int channelId, String modelName) =>
    '$channelId::$modelName';

String _channelDisplayName(int channelId, String channelName) {
  final trimmed = channelName.trim();
  return trimmed.isNotEmpty ? trimmed : 'Channel $channelId';
}
