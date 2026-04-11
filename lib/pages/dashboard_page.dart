import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/stats.dart';
import 'package:octopusmanage/widgets/stats_card.dart';
import 'package:provider/provider.dart';
import 'package:octopusmanage/providers/app_provider.dart';

enum _RankSortMode { cost, count, tokens, keyUsage }

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
  _RankSortMode _rankSortMode = _RankSortMode.cost;

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
      ]);
      if (mounted) {
        setState(() {
          _today = results[0] as StatsMetrics;
          _total = results[1] as StatsMetrics;
          _daily = results[2] as List<StatsDaily>;
          _apiKeyStats = results[3] as List<StatsAPIKeyEntry>;
          _channels = results[4] as List<Channel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final outlineColor = Theme.of(context).colorScheme.outlineVariant;
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(loc.t('dashboard')),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AppProvider>().logout(),
              ),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildStatsCard(outlineColor, loc),
            if (_daily.isNotEmpty) _buildDailyChartCard(outlineColor, loc),
            _buildRankingCard(outlineColor, loc),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(Color outlineColor, AppLocalizations loc) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: outlineColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(loc.t('today'))),
                    ButtonSegment(value: false, label: Text(loc.t('total'))),
                  ],
                  selected: {_showToday},
                  onSelectionChanged: (v) => setState(() => _showToday = v.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildStatsGrid(
                  _showToday ? (_today ?? StatsMetrics()) : (_total ?? StatsMetrics()),
                  loc,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyChartCard(Color outlineColor, AppLocalizations loc) {
    final data = _daily.reversed.toList();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: outlineColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Text(
                      loc.t('daily_chart'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Legend
                    _buildLegend(Colors.blue, loc.t('daily_requests')),
                    const SizedBox(width: 12),
                    _buildLegend(Colors.green, loc.t('daily_cost')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: _buildCombinedDailyChart(data, loc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildCombinedDailyChart(List<StatsDaily> data, AppLocalizations loc) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Find max values for dual-axis scaling
    double maxRequests = 0;
    double maxCost = 0;
    for (final d in data) {
      final r = d.metrics.requestSuccess.toDouble() + d.metrics.requestFailed.toDouble();
      if (r > maxRequests) maxRequests = r;
      if (d.metrics.totalCost > maxCost) maxCost = d.metrics.totalCost;
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(_formatNum(v.toInt()), style: const TextStyle(fontSize: 10, color: Colors.blue)),
                ),
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('\$${v.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.green)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  final d = data[i].date;
                  return Text(d.length >= 5 ? d.substring(5) : d, style: const TextStyle(fontSize: 10));
                },
                interval: data.length > 7 ? (data.length / 7).ceilToDouble() : 1,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Requests line (left axis)
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.metrics.requestSuccess.toDouble() + e.value.metrics.requestFailed.toDouble())).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.08)),
            ),
            // Cost line (right axis, scaled to left axis range)
            LineChartBarData(
              spots: maxCost > 0
                  ? data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), maxRequests > 0 ? (e.value.metrics.totalCost / maxCost) * maxRequests : 0)).toList()
                  : data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), 0)).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.08)),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                if (s.barIndex == 0) {
                  final i = s.x.toInt();
                  final count = i >= 0 && i < data.length ? (data[i].metrics.requestSuccess + data[i].metrics.requestFailed) : 0;
                  return LineTooltipItem(
                    '${loc.t('daily_requests')}: $count',
                    const TextStyle(color: Colors.blue, fontSize: 12),
                  );
                } else {
                  final i = s.x.toInt();
                  final cost = i >= 0 && i < data.length ? data[i].metrics.totalCost : 0.0;
                  return LineTooltipItem(
                    '${loc.t('daily_cost')}: \$${cost.toStringAsFixed(4)}',
                    const TextStyle(color: Colors.green, fontSize: 12),
                  );
                }
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingCard(Color outlineColor, AppLocalizations loc) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: outlineColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      loc.t('ranking'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    SegmentedButton<_RankSortMode>(
                      segments: [
                        ButtonSegment(value: _RankSortMode.cost, label: Text(loc.t('sort_by_cost'), style: const TextStyle(fontSize: 11))),
                        ButtonSegment(value: _RankSortMode.count, label: Text(loc.t('sort_by_count'), style: const TextStyle(fontSize: 11))),
                        ButtonSegment(value: _RankSortMode.tokens, label: Text(loc.t('sort_by_tokens'), style: const TextStyle(fontSize: 11))),
                        ButtonSegment(value: _RankSortMode.keyUsage, label: Text(loc.t('sort_by_key_usage'), style: const TextStyle(fontSize: 11))),
                      ],
                      selected: {_rankSortMode},
                      onSelectionChanged: (v) => setState(() => _rankSortMode = v.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
                      ),
                    ),
                  ],
                ),
              ),
              _buildRankingList(loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingList(AppLocalizations loc) {
    switch (_rankSortMode) {
      case _RankSortMode.cost:
        return _buildChannelRanking(loc, _channelsWithStats.toList()
          ..sort((a, b) => (b.stats!.inputCost + b.stats!.outputCost).compareTo(a.stats!.inputCost + a.stats!.outputCost)));
      case _RankSortMode.count:
        return _buildChannelRanking(loc, _channelsWithStats.toList()
          ..sort((a, b) => (b.stats!.requestSuccess + b.stats!.requestFailed).compareTo(a.stats!.requestSuccess + a.stats!.requestFailed)));
      case _RankSortMode.tokens:
        return _buildChannelRanking(loc, _channelsWithStats.toList()
          ..sort((a, b) => (b.stats!.inputToken + b.stats!.outputToken).compareTo(a.stats!.inputToken + a.stats!.outputToken)));
      case _RankSortMode.keyUsage:
        return _buildAPIKeyRanking(loc);
    }
  }

  Iterable<Channel> get _channelsWithStats sync* {
    for (final c in _channels) {
      if (c.stats != null) yield c;
    }
  }

  Widget _buildChannelRanking(AppLocalizations loc, List<Channel> channels) {
    if (channels.isEmpty) {
      return _buildEmptyRanking(loc);
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final channel = channels[index];
        final stats = channel.stats!;
        final rank = index + 1;
        final successRate = (stats.requestSuccess + stats.requestFailed) > 0
            ? stats.requestSuccess / (stats.requestSuccess + stats.requestFailed)
            : 0.0;

        String valueText;
        if (_rankSortMode == _RankSortMode.cost) {
          valueText = '\$${(stats.inputCost + stats.outputCost).toStringAsFixed(4)}';
        } else if (_rankSortMode == _RankSortMode.count) {
          valueText = _formatNum(stats.requestSuccess + stats.requestFailed);
        } else {
          valueText = _formatNum(stats.inputToken + stats.outputToken);
        }

        return ListTile(
          dense: true,
          leading: _buildRankBadge(rank),
          title: Text(channel.name, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${loc.t('success_rate_label')}: ${(successRate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: Text(
            valueText,
            style: TextStyle(
              color: _rankSortMode == _RankSortMode.cost ? Colors.green : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAPIKeyRanking(AppLocalizations loc) {
    final sorted = List<StatsAPIKeyEntry>.from(_apiKeyStats)
      ..sort((a, b) => (b.metrics.requestSuccess + b.metrics.requestFailed)
          .compareTo(a.metrics.requestSuccess + a.metrics.requestFailed));

    if (sorted.isEmpty) {
      return _buildEmptyRanking(loc);
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = sorted[index];
        final m = entry.metrics;
        final rank = index + 1;
        final successRate = (m.requestSuccess + m.requestFailed) > 0
            ? m.requestSuccess / (m.requestSuccess + m.requestFailed)
            : 0.0;

        return ListTile(
          dense: true,
          leading: _buildRankBadge(rank),
          title: Text('Key #${entry.apiKeyId}', style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${loc.t('success_rate_label')}: ${(successRate * 100).toStringAsFixed(1)}% | ${loc.t('cost')}: \$${m.totalCost.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: Text(
            _formatNum(m.requestSuccess + m.requestFailed),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyRanking(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(loc.t('no_data'), style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    if (rank == 1) {
      color = Colors.amber;
    } else if (rank == 2) {
      color = Colors.grey.shade400;
    } else if (rank == 3) {
      color = Colors.brown.shade300;
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text('$rank', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(Icons.emoji_events, size: 18, color: color),
    );
  }

  Widget _buildStatsGrid(StatsMetrics stats, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
        children: [
          StatsCard(
            title: loc.t('requests'),
            value: _formatNum(stats.requestSuccess + stats.requestFailed),
            subtitle: '${loc.t('success')}: ${_formatNum(stats.requestSuccess)} | ${loc.t('failed')}: ${_formatNum(stats.requestFailed)}',
            icon: Icons.send,
            color: Colors.blue,
          ),
          StatsCard(
            title: loc.t('cost'),
            value: '\$${stats.totalCost.toStringAsFixed(4)}',
            subtitle: 'In: \$${stats.inputCost.toStringAsFixed(4)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          StatsCard(
            title: loc.t('tokens'),
            value: _formatNum(stats.totalTokens),
            subtitle: 'In: ${_formatNum(stats.inputToken)}',
            icon: Icons.data_usage,
            color: Colors.orange,
          ),
          StatsCard(
            title: loc.t('success_rate'),
            value: '${(stats.successRate * 100).toStringAsFixed(1)}%',
            subtitle: '${loc.t('avg_wait')}: ${stats.waitTime}ms',
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
