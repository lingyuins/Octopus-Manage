import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/channel_probe.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class ChannelPage extends StatefulWidget {
  const ChannelPage({super.key});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  List<Channel> _channels = [];
  bool _loading = true;
  bool _syncing = false;

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
      _channels.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleEnabled(Channel channel) async {
    try {
      final api = context.read<AppProvider>().api;
      await api.enableChannel(channel.id, !channel.enabled);
      await _loadChannels();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _syncChannels(AppLocalizations loc) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.syncChannels();
      await _loadChannels();
      if (mounted) {
        await AppTextDialog.show(
          context: context,
          title: loc.t('sync_channels'),
          content: loc.t('channel_sync_success'),
          buttonText: loc.t('ok'),
          selectable: false,
        );
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          e.toString(),
          title: loc.t('channel_sync_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _deleteChannel(Channel channel, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete_channel'),
      content: loc.t('delete_confirm', {'name': channel.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteChannel(channel.id);
      await _loadChannels();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _showChannelEditor({Channel? existing}) async {
    final channel = await showModalBottomSheet<Channel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChannelEditorSheet(existing: existing),
    );
    if (channel == null || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      if (existing == null) {
        await api.createChannel(channel);
      } else {
        await api.updateChannel(channel);
      }
      await _loadChannels();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  String _channelTypeName(int type, AppLocalizations loc) {
    switch (type) {
      case 0:
        return loc.t('type_openai_chat');
      case 1:
        return loc.t('type_openai_response');
      case 2:
        return loc.t('type_anthropic');
      case 3:
        return loc.t('type_gemini');
      case 4:
        return loc.t('type_volcengine');
      case 5:
        return loc.t('type_openai_embedding');
      case 6:
        return 'Type 6';
      default:
        return 'Type $type';
    }
  }

  Color _channelTypeColor(int type) {
    switch (type) {
      case 0:
        return AppTheme.colorBlue;
      case 1:
        return AppTheme.colorTeal;
      case 2:
        return AppTheme.colorIndigo;
      case 3:
        return AppTheme.colorOrange;
      case 4:
        return AppTheme.colorRed;
      case 5:
        return AppTheme.colorGreen;
      case 6:
        return AppTheme.colorGray;
      default:
        return AppTheme.colorGray;
    }
  }

  List<String> _splitModels(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
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
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(loc.t('channels')),
                  backgroundColor: AppTheme.getSurfaceLowest(
                    colorScheme,
                  ).withValues(alpha: 0.85),
                  border: null,
                  trailing: GestureDetector(
                    onTap: _syncing ? null : () => _syncChannels(loc),
                    child: _syncing
                        ? const CupertinoActivityIndicator(radius: 10)
                        : Icon(
                            CupertinoIcons.refresh,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                  ),
                ),
                CupertinoSliverRefreshControl(onRefresh: _loadChannels),
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
                        onPressed: () => _showChannelEditor(),
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
                        final channel = _channels[index];
                        final autoModels = _splitModels(channel.model);
                        final customModels = _splitModels(channel.customModel);
                        final baseUrlPreview = channel.baseUrls.isNotEmpty
                            ? channel.baseUrls.first.url
                            : loc.t('empty');
                        return AppCard(
                          margin: const EdgeInsets.fromLTRB(
                            AppTheme.spacingLg,
                            AppTheme.spacingSm,
                            AppTheme.spacingLg,
                            0,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CupertinoSwitch(
                                    value: channel.enabled,
                                    onChanged: (_) => _toggleEnabled(channel),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                channel.name,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            AppTypeChip(
                                              label: _channelTypeName(
                                                channel.type,
                                                loc,
                                              ),
                                              color: _channelTypeColor(
                                                channel.type,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: AppTheme.spacingXs,
                                        ),
                                        Text(
                                          baseUrlPreview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.caption
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  GestureDetector(
                                    onTap: () =>
                                        _showChannelEditor(existing: channel),
                                    child: Icon(
                                      CupertinoIcons.pencil,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  GestureDetector(
                                    onTap: () => _deleteChannel(channel, loc),
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
                                    icon: CupertinoIcons.link,
                                    label:
                                        '${loc.t('base_urls')}: ${channel.baseUrls.length}',
                                  ),
                                  AppInfoChip(
                                    icon: CupertinoIcons.tag,
                                    label:
                                        '${loc.t('keys')}: ${channel.keys.where((item) => item.enabled).length}/${channel.keys.length}',
                                  ),
                                  AppInfoChip(
                                    icon: CupertinoIcons.cube_box,
                                    label:
                                        '${loc.t('models')}: ${autoModels.length + customModels.length}',
                                  ),
                                  if (channel.autoSync)
                                    AppTypeChip(
                                      label: loc.t('auto_sync'),
                                      color: AppTheme.colorGreen,
                                    ),
                                  if (channel.proxy)
                                    AppTypeChip(
                                      label: loc.t('proxy'),
                                      color: AppTheme.colorPurple,
                                    ),
                                ],
                              ),
                              if (channel.stats != null) ...[
                                const SizedBox(height: AppTheme.spacingMd),
                                Wrap(
                                  spacing: AppTheme.spacingSm,
                                  runSpacing: AppTheme.spacingXs,
                                  children: [
                                    AppInfoChip(
                                      icon: CupertinoIcons.checkmark_circle,
                                      label: '${channel.stats!.requestSuccess}',
                                      color: AppTheme.colorGreen,
                                    ),
                                    AppInfoChip(
                                      icon: CupertinoIcons.xmark_circle,
                                      label: '${channel.stats!.requestFailed}',
                                      color: colorScheme.error,
                                    ),
                                    AppInfoChip(
                                      icon: CupertinoIcons.clock,
                                      label: '${channel.stats!.waitTime}ms',
                                    ),
                                  ],
                                ),
                              ],
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.getShadowMedium(colorScheme),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(28),
                    color: colorScheme.primary,
                    onPressed: () => _showChannelEditor(),
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

class _ChannelEditorSheet extends StatefulWidget {
  final Channel? existing;

  const _ChannelEditorSheet({this.existing});

  @override
  State<_ChannelEditorSheet> createState() => _ChannelEditorSheetState();
}

class _ChannelEditorSheetState extends State<_ChannelEditorSheet> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _modelCtl;
  late final TextEditingController _customModelCtl;
  late final TextEditingController _channelProxyCtl;
  late final TextEditingController _matchRegexCtl;
  late final TextEditingController _paramOverrideCtl;
  late List<BaseUrl> _baseUrls;
  late List<ChannelKey> _keys;
  late List<CustomHeader> _headers;
  late int _selectedType;
  late int _autoGroup;
  late bool _enabled;
  late bool _proxy;
  late bool _autoSync;
  bool _testing = false;
  bool _fetchingModels = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtl = TextEditingController(text: existing?.name ?? '');
    _modelCtl = TextEditingController(text: existing?.model ?? '');
    _customModelCtl = TextEditingController(text: existing?.customModel ?? '');
    _channelProxyCtl = TextEditingController(
      text: existing?.channelProxy ?? '',
    );
    _matchRegexCtl = TextEditingController(text: existing?.matchRegex ?? '');
    _paramOverrideCtl = TextEditingController(
      text: existing?.paramOverride ?? '',
    );
    _baseUrls = existing?.baseUrls.isNotEmpty == true
        ? existing!.baseUrls
              .map((item) => BaseUrl(url: item.url, delay: item.delay))
              .toList()
        : [BaseUrl(url: '', delay: 0)];
    _keys = existing?.keys.isNotEmpty == true
        ? existing!.keys
              .map(
                (item) => ChannelKey(
                  id: item.id,
                  channelId: item.channelId,
                  enabled: item.enabled,
                  channelKey: item.channelKey,
                  statusCode: item.statusCode,
                  lastUseTimeStamp: item.lastUseTimeStamp,
                  totalCost: item.totalCost,
                  remark: item.remark,
                ),
              )
              .toList()
        : [ChannelKey(id: 0, enabled: true, channelKey: '', remark: '')];
    _headers = existing?.customHeader.isNotEmpty == true
        ? existing!.customHeader
              .map(
                (item) => CustomHeader(
                  headerKey: item.headerKey,
                  headerValue: item.headerValue,
                ),
              )
              .toList()
        : [];
    _selectedType = existing?.type ?? 0;
    _autoGroup = existing?.autoGroup ?? 0;
    _enabled = existing?.enabled ?? true;
    _proxy = existing?.proxy ?? false;
    _autoSync = existing?.autoSync ?? false;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _modelCtl.dispose();
    _customModelCtl.dispose();
    _channelProxyCtl.dispose();
    _matchRegexCtl.dispose();
    _paramOverrideCtl.dispose();
    super.dispose();
  }

  Channel _buildChannel() {
    return Channel(
      id: widget.existing?.id ?? 0,
      name: _nameCtl.text.trim(),
      type: _selectedType,
      enabled: _enabled,
      baseUrls: _baseUrls
          .where((item) => item.url.trim().isNotEmpty)
          .map((item) => BaseUrl(url: item.url.trim(), delay: item.delay))
          .toList(),
      keys: _keys
          .where((item) => item.channelKey.trim().isNotEmpty)
          .map(
            (item) => ChannelKey(
              id: item.id,
              channelId: widget.existing?.id ?? 0,
              enabled: item.enabled,
              channelKey: item.channelKey.trim(),
              statusCode: item.statusCode,
              lastUseTimeStamp: item.lastUseTimeStamp,
              totalCost: item.totalCost,
              remark: item.remark.trim(),
            ),
          )
          .toList(),
      model: _modelCtl.text.trim(),
      customModel: _customModelCtl.text.trim(),
      proxy: _proxy,
      autoSync: _autoSync,
      autoGroup: _autoGroup,
      customHeader: _headers
          .where(
            (item) =>
                item.headerKey.trim().isNotEmpty ||
                item.headerValue.trim().isNotEmpty,
          )
          .map(
            (item) => CustomHeader(
              headerKey: item.headerKey.trim(),
              headerValue: item.headerValue.trim(),
            ),
          )
          .toList(),
      paramOverride: _paramOverrideCtl.text.trim().isEmpty
          ? null
          : _paramOverrideCtl.text.trim(),
      channelProxy: _channelProxyCtl.text.trim().isEmpty
          ? null
          : _channelProxyCtl.text.trim(),
      matchRegex: _matchRegexCtl.text.trim().isEmpty
          ? null
          : _matchRegexCtl.text.trim(),
    );
  }

  Future<void> _fetchModels(AppLocalizations loc) async {
    if (_fetchingModels) return;
    setState(() => _fetchingModels = true);
    try {
      final api = context.read<AppProvider>().api;
      final models = await api.fetchModels(_buildChannel());
      if (!mounted) return;
      if (models.isEmpty) {
        await AppTextDialog.show(
          context: context,
          title: loc.t('fetch_models'),
          content: loc.t('fetch_models_empty'),
          buttonText: loc.t('ok'),
          selectable: false,
        );
      } else {
        _modelCtl.text = models.join(', ');
        await AppTextDialog.show(
          context: context,
          title: loc.t('fetch_models'),
          content: '${loc.t('fetch_models_success')}\n\n${models.join('\n')}',
          buttonText: loc.t('ok'),
        );
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          e.toString(),
          title: loc.t('fetch_models_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  Future<void> _testChannel(AppLocalizations loc) async {
    if (_testing) return;
    setState(() => _testing = true);
    try {
      final api = context.read<AppProvider>().api;
      final summary = await api.testChannel(_buildChannel());
      if (!mounted) return;
      final content = _formatTestSummary(summary, loc);
      await AppTextDialog.show(
        context: context,
        title: loc.t('test_channel'),
        content: content,
        buttonText: loc.t('ok'),
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          e.toString(),
          title: loc.t('test_channel_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  String _formatTestSummary(ChannelTestSummary summary, AppLocalizations loc) {
    if (summary.results.isEmpty) return loc.t('no_data');

    final buffer = StringBuffer();
    buffer.writeln(
      summary.passed
          ? loc.t('test_channel_passed')
          : loc.t('test_channel_failed'),
    );
    buffer.writeln();
    for (final result in summary.results) {
      buffer.writeln('${result.passed ? 'PASS' : 'FAIL'}  ${result.baseUrl}');
      if (result.keyRemark.isNotEmpty) {
        buffer.writeln('${loc.t('remark')}: ${result.keyRemark}');
      }
      if (result.keyMasked.isNotEmpty) {
        buffer.writeln('${loc.t('api_key')}: ${result.keyMasked}');
      }
      buffer.writeln('HTTP ${result.statusCode}  ${result.latencyMs}ms');
      if (result.message.isNotEmpty) {
        buffer.writeln(result.message);
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  void _save() {
    final nextChannel = _buildChannel();
    if (nextChannel.name.isEmpty) return;
    Navigator.pop(context, nextChannel);
  }

  void _updateBaseUrl(int index, BaseUrl value) {
    setState(() => _baseUrls[index] = value);
  }

  void _updateKey(int index, ChannelKey value) {
    setState(() => _keys[index] = value);
  }

  void _updateHeader(int index, CustomHeader value) {
    setState(() => _headers[index] = value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return AnimatedPadding(
      duration: AppTheme.animFast,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                        isEdit
                            ? loc.t('edit_channel')
                            : loc.t('create_channel'),
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
                      placeholder: loc.t('channel_name'),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _PickerField<int>(
                      label: loc.t('channel_type'),
                      value: _selectedType,
                      items: {
                        0: loc.t('type_openai_chat'),
                        1: loc.t('type_openai_response'),
                        2: loc.t('type_anthropic'),
                        3: loc.t('type_gemini'),
                        4: loc.t('type_volcengine'),
                        5: loc.t('type_openai_embedding'),
                      },
                      onChanged: (value) =>
                          setState(() => _selectedType = value),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _PickerField<int>(
                      label: loc.t('auto_group'),
                      value: _autoGroup,
                      items: {
                        0: loc.t('auto_group_none'),
                        1: loc.t('auto_group_fuzzy'),
                        2: loc.t('auto_group_exact'),
                        3: loc.t('auto_group_regex'),
                      },
                      onChanged: (value) => setState(() => _autoGroup = value),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _SwitchRow(
                      title: loc.t('enabled'),
                      value: _enabled,
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                    _SwitchRow(
                      title: loc.t('proxy'),
                      value: _proxy,
                      onChanged: (value) => setState(() => _proxy = value),
                    ),
                    _SwitchRow(
                      title: loc.t('auto_sync'),
                      value: _autoSync,
                      onChanged: (value) => setState(() => _autoSync = value),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(
                      title: loc.t('base_urls'),
                      actionLabel: loc.t('add'),
                      onAction: () => setState(
                        () => _baseUrls.add(BaseUrl(url: '', delay: 0)),
                      ),
                    ),
                    ...List.generate(_baseUrls.length, (index) {
                      final item = _baseUrls[index];
                      return _BaseUrlEditor(
                        key: ValueKey('base-url-$index'),
                        index: index,
                        value: item,
                        onChanged: (value) => _updateBaseUrl(index, value),
                        onRemove: _baseUrls.length > 1
                            ? () => setState(() => _baseUrls.removeAt(index))
                            : null,
                      );
                    }),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(
                      title: loc.t('keys'),
                      actionLabel: loc.t('add'),
                      onAction: () => setState(
                        () => _keys.add(
                          ChannelKey(
                            id: 0,
                            enabled: true,
                            channelKey: '',
                            remark: '',
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(_keys.length, (index) {
                      final item = _keys[index];
                      return _KeyEditor(
                        key: ValueKey('channel-key-$index'),
                        index: index,
                        value: item,
                        onChanged: (value) => _updateKey(index, value),
                        onRemove: _keys.length > 1
                            ? () => setState(() => _keys.removeAt(index))
                            : null,
                      );
                    }),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(title: loc.t('models')),
                    _SheetField(
                      controller: _modelCtl,
                      placeholder: loc.t('model'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _SheetField(
                      controller: _customModelCtl,
                      placeholder: loc.t('custom_model'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: _fetchingModels
                                ? null
                                : () => _fetchModels(loc),
                            child: _fetchingModels
                                ? const CupertinoActivityIndicator()
                                : Text(loc.t('fetch_models')),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: colorScheme.secondaryContainer,
                            onPressed: _testing
                                ? null
                                : () => _testChannel(loc),
                            child: _testing
                                ? const CupertinoActivityIndicator()
                                : Text(
                                    loc.t('test_channel'),
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(title: loc.t('advanced_settings')),
                    _SheetField(
                      controller: _channelProxyCtl,
                      placeholder: loc.t('channel_proxy'),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _SheetField(
                      controller: _matchRegexCtl,
                      placeholder: loc.t('match_regex'),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _SheetField(
                      controller: _paramOverrideCtl,
                      placeholder: loc.t('param_override'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _SectionTitle(
                      title: loc.t('custom_headers'),
                      actionLabel: loc.t('add'),
                      onAction: () => setState(
                        () => _headers.add(
                          CustomHeader(headerKey: '', headerValue: ''),
                        ),
                      ),
                    ),
                    if (_headers.isEmpty)
                      Text(
                        loc.t('empty'),
                        style: theme.textTheme.caption?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ...List.generate(_headers.length, (index) {
                      final item = _headers[index];
                      return _HeaderEditor(
                        key: ValueKey('header-$index'),
                        index: index,
                        value: item,
                        onChanged: (value) => _updateHeader(index, value),
                        onRemove: () =>
                            setState(() => _headers.removeAt(index)),
                      );
                    }),
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
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _SheetField({
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
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

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;

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
              icon: Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onSurfaceVariant,
              ),
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

class _BaseUrlEditor extends StatefulWidget {
  final int index;
  final BaseUrl value;
  final ValueChanged<BaseUrl> onChanged;
  final VoidCallback? onRemove;

  const _BaseUrlEditor({
    super.key,
    required this.index,
    required this.value,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_BaseUrlEditor> createState() => _BaseUrlEditorState();
}

class _BaseUrlEditorState extends State<_BaseUrlEditor> {
  late final TextEditingController _urlCtl;
  late final TextEditingController _delayCtl;

  @override
  void initState() {
    super.initState();
    _urlCtl = TextEditingController(text: widget.value.url);
    _delayCtl = TextEditingController(text: widget.value.delay.toString());
  }

  @override
  void didUpdateWidget(covariant _BaseUrlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.url != widget.value.url) {
      _syncEditorController(_urlCtl, widget.value.url);
    }
    if (oldWidget.value.delay != widget.value.delay) {
      _syncEditorController(_delayCtl, widget.value.delay.toString());
    }
  }

  @override
  void dispose() {
    _urlCtl.dispose();
    _delayCtl.dispose();
    super.dispose();
  }

  void _emit({String? url, String? delay}) {
    widget.onChanged(
      BaseUrl(
        url: url ?? _urlCtl.text,
        delay: int.tryParse((delay ?? _delayCtl.text).trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SheetField(
              controller: _urlCtl,
              placeholder: 'URL ${widget.index + 1}',
              onChanged: (next) => _emit(url: next),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          SizedBox(
            width: 90,
            child: _SheetField(
              controller: _delayCtl,
              placeholder: 'Delay',
              keyboardType: TextInputType.number,
              onChanged: (next) => _emit(delay: next),
            ),
          ),
          if (widget.onRemove != null) ...[
            const SizedBox(width: AppTheme.spacingSm),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: widget.onRemove,
              child: const Icon(
                CupertinoIcons.minus_circle,
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KeyEditor extends StatefulWidget {
  final int index;
  final ChannelKey value;
  final ValueChanged<ChannelKey> onChanged;
  final VoidCallback? onRemove;

  const _KeyEditor({
    super.key,
    required this.index,
    required this.value,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_KeyEditor> createState() => _KeyEditorState();
}

class _KeyEditorState extends State<_KeyEditor> {
  late final TextEditingController _keyCtl;
  late final TextEditingController _remarkCtl;

  @override
  void initState() {
    super.initState();
    _keyCtl = TextEditingController(text: widget.value.channelKey);
    _remarkCtl = TextEditingController(text: widget.value.remark);
  }

  @override
  void didUpdateWidget(covariant _KeyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.channelKey != widget.value.channelKey) {
      _syncEditorController(_keyCtl, widget.value.channelKey);
    }
    if (oldWidget.value.remark != widget.value.remark) {
      _syncEditorController(_remarkCtl, widget.value.remark);
    }
  }

  @override
  void dispose() {
    _keyCtl.dispose();
    _remarkCtl.dispose();
    super.dispose();
  }

  void _emit({bool? enabled, String? channelKey, String? remark}) {
    widget.onChanged(
      ChannelKey(
        id: widget.value.id,
        channelId: widget.value.channelId,
        enabled: enabled ?? widget.value.enabled,
        channelKey: channelKey ?? _keyCtl.text,
        statusCode: widget.value.statusCode,
        lastUseTimeStamp: widget.value.lastUseTimeStamp,
        totalCost: widget.value.totalCost,
        remark: remark ?? _remarkCtl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Key ${widget.index + 1}')),
              CupertinoSwitch(
                value: widget.value.enabled,
                onChanged: (next) => _emit(enabled: next),
              ),
              if (widget.onRemove != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: widget.onRemove,
                  child: const Icon(
                    CupertinoIcons.minus_circle,
                    color: CupertinoColors.systemRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SheetField(
            controller: _keyCtl,
            placeholder: 'sk-...',
            onChanged: (next) => _emit(channelKey: next),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SheetField(
            controller: _remarkCtl,
            placeholder: 'Remark',
            onChanged: (next) => _emit(remark: next),
          ),
        ],
      ),
    );
  }
}

class _HeaderEditor extends StatefulWidget {
  final int index;
  final CustomHeader value;
  final ValueChanged<CustomHeader> onChanged;
  final VoidCallback onRemove;

  const _HeaderEditor({
    super.key,
    required this.index,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_HeaderEditor> createState() => _HeaderEditorState();
}

class _HeaderEditorState extends State<_HeaderEditor> {
  late final TextEditingController _keyCtl;
  late final TextEditingController _valueCtl;

  @override
  void initState() {
    super.initState();
    _keyCtl = TextEditingController(text: widget.value.headerKey);
    _valueCtl = TextEditingController(text: widget.value.headerValue);
  }

  @override
  void didUpdateWidget(covariant _HeaderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.headerKey != widget.value.headerKey) {
      _syncEditorController(_keyCtl, widget.value.headerKey);
    }
    if (oldWidget.value.headerValue != widget.value.headerValue) {
      _syncEditorController(_valueCtl, widget.value.headerValue);
    }
  }

  @override
  void dispose() {
    _keyCtl.dispose();
    _valueCtl.dispose();
    super.dispose();
  }

  void _emit({String? headerKey, String? headerValue}) {
    widget.onChanged(
      CustomHeader(
        headerKey: headerKey ?? _keyCtl.text,
        headerValue: headerValue ?? _valueCtl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Header ${widget.index + 1}')),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: widget.onRemove,
                child: const Icon(
                  CupertinoIcons.minus_circle,
                  color: CupertinoColors.systemRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SheetField(
            controller: _keyCtl,
            placeholder: 'Header-Key',
            onChanged: (next) => _emit(headerKey: next),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SheetField(
            controller: _valueCtl,
            placeholder: 'Header-Value',
            onChanged: (next) => _emit(headerValue: next),
          ),
        ],
      ),
    );
  }
}

void _syncEditorController(TextEditingController controller, String text) {
  if (controller.text == text) return;
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}
