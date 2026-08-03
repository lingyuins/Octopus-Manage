import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/ops.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

enum _OpsTab { overview, telemetry }

enum _ProviderSort { name, status, latency, errorRate }

class OpsPage extends StatefulWidget {
  const OpsPage({super.key});

  @override
  State<OpsPage> createState() => _OpsPageState();
}

class _OpsPageState extends State<OpsPage> {
  // Overview data
  OpsSystemSummary? _system;
  OpsCacheStatus? _cache;
  OpsHealthStatus? _health;
  OpsQuotaSummary? _quota;
  bool _loading = true;

  // Telemetry data
  OpsTelemetrySummary? _telemetry;
  bool _telemetryLoading = true;
  String? _telemetryError;

  // Tab & sort state
  _OpsTab _tab = _OpsTab.overview;
  _ProviderSort _providerSort = _ProviderSort.name;
  bool _providerSortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _telemetryLoading = true;
      _telemetryError = null;
    });
    final api = context.read<AppProvider>().api;
    try {
      final results = await Future.wait([
        api.getOpsSystem(),
        api.getOpsCache(),
        api.getOpsHealth(),
        api.getOpsQuota(),
      ]);
      if (mounted) {
        _system = results[0] as OpsSystemSummary;
        _cache = results[1] as OpsCacheStatus;
        _health = results[2] as OpsHealthStatus;
        _quota = results[3] as OpsQuotaSummary;
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    // Load telemetry separately so overview still shows if telemetry fails
    try {
      final telemetry = await api.getOpsTelemetry();
      if (mounted) setState(() => _telemetry = telemetry);
    } catch (e) {
      if (mounted) setState(() => _telemetryError = e.toString());
    } finally {
      if (mounted) setState(() => _telemetryLoading = false);
    }
  }

  Widget _statusIcon(bool ok) {
    return Icon(
      ok ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
      size: 16,
      color: ok ? AppTheme.colorGreen : AppTheme.colorRed,
    );
  }

  Color _providerStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return AppTheme.colorGreen;
      case 'degraded':
        return AppTheme.colorOrange;
      case 'down':
        return AppTheme.colorRed;
      default:
        return AppTheme.colorGray;
    }
  }

  List<OpsProviderItem> _sortedProviders(List<OpsProviderItem> providers) {
    final list = List<OpsProviderItem>.from(providers);
    switch (_providerSort) {
      case _ProviderSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _ProviderSort.status:
        list.sort((a, b) => a.status.compareTo(b.status));
        break;
      case _ProviderSort.latency:
        list.sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
        break;
      case _ProviderSort.errorRate:
        list.sort((a, b) => a.errorRate.compareTo(b.errorRate));
        break;
    }
    return _providerSortAsc ? list : list.reversed.toList();
  }

  void _toggleProviderSort(_ProviderSort field) {
    setState(() {
      if (_providerSort == field) {
        _providerSortAsc = !_providerSortAsc;
      } else {
        _providerSort = field;
        _providerSortAsc = true;
      }
    });
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(loc.t('ops')),
              backgroundColor: AppTheme.getSurfaceLowest(colorScheme)
                  .withValues(alpha: 0.85),
              border: null,
            ),
            CupertinoSliverRefreshControl(onRefresh: _loadAll),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingState(),
              )
            else ...[
              // Segmented control
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg, AppTheme.spacingSm,
                    AppTheme.spacingLg, 0,
                  ),
                  child: CupertinoSlidingSegmentedControl<_OpsTab>(
                    groupValue: _tab,
                    children: {
                      _OpsTab.overview: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(loc.t('ops_overview')),
                      ),
                      _OpsTab.telemetry: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(loc.t('ops_telemetry')),
                      ),
                    },
                    onValueChanged: (v) {
                      if (v != null) setState(() => _tab = v);
                    },
                  ),
                ),
              ),
              if (_tab == _OpsTab.overview) ..._buildOverview(loc, colorScheme) else ..._buildTelemetry(loc, colorScheme, theme),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== Overview Tab ====================

  List<Widget> _buildOverview(AppLocalizations loc, ColorScheme colorScheme) {
    return [
      // System Card
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_system'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('server_version'), _system?.version ?? '-'),
              _infoRow(loc.t('database_type'), _system?.databaseType ?? '-'),
              _infoRow(loc.t('channels'), '${_system?.channelCount ?? 0}'),
              _infoRow(loc.t('groups'), '${_system?.groupCount ?? 0}'),
              _infoRow(loc.t('api_keys'), '${_system?.apiKeyCount ?? 0}'),
              if ((_system?.proxyURL ?? '').isNotEmpty)
                _infoRow(loc.t('setting_proxy_url'), _system!.proxyURL),
              _infoRow(loc.t('ops_build_time'), _system?.buildTime ?? '-'),
              if ((_system?.relayRetryCount ?? 0) > 0)
                _infoRow(loc.t('setting_relay_retry_count'), '${_system!.relayRetryCount}'),
              if (_system?.circuitBreakerEnabled == true) ...[
                _infoRow(loc.t('setting_circuit_breaker_threshold'),
                    '${_system!.circuitBreakerThreshold}'),
                _infoRow(loc.t('setting_circuit_breaker_cooldown'),
                    '${_system!.circuitBreakerRecoveryMs}ms'),
              ],
              if (_system?.aiRouteEnabled == true)
                _infoRow(loc.t('ai_route_service'), '${_system!.aiRouteServiceCount}'),
            ],
          ),
        ),
      ),
      // Health Card
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_health'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingMd),
              Row(children: [
                _statusIcon(_health?.databaseOK ?? false),
                const SizedBox(width: 8),
                Text(loc.t('ops_db_status')),
                const Spacer(),
                Text(_health?.databaseOK == true ? loc.t('ops_ok') : loc.t('ops_fail'),
                  style: TextStyle(color: _health?.databaseOK == true
                    ? AppTheme.colorGreen : AppTheme.colorRed)),
              ]),
              const SizedBox(height: AppTheme.spacingSm),
              Row(children: [
                _statusIcon(_health?.cacheOK ?? false),
                const SizedBox(width: 8),
                Text(loc.t('ops_cache_status')),
                const Spacer(),
                Text(_health?.cacheOK == true ? loc.t('ops_ok') : loc.t('ops_fail'),
                  style: TextStyle(color: _health?.cacheOK == true
                    ? AppTheme.colorGreen : AppTheme.colorRed)),
              ]),
              const SizedBox(height: AppTheme.spacingSm),
              Row(children: [
                _statusIcon(_health?.taskRuntimeOK ?? false),
                const SizedBox(width: 8),
                Text(loc.t('ops_task_status')),
                const Spacer(),
                Text(_health?.taskRuntimeOK == true ? loc.t('ops_ok') : loc.t('ops_fail'),
                  style: TextStyle(color: _health?.taskRuntimeOK == true
                    ? AppTheme.colorGreen : AppTheme.colorRed)),
              ]),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('ops_healthy_groups'), '${_health?.healthyGroupCount ?? 0}'),
              _infoRow(loc.t('ops_warning_groups'), '${_health?.warningGroupCount ?? 0}'),
              _infoRow(loc.t('ops_degraded_groups'), '${_health?.degradedGroupCount ?? 0}'),
              _infoRow(loc.t('ops_down_groups'), '${_health?.downGroupCount ?? 0}'),
              _infoRow(loc.t('ops_empty_groups'), '${_health?.emptyGroupCount ?? 0}'),
            ],
          ),
        ),
      ),
      // Cache Card
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(loc.t('ops_cache'),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
                const Spacer(),
                AppInfoChip(
                  icon: _cache?.runtimeEnabled == true
                    ? CupertinoIcons.checkmark_circle
                    : CupertinoIcons.xmark_circle,
                  label: _cache?.runtimeEnabled == true
                    ? loc.t('enabled') : loc.t('disabled'),
                ),
              ]),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('ops_cache_entries'),
                '${_cache?.currentEntries ?? 0} / ${_cache?.maxEntries ?? 0}'),
              _infoRow(loc.t('ops_cache_hits'), '${_cache?.hits ?? 0}'),
              _infoRow(loc.t('ops_cache_misses'), '${_cache?.misses ?? 0}'),
              _infoRow(loc.t('ops_cache_hit_rate'),
                '${(_cache?.hitRate ?? 0).toStringAsFixed(1)}%'),
              _infoRow(loc.t('ops_cache_usage_rate'),
                '${(_cache?.usageRate ?? 0).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ),
      // Quota Card
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_quota'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('ops_total_keys'), '${_quota?.totalKeyCount ?? 0}'),
              _infoRow(loc.t('ops_enabled_keys'), '${_quota?.enabledKeyCount ?? 0}'),
              _infoRow(loc.t('ops_available_keys'), '${_quota?.availableKeyCount ?? 0}'),
              _infoRow(loc.t('ops_expired_keys'), '${_quota?.expiredKeyCount ?? 0}'),
              _infoRow(loc.t('ops_limited_keys'), '${_quota?.limitedKeyCount ?? 0}'),
              _infoRow(loc.t('ops_exhausted_keys'), '${_quota?.exhaustedKeyCount ?? 0}'),
              _infoRow(loc.t('ops_total_rpm'), '${_quota?.totalRPM ?? 0}'),
              _infoRow(loc.t('ops_total_tpm'), '${_quota?.totalTPM ?? 0}'),
            ],
          ),
        ),
      ),
    ];
  }

  // ==================== Telemetry Tab ====================

  List<Widget> _buildTelemetry(AppLocalizations loc, ColorScheme colorScheme, ThemeData theme) {
    if (_telemetryLoading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoadingState(),
        ),
      ];
    }
    if (_telemetryError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorState(
            message: _telemetryError!,
            onRetry: () async {
              setState(() { _telemetryLoading = true; _telemetryError = null; });
              try {
                final api = context.read<AppProvider>().api;
                final t = await api.getOpsTelemetry();
                if (mounted) setState(() => _telemetry = t);
              } catch (e) {
                if (mounted) setState(() => _telemetryError = e.toString());
              } finally {
                if (mounted) setState(() => _telemetryLoading = false);
              }
            },
          ),
        ),
      ];
    }

    final t = _telemetry!;
    return [
      // Hero Metrics Grid
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_hero_metrics'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.spacingSm,
            crossAxisSpacing: AppTheme.spacingSm,
            childAspectRatio: 1.8,
          ),
          delegate: SliverChildListDelegate([
            _heroMetricTile(
              icon: CupertinoIcons.clock,
              accent: AppTheme.colorBlue,
              title: loc.t('ops_uptime'),
              value: t.heroMetrics.uptime.isEmpty ? '-' : t.heroMetrics.uptime,
            ),
            _heroMetricTile(
              icon: CupertinoIcons.arrow_right_arrow_left,
              accent: AppTheme.colorIndigo,
              title: loc.t('ops_total_requests'),
              value: _formatNumber(t.heroMetrics.totalRequests),
            ),
            _heroMetricTile(
              icon: CupertinoIcons.speedometer,
              accent: AppTheme.colorPurple,
              title: loc.t('ops_avg_latency'),
              value: '${t.heroMetrics.avgLatency.toStringAsFixed(1)}ms',
            ),
            _heroMetricTile(
              icon: CupertinoIcons.exclamationmark_triangle,
              accent: t.heroMetrics.errorRate > 5 ? AppTheme.colorRed : AppTheme.colorOrange,
              title: loc.t('ops_error_rate'),
              value: '${t.heroMetrics.errorRate.toStringAsFixed(2)}%',
            ),
            _heroMetricTile(
              icon: CupertinoIcons.antenna_radiowaves_left_right,
              accent: AppTheme.colorTeal,
              title: loc.t('ops_active_connections'),
              value: '${t.heroMetrics.activeConnections}',
            ),
            _heroMetricTile(
              icon: CupertinoIcons.device_laptop,
              accent: AppTheme.colorGreen,
              title: loc.t('ops_memory_usage'),
              value: '${t.heroMetrics.memoryUsageMB.toStringAsFixed(1)} MB',
            ),
          ]),
        ),
      ),

      // Runtime Signals
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_runtime_signals'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('ops_goroutine_count'), '${t.runtimeSignals.goroutineCount}'),
              _infoRow(loc.t('ops_gc_pause'), '${t.runtimeSignals.gcPauseMs.toStringAsFixed(2)}ms'),
              _infoRow(loc.t('ops_heap_alloc'), '${t.runtimeSignals.heapAllocMB.toStringAsFixed(1)} MB'),
              _infoRow(loc.t('ops_heap_in_use'), '${t.runtimeSignals.heapInUseMB.toStringAsFixed(1)} MB'),
            ],
          ),
        ),
      ),

      // Database Health
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(loc.t('ops_db_status'),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
                const Spacer(),
                _statusIcon(t.databaseHealth.connected),
              ]),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('database_type'), t.databaseHealth.type.isEmpty ? '-' : t.databaseHealth.type),
              _infoRow(loc.t('ops_db_latency'), '${t.databaseHealth.latencyMs.toStringAsFixed(1)}ms'),
              _infoRow(loc.t('ops_db_connections'),
                  '${t.databaseHealth.activeConnections} / ${t.databaseHealth.maxConnections}'),
            ],
          ),
        ),
      ),

      // Session & Quota
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_session_quota'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('ops_active_sessions'), '${t.sessionQuotaActivity.activeSessions}'),
              _infoRow(loc.t('ops_quota_exhausted'), '${t.sessionQuotaActivity.quotaExhaustedCount}'),
              _infoRow(loc.t('ops_recent_quota_events'), '${t.sessionQuotaActivity.recentQuotaEvents}'),
            ],
          ),
        ),
      ),

      // Prompt Cache
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_prompt_cache'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingMd),
              _infoRow(loc.t('ops_cache_entries'), '${t.promptCache.entries} / ${t.promptCache.maxEntries}'),
              _infoRow(loc.t('ops_cache_hits'), '${t.promptCache.hits}'),
              _infoRow(loc.t('ops_cache_misses'), '${t.promptCache.misses}'),
              _infoRow(loc.t('ops_cache_hit_rate'), '${t.promptCache.hitRate.toStringAsFixed(1)}%'),
              _infoRow(loc.t('ops_cache_evictions'), '${t.promptCache.evictions}'),
            ],
          ),
        ),
      ),

      // Provider Health Summary
      SliverToBoxAdapter(
        child: AppCard(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg, AppTheme.spacingMd,
            AppTheme.spacingLg, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('ops_provider_health'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
              const SizedBox(height: AppTheme.spacingMd),
              Row(children: [
                _summaryPill(loc.t('ops_total_providers'), '${t.providerHealth.totalProviders}', AppTheme.colorBlue),
                const SizedBox(width: AppTheme.spacingSm),
                _summaryPill(loc.t('ops_healthy_providers'), '${t.providerHealth.healthyProviders}', AppTheme.colorGreen),
                const SizedBox(width: AppTheme.spacingSm),
                _summaryPill(loc.t('ops_degraded_providers'), '${t.providerHealth.degradedProviders}', AppTheme.colorOrange),
                const SizedBox(width: AppTheme.spacingSm),
                _summaryPill(loc.t('ops_down_providers'), '${t.providerHealth.downProviders}', AppTheme.colorRed),
              ]),
            ],
          ),
        ),
      ),

      // Provider Table
      if (t.providerHealth.providers.isNotEmpty)
        SliverToBoxAdapter(
          child: AppCard(
            margin: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg, AppTheme.spacingMd,
              AppTheme.spacingLg, 0,
            ),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Sort controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg, AppTheme.spacingMd,
                    AppTheme.spacingLg, AppTheme.spacingSm,
                  ),
                  child: Row(
                    children: [
                      Text(loc.t('ops_sort_by'),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                      const SizedBox(width: AppTheme.spacingSm),
                      _sortChip(loc.t('ops_provider_name'), _ProviderSort.name),
                      const SizedBox(width: AppTheme.spacingXs),
                      _sortChip(loc.t('ops_provider_status'), _ProviderSort.status),
                      const SizedBox(width: AppTheme.spacingXs),
                      _sortChip(loc.t('ops_provider_latency'), _ProviderSort.latency),
                      const SizedBox(width: AppTheme.spacingXs),
                      _sortChip(loc.t('ops_provider_error_rate'), _ProviderSort.errorRate),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Table header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg, AppTheme.spacingSm,
                    AppTheme.spacingLg, AppTheme.spacingXs,
                  ),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text(loc.t('ops_provider_name'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant))),
                    Expanded(flex: 2, child: Text(loc.t('ops_provider_status'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant))),
                    Expanded(flex: 2, child: Text(loc.t('ops_provider_latency'),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant))),
                    Expanded(flex: 2, child: Text(loc.t('ops_provider_error_rate'),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant))),
                  ]),
                ),
                const Divider(height: 1),
                // Rows
                ..._sortedProviders(t.providerHealth.providers).map(
                  (p) => _providerRow(p, colorScheme),
                ),
                const SizedBox(height: AppTheme.spacingSm),
              ],
            ),
          ),
        ),
    ];
  }

  // ==================== Shared Widgets ====================

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _heroMetricTile({
    required IconData icon,
    required Color accent,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLow(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, size: 13, color: accent),
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Expanded(
              child: Text(title,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: AppTheme.spacingXs),
          Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: accent, height: 1.1),
            overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          children: [
            Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
              overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label, _ProviderSort field) {
    final isActive = _providerSort == field;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _toggleProviderSort(field),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              )),
            if (isActive) ...[
              const SizedBox(width: 2),
              Icon(
                _providerSortAsc
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 10,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _providerRow(OpsProviderItem p, ColorScheme colorScheme) {
    final statusColor = _providerStatusColor(p.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg, AppTheme.spacingSm,
        AppTheme.spacingLg, AppTheme.spacingSm,
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(p.name,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
              color: colorScheme.onSurface),
            overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(p.status,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: statusColor),
              textAlign: TextAlign.center),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('${p.latencyMs.toStringAsFixed(1)}ms',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
        ),
        Expanded(
          flex: 2,
          child: Text('${p.errorRate.toStringAsFixed(2)}%',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14,
              color: p.errorRate > 5 ? AppTheme.colorRed : colorScheme.onSurface)),
        ),
      ]),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
