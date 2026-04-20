import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/stats.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StatsMetrics? _today;
  StatsMetrics? _total;
  List<StatsDaily> _daily = [];
  List<StatsAPIKeyEntry> _apiKeyStats = [];
  List<Channel> _channels = [];
  bool _loading = true;
  bool _showToday = true;
  final Set<String> _expandedRankings = {};
  String? _error;
  bool _requestInFlight = false;

  Map<int, APIKey> _apiKeysMap = {};
  Timer? _autoRefreshTimer;
  AppProvider? _appProvider;

  static const int _rankingPreviewCount = 5;
  static const int _rankingPreviewCountMobile = 3;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AppProvider>();
    if (!identical(_appProvider, provider)) {
      _appProvider?.removeListener(_handleProviderChanged);
      _appProvider = provider;
      provider.addListener(_handleProviderChanged);
      _configureAutoRefresh(provider);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _appProvider?.removeListener(_handleProviderChanged);
    super.dispose();
  }

  void _handleProviderChanged() {
    final provider = _appProvider;
    if (!mounted || provider == null) return;
    _configureAutoRefresh(provider);
  }

  void _configureAutoRefresh(AppProvider provider) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;

    if (!provider.autoRefreshEnabled) return;

    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: provider.autoRefreshIntervalSeconds),
      (_) => _loadStats(silent: true),
    );
  }

  Future<void> _loadStats({bool silent = false}) async {
    if (_requestInFlight) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    _requestInFlight = true;
    try {
      final api = context.read<AppProvider>().api;

      // 并行请求所有数据，apiKeys 单独处理以避免单个失败导致整体失败
      final futures = await Future.wait([
        api.getStatsToday(),
        api.getStatsTotal(),
        api.getStatsDaily(),
        api.getStatsApiKey(),
        api.getChannels(),
      ]);

      // apiKeys 单独请求，失败不影响主流程
      Map<int, APIKey> apiKeysMap = {};
      try {
        final apiKeys = await api.getApiKeys();
        apiKeysMap = {for (var k in apiKeys) k.id: k};
      } catch (_) {}

      if (mounted) {
        setState(() {
          _today = futures[0] as StatsMetrics?;
          _total = futures[1] as StatsMetrics?;
          _daily = futures[2] as List<StatsDaily>;
          _apiKeyStats = futures[3] as List<StatsAPIKeyEntry>;
          _channels = futures[4] as List<Channel>;
          _apiKeysMap = apiKeysMap;
          _loading = false;
          _error = null;
          _expandedRankings.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (!silent) {
            _error = e.toString();
          }
        });
      }
    } finally {
      _requestInFlight = false;
    }
  }

  String _getApiKeyDisplayName(int id) {
    final key = _apiKeysMap[id];
    if (key != null && key.name.isNotEmpty) {
      return key.name;
    }
    return 'Key #$id';
  }

  String _formatNum(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  String _formatCurrency(double value, {int digits = 4}) {
    return '\$${value.toStringAsFixed(digits)}';
  }

  String _formatCurrencyCompact(num value, {int digits = 4}) {
    // 使用 toStringAsFixed 避免 toString() 输出科学计数法
    return '\$${value.toStringAsFixed(digits)}';
  }

  String _formatDailyAxisDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed != null) {
      return '${parsed.month}/${parsed.day}';
    }
    if (date.length >= 10) {
      final month = int.tryParse(date.substring(5, 7));
      final day = int.tryParse(date.substring(8, 10));
      if (month != null && day != null) {
        return '$month/$day';
      }
    }
    return date;
  }

  double _calculateDailyAxisInterval(double maxValue, {int targetTicks = 5}) {
    if (maxValue <= 0) return 1;

    final rawInterval = maxValue / targetTicks;
    final magnitude = math
        .pow(10, (math.log(rawInterval) / math.ln10).floor())
        .toDouble();
    final normalized = rawInterval / magnitude;

    final niceNormalized = switch (normalized) {
      <= 1 => 1.0,
      <= 2 => 2.0,
      <= 2.5 => 2.5,
      <= 5 => 5.0,
      _ => 10.0,
    };

    return niceNormalized * magnitude;
  }

  StatsMetrics get _selectedStats =>
      _showToday ? (_today ?? StatsMetrics()) : (_total ?? StatsMetrics());

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final loc = provider.loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const AppLoadingState();
    }

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
              largeTitle: Text(loc.t('dashboard')),
              backgroundColor: AppTheme.getSurfaceLowest(
                colorScheme,
              ).withValues(alpha: 0.85),
              border: null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoSlidingSegmentedControl<bool>(
                    groupValue: _showToday,
                    onValueChanged: (v) {
                      if (v != null) setState(() => _showToday = v);
                    },
                    children: {
                      true: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          loc.t('today'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      false: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          loc.t('total'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    },
                  ),
                ],
              ),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () => _loadStats(silent: true),
            ),
            if (_error != null)
              SliverFillRemaining(
                child: AppErrorState(message: _error!, onRetry: _loadStats),
              )
            else ...[
              _buildCompactOverview(
                theme,
                colorScheme,
                loc,
                provider.waitTimeUnit,
              ),
              if (_daily.isNotEmpty) _buildDailyChart(theme, colorScheme, loc),
              _buildRankingSection(theme, colorScheme, loc),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactOverview(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
    WaitTimeUnit waitUnit,
  ) {
    final stats = _selectedStats;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingLg,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 2;
            const spacing = AppTheme.spacingSm;
            final itemWidth =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;
            final targetHeight = constraints.maxWidth < 380 ? 96.0 : 100.0;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: itemWidth / targetHeight,
              children: [
                _buildStatItem(
                  loc.t('requests'),
                  _formatNum(stats.requestSuccess + stats.requestFailed),
                  CupertinoIcons.paperplane,
                  AppTheme.colorBlue,
                  theme,
                  colorScheme,
                  '${loc.t('success')}: ${_formatNum(stats.requestSuccess)}',
                ),
                _buildStatItem(
                  loc.t('cost'),
                  _formatCurrency(stats.totalCost),
                  CupertinoIcons.money_dollar_circle,
                  AppTheme.colorGreen,
                  theme,
                  colorScheme,
                  '${loc.t('input')}: ${_formatCurrency(stats.inputCost)}',
                ),
                _buildStatItem(
                  loc.t('tokens'),
                  _formatNum(stats.totalTokens),
                  CupertinoIcons.chart_pie,
                  AppTheme.colorOrange,
                  theme,
                  colorScheme,
                  '${loc.t('input')}: ${_formatNum(stats.inputToken)}',
                ),
                _buildStatItem(
                  loc.t('success_rate'),
                  '${(stats.successRate * 100).toStringAsFixed(1)}%',
                  CupertinoIcons.arrow_up_circle,
                  AppTheme.colorPurple,
                  theme,
                  colorScheme,
                  'Avg: ${_formatWaitTime(stats.waitTime, loc, waitUnit)}',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
    String? subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLow(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.12),
        ),
        boxShadow: AppTheme.getShadow(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 11, color: color),
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                label,
                style: theme.textTheme.footnote?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.footnote?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatWaitTime(int ms, AppLocalizations loc, WaitTimeUnit unit) {
    switch (unit) {
      case WaitTimeUnit.ms:
        return '${ms}ms';
      case WaitTimeUnit.s:
        return '${(ms / 1000).toStringAsFixed(2)}s';
      case WaitTimeUnit.auto:
        if (ms < 1000) return '${ms}ms';
        if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
        return '${(ms / 60000).toStringAsFixed(1)}m';
    }
  }

  Widget _buildDailyChart(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    final data = _daily.reversed.toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingLg,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.t('daily_chart'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                Text(
                  loc.t('daily_chart_subtitle'),
                  style: theme.textTheme.footnote?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceLow(colorScheme),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
                boxShadow: AppTheme.getShadow(colorScheme),
              ),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  // 图例
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLegendItem(
                        'Requests',
                        AppTheme.colorBlue,
                        CupertinoIcons.chart_bar_fill,
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      _buildLegendItem(
                        'Cost',
                        AppTheme.colorGreen,
                        CupertinoIcons.money_dollar_circle_fill,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    height: 200,
                    child: _buildCombinedDailyChart(
                      data,
                      loc,
                      theme,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedDailyChart(
    List<StatsDaily> data,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    double maxRequests = 0;
    double maxCost = 0;
    for (final d in data) {
      final requests =
          d.metrics.requestSuccess.toDouble() +
          d.metrics.requestFailed.toDouble();
      if (requests > maxRequests) maxRequests = requests;
      if (d.metrics.totalCost > maxCost) maxCost = d.metrics.totalCost;
    }
    final yAxisInterval = _calculateDailyAxisInterval(maxRequests);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yAxisInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
            strokeWidth: 0.5,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yAxisInterval,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                _formatNum(v.toInt()),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yAxisInterval,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Text(
                _formatCurrencyCompact(
                  maxRequests > 0 && maxCost > 0
                      ? (v / maxRequests) * maxCost
                      : 0,
                  digits: 0,
                ),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final date = data[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatDailyAxisDate(date),
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                );
              },
              interval: data.length > 5 ? (data.length / 5).ceilToDouble() : 1,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map(
                  (e) => FlSpot(
                    e.key.toDouble(),
                    e.value.metrics.requestSuccess.toDouble() +
                        e.value.metrics.requestFailed.toDouble(),
                  ),
                )
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.colorBlue,
            barWidth: 2.5,
            dotData: FlDotData(
              show: data.length <= 7,
              checkToShowDot: (spot, barData) {
                return spot.x == data.length - 1 ||
                    (data.length <= 7 && spot.x % 1 == 0);
              },
              getDotPainter: (spot, xPercent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.colorBlue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.colorBlue.withValues(alpha: 0.18),
                  AppTheme.colorBlue.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map(
                  (e) => FlSpot(
                    e.key.toDouble(),
                    maxCost > 0 && maxRequests > 0
                        ? (e.value.metrics.totalCost / maxCost) * maxRequests
                        : 0,
                  ),
                )
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.colorGreen,
            barWidth: 2.5,
            dotData: FlDotData(
              show: data.length <= 7,
              checkToShowDot: (spot, barData) {
                return spot.x == data.length - 1 ||
                    (data.length <= 7 && spot.x % 1 == 0);
              },
              getDotPainter: (spot, xPercent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.colorGreen,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.colorGreen.withValues(alpha: 0.14),
                  AppTheme.colorGreen.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipMargin: 8,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt();
              final isRequests = s.barIndex == 0;
              final color = isRequests
                  ? AppTheme.colorBlue
                  : AppTheme.colorGreen;

              if (isRequests) {
                final count = i >= 0 && i < data.length
                    ? data[i].metrics.requestSuccess +
                          data[i].metrics.requestFailed
                    : 0;
                final date = i >= 0 && i < data.length ? data[i].date : '';
                return LineTooltipItem(
                  '$date\n',
                  TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '${loc.t('daily_requests')}: ',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    TextSpan(
                      text: _formatNum(count),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }
              final cost = i >= 0 && i < data.length
                  ? data[i].metrics.totalCost
                  : 0.0;
              return LineTooltipItem(
                '${loc.t('daily_cost')}: ',
                TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                children: [
                  TextSpan(
                    text: _formatCurrency(cost, digits: 0),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          handleBuiltInTouches: true,
        ),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildRankingSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    final tokenRanking = _getTokenRanking();
    final requestRanking = _getRequestRanking();
    final apiKeyRanking = _getApiKeyRanking();

    final isMobile = Responsive.isCompact(context);
    final previewCount = isMobile
        ? _rankingPreviewCountMobile
        : _rankingPreviewCount;

    const tokenKey = 'token';
    const requestKey = 'request';
    const apiKeyKey = 'apikey';

    final tokenExpanded = _expandedRankings.contains(tokenKey);
    final requestExpanded = _expandedRankings.contains(requestKey);
    final apiKeyExpanded = _expandedRankings.contains(apiKeyKey);

    final tokenItems = tokenExpanded
        ? tokenRanking
        : tokenRanking.take(previewCount).toList();
    final requestItems = requestExpanded
        ? requestRanking
        : requestRanking.take(previewCount).toList();
    final apiKeyItems = apiKeyExpanded
        ? apiKeyRanking
        : apiKeyRanking.take(previewCount).toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.t('ranking'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                Text(
                  loc.t('ranking_subtitle'),
                  style: theme.textTheme.footnote?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildRankingCard(
              loc.t('token_consumption_ranking'),
              tokenItems,
              tokenRanking.length > previewCount,
              tokenExpanded,
              CupertinoIcons.flame,
              AppTheme.colorOrange,
              theme,
              colorScheme,
              loc,
              (item, rank) {
                if (item is Channel && item.stats != null) {
                  return _buildChannelRankingTile(
                    item,
                    theme,
                    colorScheme,
                    item.stats!,
                    'token',
                    rank,
                    loc,
                  );
                }
                return const SizedBox.shrink();
              },
              () => setState(() {
                tokenExpanded
                    ? _expandedRankings.remove(tokenKey)
                    : _expandedRankings.add(tokenKey);
              }),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _buildRankingCard(
              loc.t('request_activity_ranking'),
              requestItems,
              requestRanking.length > previewCount,
              requestExpanded,
              CupertinoIcons.arrow_up_circle,
              AppTheme.colorBlue,
              theme,
              colorScheme,
              loc,
              (item, rank) {
                if (item is Channel && item.stats != null) {
                  return _buildChannelRankingTile(
                    item,
                    theme,
                    colorScheme,
                    item.stats!,
                    'request',
                    rank,
                    loc,
                  );
                }
                return const SizedBox.shrink();
              },
              () => setState(() {
                requestExpanded
                    ? _expandedRankings.remove(requestKey)
                    : _expandedRankings.add(requestKey);
              }),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _buildRankingCard(
              loc.t('key_usage_ranking'),
              apiKeyItems,
              apiKeyRanking.length > previewCount,
              apiKeyExpanded,
              CupertinoIcons.tag,
              AppTheme.colorPurple,
              theme,
              colorScheme,
              loc,
              (item, rank) {
                if (item is! StatsAPIKeyEntry) return const SizedBox.shrink();
                return _buildApiKeyRankingTile(
                  item,
                  theme,
                  colorScheme,
                  loc,
                  rank,
                );
              },
              () => setState(() {
                apiKeyExpanded
                    ? _expandedRankings.remove(apiKeyKey)
                    : _expandedRankings.add(apiKeyKey);
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<Channel> _getTokenRanking() {
    return _channels.where((c) => c.stats != null).toList()..sort(
      (a, b) => (b.stats!.inputToken + b.stats!.outputToken).compareTo(
        a.stats!.inputToken + a.stats!.outputToken,
      ),
    );
  }

  List<Channel> _getRequestRanking() {
    return _channels.where((c) => c.stats != null).toList()..sort(
      (a, b) => (b.stats!.requestSuccess + b.stats!.requestFailed).compareTo(
        a.stats!.requestSuccess + a.stats!.requestFailed,
      ),
    );
  }

  List<StatsAPIKeyEntry> _getApiKeyRanking() {
    return _apiKeyStats..sort(
      (a, b) => (b.metrics.requestSuccess + b.metrics.requestFailed).compareTo(
        a.metrics.requestSuccess + a.metrics.requestFailed,
      ),
    );
  }

  Widget _buildRankingCard(
    String title,
    List<dynamic> items,
    bool hasMore,
    bool isExpanded,
    IconData icon,
    Color accentColor,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
    Widget Function(dynamic, int) itemBuilder,
    VoidCallback? onToggleExpand,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLow(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.12),
        ),
        boxShadow: AppTheme.getShadow(colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: accentColor),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  title,
                  style: theme.textTheme.footnote?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Center(
                child: Text(loc.t('no_data'), style: theme.textTheme.footnote),
              ),
            )
          else
            ...items.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: AppTheme.spacingLg,
                      endIndent: AppTheme.spacingLg,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  itemBuilder(item, index + 1),
                ],
              );
            }),
          if (hasMore)
            GestureDetector(
              onTap: onToggleExpand,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.radiusLarge),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded ? loc.t('collapse') : loc.t('show_more'),
                        style: theme.textTheme.footnote?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChannelRankingTile(
    Channel channel,
    ThemeData theme,
    ColorScheme colorScheme,
    StatsChannel stats,
    String type,
    int rank,
    AppLocalizations loc,
  ) {
    String value;
    Color valueColor;
    if (type == 'token') {
      value = _formatNum(stats.inputToken + stats.outputToken);
      valueColor = AppTheme.colorOrange;
    } else {
      value = _formatNum(stats.requestSuccess + stats.requestFailed);
      valueColor = AppTheme.colorBlue;
    }

    final successRate = (stats.requestSuccess + stats.requestFailed) > 0
        ? stats.requestSuccess / (stats.requestSuccess + stats.requestFailed)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  style: theme.textTheme.body?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(successRate * 100).toStringAsFixed(0)}% ${loc.t('success')}',
                  style: theme.textTheme.footnote,
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyRankingTile(
    StatsAPIKeyEntry entry,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
    int rank,
  ) {
    final displayName = _getApiKeyDisplayName(entry.apiKeyId);
    final metrics = entry.metrics;
    final totalRequests = metrics.requestSuccess + metrics.requestFailed;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.body?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatCurrency(entry.metrics.totalCost),
                  style: theme.textTheme.footnote,
                ),
              ],
            ),
          ),
          Text(
            _formatNum(totalRequests),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.colorPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    final colorScheme = Theme.of(context).colorScheme;

    if (rank == 1) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.colorOrange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          CupertinoIcons.star_fill,
          size: 12,
          color: AppTheme.colorOrange,
        ),
      );
    }
    if (rank == 2) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.colorGray.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          CupertinoIcons.star_fill,
          size: 12,
          color: AppTheme.colorGray,
        ),
      );
    }
    if (rank == 3) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.colorPurple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          CupertinoIcons.star_fill,
          size: 12,
          color: AppTheme.colorPurple,
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceHigh(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
    );
  }
}
