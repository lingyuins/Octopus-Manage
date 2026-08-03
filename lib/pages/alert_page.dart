import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/alert.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:octopusmanage/widgets/app_list_tile.dart';
import 'package:provider/provider.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  int _tab = 0;

  List<AlertRule> _rules = [];
  List<AlertNotifChannel> _channels = [];
  List<AlertHistory> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      final results = await Future.wait([
        api.getAlertRules(),
        api.getNotifChannels(),
        api.getAlertHistory(),
      ]);
      if (mounted) {
        _rules = results[0] as List<AlertRule>;
        _channels = results[1] as List<AlertNotifChannel>;
        _history = results[2] as List<AlertHistory>;
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _channelName(int id, AppLocalizations loc) {
    final ch = _channels.where((c) => c.id == id).firstOrNull;
    return ch?.name ?? 'ID $id';
  }

  Future<void> _deleteRule(AlertRule rule, AppLocalizations loc) async {
    final ok = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete'),
      content: loc.t('delete_confirm', {'name': rule.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!ok || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteAlertRule(rule.id);
      _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _showRuleDialog({AlertRule? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final thresholdCtl = TextEditingController(
      text: existing?.threshold.toString() ?? '0',
    );
    final cooldownCtl = TextEditingController(
      text: existing?.cooldownSec.toString() ?? '300',
    );
    final conditionJsonCtl = TextEditingController(text: existing?.conditionJson ?? '');
    String conditionType = existing?.conditionType ?? 'error_rate';
    int notifChannelId = existing?.notifChannelId ?? 0;
    bool enabled = existing?.enabled ?? true;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState2) => CupertinoAlertDialog(
          title: Text(isEdit ? loc.t('edit_alert_rule') : loc.t('create_alert_rule')),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('alert_condition'), style: const TextStyle(fontSize: 14)),
                      CupertinoSlidingSegmentedControl<String>(
                        groupValue: conditionType,
                        onValueChanged: (v) => setState2(() => conditionType = v ?? conditionType),
                        children: const {
                          'error_rate': Text('Error%', style: TextStyle(fontSize: 12)),
                          'cost_threshold': Text('Cost', style: TextStyle(fontSize: 12)),
                          'quota_exceeded': Text('Quota', style: TextStyle(fontSize: 12)),
                          'channel_down': Text('Down', style: TextStyle(fontSize: 12)),
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: thresholdCtl,
                    placeholder: loc.t('alert_threshold'),
                    padding: const EdgeInsets.all(12),
                    keyboardType: TextInputType.number,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: cooldownCtl,
                    placeholder: loc.t('alert_cooldown'),
                    padding: const EdgeInsets.all(12),
                    keyboardType: TextInputType.number,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: conditionJsonCtl,
                    placeholder: loc.t('alert_condition_json'),
                    padding: const EdgeInsets.all(12),
                    maxLines: 2,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('alert_notif_channel'), style: const TextStyle(fontSize: 14)),
                      GestureDetector(
                        onTap: () async {
                          final ch = await _pickChannel(ctx);
                          if (ch != null) setState2(() => notifChannelId = ch);
                        },
                        child: Text(
                          _channelName(notifChannelId, loc),
                          style: TextStyle(color: CupertinoTheme.of(ctx).primaryColor, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('enabled')),
                      CupertinoSwitch(
                        value: enabled,
                        onChanged: (v) => setState2(() => enabled = v),
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

    final name = nameCtl.text.trim();
    final thresholdText = thresholdCtl.text;
    final cooldownText = cooldownCtl.text;
    final conditionJson = conditionJsonCtl.text.trim();
    nameCtl.dispose(); thresholdCtl.dispose(); cooldownCtl.dispose(); conditionJsonCtl.dispose();

    if (result != true || name.isEmpty || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      final rule = AlertRule(
        id: existing?.id ?? 0,
        name: name,
        enabled: enabled,
        conditionType: conditionType,
        threshold: double.tryParse(thresholdText) ?? 0,
        conditionJson: conditionJson,
        notifChannelId: notifChannelId,
        cooldownSec: int.tryParse(cooldownText) ?? 300,
      );
      if (isEdit) {
        await api.updateAlertRule(rule);
      } else {
        await api.createAlertRule(rule);
      }
      _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<int?> _pickChannel(BuildContext ctx) async {
    final picked = await showCupertinoModalPopup<int>(
      context: ctx,
      builder: (c) => CupertinoActionSheet(
        title: Text(context.read<AppProvider>().loc.t('alert_notif_channel')),
        actions: _channels.map((ch) => CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(c, ch.id),
          child: Text(ch.name),
        )).toList()..add(
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(c),
            child: Text(context.read<AppProvider>().loc.t('cancel')),
          ),
        ),
      ),
    );
    return picked;
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
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(loc.t('alerts')),
                  backgroundColor: AppTheme.getSurfaceLowest(colorScheme).withValues(alpha: 0.85),
                  border: null,
                ),
                CupertinoSliverRefreshControl(onRefresh: _load),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabHeaderDelegate(
                    child: Container(
                      color: AppTheme.getSurfaceLowest(colorScheme),
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                      child: CupertinoSegmentedControl<int>(
                        groupValue: _tab,
                        onValueChanged: (v) => setState(() => _tab = v),
                        children: {
                          0: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Text(loc.t('alert_rules'), style: const TextStyle(fontSize: 13)),
                          ),
                          1: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Text(loc.t('alert_channels'), style: const TextStyle(fontSize: 13)),
                          ),
                          2: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Text(loc.t('alert_history'), style: const TextStyle(fontSize: 13)),
                          ),
                        },
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(hasScrollBody: false, child: AppLoadingState())
                else ...[
                  if (_tab == 0) _buildRulesTab(loc, colorScheme),
                  if (_tab == 1) _buildChannelsTab(loc, colorScheme),
                  if (_tab == 2) _buildHistoryTab(loc, colorScheme),
                ],
              ],
            ),
            if (!_loading && _tab != 2)
              Positioned(
                right: AppTheme.spacingLg,
                bottom: 24,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(28),
                  color: colorScheme.primary,
                  onPressed: _tab == 0 ? () => _showRuleDialog() : () => _showChannelDialog(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16),
                      const Icon(CupertinoIcons.add, size: 22, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _tab == 0 ? loc.t('create_alert_rule') : loc.t('create_alert_channel'),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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

  Widget _buildRulesTab(AppLocalizations loc, ColorScheme cs) {
    if (_rules.isEmpty) {
      return SliverFillRemaining(
        child: AppEmptyState(
          icon: CupertinoIcons.bell,
          title: loc.t('no_alert_rules'),
          subtitle: loc.t('create_first_alert_rule'),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final rule = _rules[i];
          return AppListTile(
            margin: const EdgeInsets.fromLTRB(AppTheme.spacingLg, AppTheme.spacingSm, AppTheme.spacingLg, 0),
            leading: CupertinoSwitch(
              value: rule.enabled,
              onChanged: (_) async {
                try {
                  await context.read<AppProvider>().api.updateAlertRule(
                    AlertRule(id: rule.id, name: rule.name, enabled: !rule.enabled,
                      conditionType: rule.conditionType, threshold: rule.threshold,
                      conditionJson: rule.conditionJson, notifChannelId: rule.notifChannelId,
                      cooldownSec: rule.cooldownSec),
                  );
                  _load();
                } catch (e) {
                  if (mounted) showErrorDialog(context, e.toString());
                }
              },
            ),
            title: Text(rule.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Row(children: [
              AppInfoChip(icon: CupertinoIcons.tag, label: rule.conditionType),
              const SizedBox(width: 4),
              AppInfoChip(icon: CupertinoIcons.bell, label: _channelName(rule.notifChannelId, loc)),
            ]),
            trailing: GestureDetector(
              onTap: () => _deleteRule(rule, loc),
              child: Icon(CupertinoIcons.delete, size: 20, color: cs.error),
            ),
          );
        }, childCount: _rules.length),
      ),
    );
  }

  Widget _buildChannelsTab(AppLocalizations loc, ColorScheme cs) {
    if (_channels.isEmpty) {
      return SliverFillRemaining(
        child: AppEmptyState(
          icon: CupertinoIcons.bell_slash,
          title: loc.t('no_alert_channels'),
          subtitle: loc.t('create_first_alert_channel'),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final ch = _channels[i];
          return AppListTile(
            margin: const EdgeInsets.fromLTRB(AppTheme.spacingLg, AppTheme.spacingSm, AppTheme.spacingLg, 0),
            title: Text(ch.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Text(ch.url.isNotEmpty ? ch.url : ch.type,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            onTap: () => _showChannelDialog(existing: ch),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showChannelDialog(existing: ch),
                  child: Icon(CupertinoIcons.pencil, size: 20, color: cs.primary),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                GestureDetector(
                  onTap: () async {
                    final ok = await AppConfirmDialog.show(
                      context: context,
                      title: loc.t('delete'),
                      content: loc.t('delete_confirm', {'name': ch.name}),
                      confirmText: loc.t('delete'), cancelText: loc.t('cancel'), isDanger: true,
                    );
                    if (!ok || !mounted) return;
                    try {
                      final api = context.read<AppProvider>().api;
                      await api.deleteNotifChannel(ch.id);
                      _load();
                    } catch (e) {
                      if (mounted) showErrorDialog(context, e.toString());
                    }
                  },
                  child: Icon(CupertinoIcons.delete, size: 20, color: cs.error),
                ),
              ],
            ),
          );
        }, childCount: _channels.length),
      ),
    );
  }

  Future<void> _showChannelDialog({AlertNotifChannel? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final urlCtl = TextEditingController(text: existing?.url ?? '');
    String type = existing?.type ?? 'webhook';

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState2) => CupertinoAlertDialog(
          title: Text(isEdit ? loc.t('edit_alert_channel') : loc.t('create_alert_channel')),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.t('channel_type'), style: const TextStyle(fontSize: 14)),
                      CupertinoSlidingSegmentedControl<String>(
                        groupValue: type,
                        onValueChanged: (v) => setState2(() => type = v ?? type),
                        children: const {
                          'webhook': Text('Webhook', style: TextStyle(fontSize: 12)),
                          'gotify': Text('Gotify', style: TextStyle(fontSize: 12)),
                          'email': Text('Email', style: TextStyle(fontSize: 12)),
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: urlCtl,
                    placeholder: loc.t('base_url'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
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

    final name = nameCtl.text.trim();
    final url = urlCtl.text.trim();
    nameCtl.dispose(); urlCtl.dispose();

    if (result != true || name.isEmpty || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      final ch = AlertNotifChannel(
        id: existing?.id ?? 0,
        name: name,
        type: type,
        url: url,
      );
      if (isEdit) {
        await api.updateNotifChannel(ch);
      } else {
        await api.createNotifChannel(ch);
      }
      _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Widget _buildHistoryTab(AppLocalizations loc, ColorScheme cs) {
    if (_history.isEmpty) {
      return SliverFillRemaining(
        child: AppEmptyState(icon: CupertinoIcons.clock, title: loc.t('no_alert_history')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final h = _history[i];
          final dt = DateTime.fromMillisecondsSinceEpoch(h.time * 1000);
          final stateLabel = h.state == 0 ? 'OK' : h.state == 1 ? 'FIRING' : 'RESOLVED';
          return AppListTile(
            margin: const EdgeInsets.fromLTRB(AppTheme.spacingLg, AppTheme.spacingSm, AppTheme.spacingLg, 0),
            title: Text(h.ruleName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.message, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant), maxLines: 2),
              Text('${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
            ]),
            trailing: AppInfoChip(
              icon: h.state == 0 ? CupertinoIcons.checkmark : h.state == 1 ? CupertinoIcons.flame : CupertinoIcons.arrow_uturn_down,
              label: stateLabel,
            ),
          );
        }, childCount: _history.length),
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TabHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 52;

  @override
  double get minExtent => 52;

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) => child != oldDelegate.child;
}
