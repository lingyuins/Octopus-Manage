import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/relay_log.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final List<RelayLog> _logs = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      final logs = await api.getLogs(page: _page, pageSize: 20);
      if (mounted) {
        setState(() {
          if (refresh) _logs.clear();
          _logs.addAll(logs);
          _hasMore = logs.length >= 20;
          _page++;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearLogs(AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.t('clear_logs')),
        content: Text(loc.t('clear_logs_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              loc.t('clear'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.clearLogs();
      _loadLogs(refresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(loc.t('logs')),
          floating: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _clearLogs(loc),
            ),
          ],
        ),
        if (_loading && _logs.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_logs.isEmpty)
          SliverFillRemaining(child: Center(child: Text(loc.t('no_logs'))))
        else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final log = _logs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    log.hasError ? Icons.error : Icons.check_circle,
                    color: log.hasError ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.requestModelName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '\$${log.cost.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${log.channelName} | ${log.inputTokens}+${log.outputTokens}tok | ${log.useTime}ms',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  trailing: Text(
                    _formatTime(log.time),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ),
              );
            }, childCount: _logs.length),
          ),
          if (_hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          _loadLogs();
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.t('load_more')),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
