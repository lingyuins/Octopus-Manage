import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/ai_route.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:provider/provider.dart';

class AIRouteProgressSheet extends StatefulWidget {
  final AIRouteProgress initialProgress;
  final VoidCallback? onCompleted;

  const AIRouteProgressSheet({
    super.key,
    required this.initialProgress,
    this.onCompleted,
  });

  @override
  State<AIRouteProgressSheet> createState() => _AIRouteProgressSheetState();
}

class _AIRouteProgressSheetState extends State<AIRouteProgressSheet> {
  late AIRouteProgress _progress;
  Timer? _timer;
  bool _refreshing = false;
  bool _completionHandled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress;
    _maybeHandleCompletion();
    _startPollingIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPollingIfNeeded() {
    _timer?.cancel();
    if (_progress.isTerminal) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      final api = context.read<AppProvider>().api;
      final next = await api.getAIRouteProgress(_progress.id);
      if (!mounted) return;
      setState(() {
        _progress = next;
        _error = null;
      });
      _maybeHandleCompletion();
      if (next.isTerminal) {
        _timer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      _refreshing = false;
    }
  }

  void _maybeHandleCompletion() {
    if (_completionHandled || !_progress.isCompletedWithResult) return;
    _completionHandled = true;
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceLowest(colorScheme),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXLarge),
            ),
          ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('ai_route_progress_title'),
                            style: theme.textTheme.heading?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _scopeLabel(_progress.scope, loc),
                            style: theme.textTheme.caption?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingLg,
                        AppTheme.spacingSm,
                        AppTheme.spacingLg,
                        AppTheme.spacingLg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          _buildOverviewCard(loc, colorScheme, theme),
                          if (_progress.summary != null) ...[
                            const SizedBox(height: AppTheme.spacingLg),
                            _buildSummaryCard(loc, colorScheme, theme),
                          ],
                          if (_batchCards.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingLg),
                            ..._buildBatchCards(loc, colorScheme, theme),
                          ],
                          if (_progress.channels.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingLg),
                            _buildChannelsCard(loc, colorScheme, theme),
                          ],
                          if (_progress.result != null) ...[
                            const SizedBox(height: AppTheme.spacingLg),
                            _buildResultCard(loc, colorScheme, theme),
                          ],
                          if (_error != null && _error!.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingLg),
                            _buildErrorCard(colorScheme, theme),
                          ],
                        ]),
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

  List<AIRouteBatchProgress> get _batchCards {
    final items = <AIRouteBatchProgress>[];
    for (final batch in _progress.runningBatches) {
      items.add(batch);
    }
    final current = _progress.currentBatch;
    if (current != null &&
        !items.any(
          (batch) =>
              batch.index == current.index &&
              batch.status == current.status &&
              batch.attempt == current.attempt,
        )) {
      items.add(current);
    }
    return items;
  }

  Widget _buildOverviewCard(
    AppLocalizations loc,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final statusColor = _statusColor(_progress.status);
    final stepLabel = _stepLabel(_progress.currentStep, loc);
    final statusLabel = _statusLabel(_progress.status, loc);
    final message = _progress.errorReason.isNotEmpty
        ? _progress.errorReason
        : (_progress.message.isNotEmpty ? _progress.message : stepLabel);

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: [
                    _Pill(label: statusLabel, color: statusColor),
                    _Pill(label: stepLabel, color: colorScheme.primary),
                  ],
                ),
              ),
              if (_refreshing) const CupertinoActivityIndicator(radius: 10),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.body?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                '${_progress.progressPercent}%',
                style: theme.textTheme.heading?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (_progress.progressPercent.clamp(0, 100)) / 100,
              backgroundColor: colorScheme.outlineVariant.withValues(
                alpha: 0.18,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingSm,
            children: [
              _MetaLine(
                title: loc.t('started_at'),
                value: _formatDateTime(_progress.startedAt, loc),
              ),
              _MetaLine(
                title: loc.t('updated_at'),
                value: _formatDateTime(_progress.updatedAt, loc),
              ),
              _MetaLine(
                title: loc.t('heartbeat_at'),
                value: _formatDateTime(_progress.heartbeatAt, loc),
              ),
              if (_progress.totalBatches > 0)
                _MetaLine(
                  title: loc.t('batches'),
                  value:
                      '${_progress.completedBatches}/${_progress.totalBatches}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    AppLocalizations loc,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final summary = _progress.summary!;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('overview'),
            style: theme.textTheme.footnote?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingMd,
            children: [
              _MetricCard(
                title: loc.t('channels'),
                value: '${summary.completedChannels}/${summary.totalChannels}',
                color: AppTheme.colorBlue,
              ),
              _MetricCard(
                title: loc.t('models'),
                value: '${summary.completedModels}/${summary.totalModels}',
                color: AppTheme.colorGreen,
              ),
              _MetricCard(
                title: loc.t('running'),
                value: '${summary.runningChannels}',
                color: AppTheme.colorPurple,
              ),
              _MetricCard(
                title: loc.t('failed'),
                value: '${summary.failedChannels}',
                color: AppTheme.colorRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBatchCards(
    AppLocalizations loc,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return [
      Text(
        loc.t('ai_route_current_batch'),
        style: theme.textTheme.footnote?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: AppTheme.spacingSm),
      ..._batchCards.map(
        (batch) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${batch.index}/${batch.total} · ${_batchTitle(batch, loc)}',
                        style: theme.textTheme.body?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (batch.status.isNotEmpty)
                      _Pill(
                        label: batch.status,
                        color: _batchStatusColor(batch.status),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingMd,
                  runSpacing: AppTheme.spacingSm,
                  children: [
                    _MetaLine(
                      title: loc.t('endpoint_type'),
                      value: batch.endpointType.isEmpty
                          ? loc.t('empty')
                          : batch.endpointType,
                    ),
                    _MetaLine(
                      title: loc.t('models'),
                      value: '${batch.modelCount}',
                    ),
                    _MetaLine(
                      title: loc.t('channels'),
                      value:
                          '${batch.channelNames.isNotEmpty ? batch.channelNames.length : batch.channelIds.length}',
                    ),
                    _MetaLine(
                      title: loc.t('ai_route_service'),
                      value: batch.serviceName.isEmpty
                          ? loc.t('empty')
                          : batch.serviceName,
                    ),
                    _MetaLine(
                      title: loc.t('attempt'),
                      value: '${batch.attempt > 0 ? batch.attempt : 1}',
                    ),
                  ],
                ),
                if (batch.channelNames.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Wrap(
                    spacing: AppTheme.spacingXs,
                    runSpacing: AppTheme.spacingXs,
                    children: batch.channelNames
                        .map((name) => _MiniTag(label: name))
                        .toList(),
                  ),
                ],
                if (batch.message.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    batch.message,
                    style: theme.textTheme.caption?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildChannelsCard(
    AppLocalizations loc,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final channels = [..._progress.channels]
      ..sort((a, b) {
        final statusCompare = _channelStatusOrder(
          a.status,
        ).compareTo(_channelStatusOrder(b.status));
        if (statusCompare != 0) return statusCompare;
        return a.channelName.compareTo(b.channelName);
      });

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('channels'),
            style: theme.textTheme.footnote?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...channels
              .take(12)
              .map(
                (channel) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
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
                                  channel.channelName.isEmpty
                                      ? 'Channel ${channel.channelId}'
                                      : channel.channelName,
                                  style: theme.textTheme.body?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (channel.provider.isNotEmpty)
                                  Text(
                                    channel.provider,
                                    style: theme.textTheme.caption?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _Pill(
                            label: channel.status,
                            color: _channelStatusColor(channel.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: channel.totalModels <= 0
                              ? 0
                              : channel.processedModels / channel.totalModels,
                          backgroundColor: colorScheme.outlineVariant
                              .withValues(alpha: 0.16),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _channelStatusColor(channel.status),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        '${channel.processedModels}/${channel.totalModels}',
                        style: theme.textTheme.caption?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (channel.message.isNotEmpty)
                        Text(
                          channel.message,
                          style: theme.textTheme.caption?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    AppLocalizations loc,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final result = _progress.result!;
    final text = result.scope == AIRouteScope.group
        ? loc.t('ai_route_result_group', {
            'routes': '${result.routeCount}',
            'items': '${result.itemCount}',
          })
        : loc.t('ai_route_result_table', {
            'routes': '${result.routeCount}',
            'groups': '${result.groupCount}',
            'items': '${result.itemCount}',
          });

    return AppCard(
      backgroundColor: AppTheme.colorGreen.withValues(alpha: 0.08),
      border: Border.all(color: AppTheme.colorGreen.withValues(alpha: 0.2)),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Text(
        text,
        style: theme.textTheme.body?.copyWith(
          color: AppTheme.colorGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorCard(ColorScheme colorScheme, ThemeData theme) {
    return AppCard(
      backgroundColor: colorScheme.error.withValues(alpha: 0.08),
      border: Border.all(color: colorScheme.error.withValues(alpha: 0.18)),
      child: Text(
        _error!,
        style: theme.textTheme.caption?.copyWith(color: colorScheme.error),
      ),
    );
  }

  String _scopeLabel(AIRouteScope scope, AppLocalizations loc) {
    return scope == AIRouteScope.group
        ? loc.t('ai_route_scope_group')
        : loc.t('ai_route_scope_table');
  }

  String _statusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case 'running':
        return loc.t('ai_route_status_running');
      case 'completed':
        return loc.t('ai_route_status_completed');
      case 'failed':
        return loc.t('ai_route_status_failed');
      case 'timeout':
        return loc.t('ai_route_status_timeout');
      default:
        return loc.t('ai_route_status_queued');
    }
  }

  String _stepLabel(String step, AppLocalizations loc) {
    switch (step) {
      case 'collecting_models':
        return loc.t('ai_route_step_collecting_models');
      case 'building_batches':
        return loc.t('ai_route_step_building_batches');
      case 'analyzing_batches':
        return loc.t('ai_route_step_analyzing_batches');
      case 'parsing_response':
        return loc.t('ai_route_step_parsing_response');
      case 'validating_routes':
        return loc.t('ai_route_step_validating_routes');
      case 'writing_groups':
        return loc.t('ai_route_step_writing_groups');
      case 'finalizing':
        return loc.t('ai_route_step_finalizing');
      case 'completed':
        return loc.t('ai_route_step_completed');
      case 'failed':
        return loc.t('ai_route_step_failed');
      case 'timeout':
        return loc.t('ai_route_step_timeout');
      default:
        return loc.t('ai_route_step_queued');
    }
  }

  String _batchTitle(AIRouteBatchProgress batch, AppLocalizations loc) {
    if (batch.endpointType.isEmpty) {
      return loc.t('ai_route_current_batch');
    }
    return batch.endpointType;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.colorGreen;
      case 'failed':
      case 'timeout':
        return AppTheme.colorRed;
      case 'running':
        return AppTheme.colorBlue;
      default:
        return AppTheme.colorOrange;
    }
  }

  Color _batchStatusColor(String status) {
    switch (status) {
      case 'parsing':
        return AppTheme.colorBlue;
      case 'retrying':
        return AppTheme.colorOrange;
      case 'failed':
        return AppTheme.colorRed;
      case 'completed':
        return AppTheme.colorGreen;
      default:
        return AppTheme.colorPurple;
    }
  }

  Color _channelStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.colorGreen;
      case 'failed':
        return AppTheme.colorRed;
      case 'running':
        return AppTheme.colorBlue;
      default:
        return AppTheme.colorGray;
    }
  }

  int _channelStatusOrder(String status) {
    switch (status) {
      case 'running':
        return 0;
      case 'completed':
        return 1;
      case 'pending':
        return 2;
      case 'failed':
        return 3;
      default:
        return 4;
    }
  }

  String _formatDateTime(String value, AppLocalizations loc) {
    if (value.isEmpty) return loc.t('empty');
    final parsed = DateTime.tryParse(value);
    if (parsed == null || parsed.year <= 1) return loc.t('empty');
    final local = parsed.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final sec = local.second.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$min:$sec';
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;

  const _MiniTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLow(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 132,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String title;
  final String value;

  const _MetaLine({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.caption?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.footnote?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
