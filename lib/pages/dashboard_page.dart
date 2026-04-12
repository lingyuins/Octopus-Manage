import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/stats.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
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
  bool _rankingExpanded = false;

  Map<int, APIKey> _apiKeysMap = {};

  static const int _rankingPreviewCount = 5;
  static const int _rankingPreviewCountMobile = 3;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;

      final results = await Future.wait([
        api.getStatsToday(),
        api.getStatsTotal(),
        api.getStatsDaily(),
        api.getStatsApiKey(),
        api.getChannels(),
        _loadApiKeysForMapping(),
      ]);

      if (mounted) {
        setState(() {
          _today = results[0] as StatsMetrics?;
          _total = results[1] as StatsMetrics?;
          _daily = results[2] as List<StatsDaily>;
          _apiKeyStats = results[3] as List<StatsAPIKeyEntry>;
          _channels = results[4] as List<Channel>;
          _loading = false;
          _rankingExpanded = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadApiKeysForMapping() async {
    try {
      final apiKeys = await context.read<AppProvider>().api.getApiKeys();
      _apiKeysMap = {for (var k in apiKeys) k.id: k};
    } catch (_) {}
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

  String _formatCurrencyCompact(num value) {
    return '\$${value.toString()}';
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
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _loadStats,
                    child: Icon(
                      CupertinoIcons.refresh,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.read<AppProvider>().logout(),
                    child: Icon(
                      CupertinoIcons.square_arrow_right,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            _buildCompactOverview(
              theme,
              colorScheme,
              loc,
              provider.waitTimeUnit,
            ),
            if (_daily.isNotEmpty) _buildDailyChart(theme, colorScheme, loc),
            _buildRankingSection(theme, colorScheme, loc),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.spacingSm,
              crossAxisSpacing: AppTheme.spacingSm,
              childAspectRatio: 1.6,
              children: [
                _buildStatItem(
                  loc.t('requests'),
                  _formatNum(stats.requestSuccess + stats.requestFailed),
                  CupertinoIcons.paperplane,
                  const Color(0xFF007AFF),
                  theme,
                  colorScheme,
                  '${loc.t('success')}: ${_formatNum(stats.requestSuccess)}',
                ),
                _buildStatItem(
                  loc.t('cost'),
                  _formatCurrency(stats.totalCost),
                  CupertinoIcons.money_dollar_circle,
                  const Color(0xFF34C759),
                  theme,
                  colorScheme,
                  '${loc.t('input')}: ${_formatCurrency(stats.inputCost)}',
                ),
                _buildStatItem(
                  loc.t('tokens'),
                  _formatNum(stats.totalTokens),
                  CupertinoIcons.chart_pie,
                  const Color(0xFFFF9500),
                  theme,
                  colorScheme,
                  'In: ${_formatNum(stats.inputToken)}',
                ),
                _buildStatItem(
                  loc.t('success_rate'),
                  '${(stats.successRate * 100).toStringAsFixed(1)}%',
                  CupertinoIcons.arrow_up_circle,
                  const Color(0xFFAF52DE),
                  theme,
                  colorScheme,
                  'Avg: ${_formatWaitTime(stats.waitTime, loc)}',
                ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLow(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                label,
                style: theme.textTheme.caption?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
            Text(subtitle, style: theme.textTheme.caption),
          ],
        ],
      ),
    );
  }

  String _formatWaitTime(int ms, AppLocalizations loc) {
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${(ms / 60000).toStringAsFixed(1)}m';
  }

  Widget _buildDailyChart(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    final data = _daily.reversed.toList();

    return SliverToBoxAdapter(
      child: AppSectionCard(
        title: loc.t('daily_chart'),
        subtitle: loc.t('daily_chart_subtitle'),
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
          0,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: SizedBox(
          height: 180,
          child: _buildCombinedDailyChart(data, loc, theme, colorScheme),
        ),
      ),
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

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxRequests > 0 ? maxRequests / 3 : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                _formatNum(v.toInt()),
                style: TextStyle(color: const Color(0xFF007AFF), fontSize: 9),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                _formatCurrencyCompact(v.toInt()),
                style: TextStyle(color: const Color(0xFF34C759), fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final date = data[i].date;
                return Text(
                  date.length >= 5 ? date.substring(5) : date,
                  style: const TextStyle(fontSize: 9),
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
            color: const Color(0xFF007AFF),
            barWidth: 2.5,
            dotData: FlDotData(
              show: data.length <= 5,
              getDotPainter: (spot, xPercent, bar, index) => FlDotCirclePainter(
                radius: 2,
                color: const Color(0xFF007AFF),
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF007AFF).withValues(alpha: 0.06),
            ),
          ),
          LineChartBarData(
            spots: maxCost > 0
                ? data
                      .asMap()
                      .entries
                      .map(
                        (e) => FlSpot(
                          e.key.toDouble(),
                          maxRequests > 0
                              ? (e.value.metrics.totalCost / maxCost) *
                                    maxRequests
                              : 0,
                        ),
                      )
                      .toList()
                : data.map((e) => FlSpot(0, 0)).toList(),
            isCurved: true,
            color: const Color(0xFF34C759),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF34C759).withValues(alpha: 0.06),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              if (s.barIndex == 0) {
                final i = s.x.toInt();
                final count = i >= 0 && i < data.length
                    ? data[i].metrics.requestSuccess +
                          data[i].metrics.requestFailed
                    : 0;
                return LineTooltipItem(
                  '${loc.t('daily_requests')}: $count',
                  const TextStyle(color: Color(0xFF007AFF), fontSize: 11),
                );
              }
              final i = s.x.toInt();
              final cost = i >= 0 && i < data.length
                  ? data[i].metrics.totalCost
                  : 0.0;
              return LineTooltipItem(
                '${loc.t('daily_cost')}: ${_formatCurrency(cost)}',
                const TextStyle(color: Color(0xFF34C759), fontSize: 11),
              );
            }).toList(),
          ),
        ),
      ),
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

    final tokenPreview = tokenRanking.take(previewCount).toList();
    final requestPreview = requestRanking.take(previewCount).toList();
    final apiKeyPreview = apiKeyRanking.take(previewCount).toList();

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
                    ),
                  ),
                ),
                Text(loc.t('ranking_subtitle'), style: theme.textTheme.caption),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildRankingCard(
              loc.t('token_consumption_ranking'),
              tokenPreview,
              tokenRanking.length > previewCount,
              CupertinoIcons.flame,
              const Color(0xFFFF9500),
              theme,
              colorScheme,
              loc,
              (item) {
                if (item is Channel) {
                  return _buildChannelRankingTile(
                    item,
                    theme,
                    colorScheme,
                    item.stats!,
                    'token',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _buildRankingCard(
              loc.t('request_activity_ranking'),
              requestPreview,
              requestRanking.length > previewCount,
              CupertinoIcons.arrow_up_circle,
              const Color(0xFF007AFF),
              theme,
              colorScheme,
              loc,
              (item) {
                if (item is Channel) {
                  return _buildChannelRankingTile(
                    item,
                    theme,
                    colorScheme,
                    item.stats!,
                    'request',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _buildRankingCard(
              loc.t('key_usage_ranking'),
              apiKeyPreview,
              apiKeyRanking.length > previewCount,
              CupertinoIcons.tag,
              const Color(0xFFAF52DE),
              theme,
              colorScheme,
              loc,
              (item) => _buildApiKeyRankingTile(
                item as StatsAPIKeyEntry,
                theme,
                colorScheme,
                loc,
              ),
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
    IconData icon,
    Color accentColor,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
    Widget Function(dynamic) itemBuilder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceLow(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Icon(icon, size: 14, color: accentColor),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  title,
                  style: theme.textTheme.footnote?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Center(
                child: Text(loc.t('no_data'), style: theme.textTheme.caption),
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
                  itemBuilder(item),
                ],
              );
            }),
          if (hasMore && !_rankingExpanded)
            GestureDetector(
              onTap: () => setState(() => _rankingExpanded = true),
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
                        loc.t('show_more'),
                        style: theme.textTheme.footnote?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
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
  ) {
    String value;
    Color valueColor;
    if (type == 'token') {
      value = _formatNum(stats.inputToken + stats.outputToken);
      valueColor = const Color(0xFFFF9500);
    } else {
      value = _formatNum(stats.requestSuccess + stats.requestFailed);
      valueColor = const Color(0xFF007AFF);
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
          _buildRankBadge(channel.id % 100),
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
                  '${(successRate * 100).toStringAsFixed(0)}% success',
                  style: theme.textTheme.caption,
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
          _buildRankBadge(entry.apiKeyId % 100),
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
                  style: theme.textTheme.caption,
                ),
              ],
            ),
          ),
          Text(
            _formatNum(totalRequests),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFAF52DE),
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
          color: const Color(0xFFFF9500).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Icon(
          CupertinoIcons.star_fill,
          size: 12,
          color: Color(0xFFFF9500),
        ),
      );
    }
    if (rank == 2) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF8E8E93).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Icon(
          CupertinoIcons.star_fill,
          size: 12,
          color: Color(0xFF8E8E93),
        ),
      );
    }
    if (rank == 3) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFFAF52DE).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Icon(
          CupertinoIcons.star_fill,
          size: 12,
          color: Color(0xFFAF52DE),
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
