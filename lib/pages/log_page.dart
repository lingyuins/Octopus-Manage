import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/relay_log.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final List<RelayLog> _logs = [];
  bool _loading = true;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (refresh) {
      // 先重置状态，再 setState，避免快速双击时状态不一致
      _page = 1;
      _hasMore = true;
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      if (refresh) _logs.clear(); // 刷新时先清空，给用户即时反馈
    });
    try {
      final api = context.read<AppProvider>().api;
      final currentPage = _page; // 记录当前请求的页码
      final logs = await api.getLogs(page: currentPage, pageSize: 20);
      if (mounted) {
        setState(() {
          // 如果期间已被另一次刷新重置，则丢弃过期结果
          if (!refresh && _page != currentPage) return;
          _logs.addAll(logs);
          _hasMore = logs.length >= 20;
          _page = currentPage + 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _clearLogs(AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('clear_logs'),
      content: loc.t('clear_logs_confirm'),
      confirmText: loc.t('clear'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed) return;
    try {
      if (!mounted) return;
      final api = context.read<AppProvider>().api;
      await api.clearLogs();
      _loadLogs(refresh: true);
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
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
              largeTitle: Text(loc.t('logs')),
              backgroundColor: AppTheme.getSurfaceLowest(
                colorScheme,
              ).withValues(alpha: 0.85),
              border: null,
              trailing: GestureDetector(
                onTap: () => _clearLogs(loc),
                child: Icon(
                  CupertinoIcons.trash,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () => _loadLogs(refresh: true),
            ),
            if (_loading && _logs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingState(),
              )
            else if (_errorMessage != null && _logs.isEmpty)
              SliverFillRemaining(
                child: AppErrorState(
                  message: _errorMessage!,
                  onRetry: () => _loadLogs(refresh: true),
                ),
              )
            else if (_logs.isEmpty)
              SliverFillRemaining(
                child: AppEmptyState(
                  icon: CupertinoIcons.doc_text,
                  title: loc.t('no_logs'),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final log = _logs[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      borderRadius: AppTheme.radiusLarge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: log.hasError
                                      ? colorScheme.error.withValues(alpha: 0.1)
                                      : AppTheme.colorGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                                child: Icon(
                                  log.hasError
                                      ? CupertinoIcons.xmark_circle_fill
                                      : CupertinoIcons.checkmark_circle_fill,
                                  color: log.hasError
                                      ? colorScheme.error
                                      : AppTheme.colorGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.requestModelName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      log.channelName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${log.cost.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(log.time),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Divider(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Row(
                            children: [
                              AppInfoChip(
                                icon: CupertinoIcons.arrow_up,
                                label: '${log.inputTokens}',
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              AppInfoChip(
                                icon: CupertinoIcons.arrow_down,
                                label: '${log.outputTokens}',
                              ),
                              const Spacer(),
                              AppInfoChip(
                                icon: CupertinoIcons.clock,
                                label: '${log.useTime}ms',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }, childCount: _logs.length),
                ),
              ),
              if (_hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: CupertinoButton(
                      onPressed: _loading ? null : () => _loadLogs(),
                      child: _loading
                          ? const CupertinoActivityIndicator(radius: 12)
                          : Text(loc.t('load_more')),
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
            ],
          ],
        ),
      ),
    );
  }
}
