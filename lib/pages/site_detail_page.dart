import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/site.dart';
import 'package:octopusmanage/pages/site_channel_page.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class SiteDetailPage extends StatefulWidget {
  final Site site;

  const SiteDetailPage({super.key, required this.site});

  @override
  State<SiteDetailPage> createState() => _SiteDetailPageState();
}

class _SiteDetailPageState extends State<SiteDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Site _site;
  List<SiteAccount> _accounts = [];
  List<SiteToken> _tokens = [];
  List<SiteModel> _models = [];
  List<CheckInRecord> _checkInHistory = [];
  List<RedemptionRecord> _redemptionHistory = [];
  final Map<int, BalanceSnapshot> _balances = {};
  final Map<int, BalancePrediction> _predictions = {};
  bool _loadingAccounts = false;
  bool _loadingTokens = false;
  bool _loadingModels = false;
  bool _syncing = false;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTabData(0);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _loadTabData(_tabController.index);
  }

  Future<void> _loadTabData(int index) async {
    if (!mounted) return;
    final api = context.read<AppProvider>().api;

    switch (index) {
      case 0:
        // Overview - refresh site data
        try {
          final updated = await api.getSite(_site.id);
          if (mounted) setState(() => _site = updated);
        } catch (_) {}
        break;
      case 1:
        if (_accounts.isNotEmpty) return;
        setState(() => _loadingAccounts = true);
        try {
          final data = await api.getSiteAccounts(_site.id);
          if (mounted) {
            setState(() => _accounts = data);
            _loadBalances();
          }
        } catch (e) {
          if (mounted) await showErrorDialog(context, e.toString());
        } finally {
          if (mounted) setState(() => _loadingAccounts = false);
        }
        break;
      case 2:
        if (_tokens.isNotEmpty) return;
        setState(() => _loadingTokens = true);
        try {
          final data = await api.getSiteTokens(_site.id);
          if (mounted) setState(() => _tokens = data);
        } catch (e) {
          if (mounted) await showErrorDialog(context, e.toString());
        } finally {
          if (mounted) setState(() => _loadingTokens = false);
        }
        break;
      case 3:
        if (_models.isNotEmpty) return;
        setState(() => _loadingModels = true);
        try {
          final data = await api.getSiteModels(_site.id);
          if (mounted) setState(() => _models = data);
        } catch (e) {
          if (mounted) await showErrorDialog(context, e.toString());
        } finally {
          if (mounted) setState(() => _loadingModels = false);
        }
        break;
      case 4:
        // Check-in / Redemption history
        if (_checkInHistory.isNotEmpty) return;
        try {
          final checkins = await api.getCheckInHistory(_site.id);
          final redeems = await api.getRedemptionHistory(_site.id);
          if (mounted) {
            setState(() {
              _checkInHistory = checkins;
              _redemptionHistory = redeems;
            });
          }
        } catch (e) {
          if (mounted) await showErrorDialog(context, e.toString());
        }
        break;
      case 5:
        // Balance - loaded on demand via accounts
        if (_accounts.isEmpty) {
          try {
            final data = await api.getSiteAccounts(_site.id);
            if (mounted) setState(() => _accounts = data);
          } catch (_) {}
        }
        _loadBalances();
        break;
    }
  }

  Future<void> _syncSite(AppLocalizations loc) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.syncSite(_site.id);
      final updated = await api.getSite(_site.id);
      if (mounted) {
        setState(() => _site = updated);
        // Reload current tab data
        _accounts = [];
        _tokens = [];
        _models = [];
        _checkInHistory = [];
        _redemptionHistory = [];
        _balances.clear();
        _predictions.clear();
        _loadTabData(_tabController.index);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _loadBalances() async {
    if (_accounts.isEmpty) return;
    final api = context.read<AppProvider>().api;
    for (final account in _accounts) {
      try {
        final balance = await api.getBalance(_site.id, account.id);
        if (mounted) {
          setState(() => _balances[account.id] = balance);
        }
      } catch (_) {}
      try {
        final prediction =
            await api.getBalancePrediction(_site.id, account.id);
        if (mounted) {
          setState(() => _predictions[account.id] = prediction);
        }
      } catch (_) {}
    }
  }

  Future<void> _checkInAccount(SiteAccount account, AppLocalizations loc) async {
    if (_checkingIn) return;
    setState(() => _checkingIn = true);
    try {
      final api = context.read<AppProvider>().api;
      final record = await api.checkInSite(_site.id, account.id);
      if (mounted) {
        if (record.status == 'already_checked') {
          _showMessage(loc.t('site_already_checked'));
        } else {
          final rewardText = record.reward != null
              ? ' +${record.reward!.toStringAsFixed(2)} ${record.rewardType ?? ''}'
              : '';
          _showMessage('${loc.t('site_checkin_success')}$rewardText');
        }
        // Refresh check-in history
        _checkInHistory = [];
        _loadTabData(4);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  void _showMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(context.read<AppProvider>().loc.t('ok')),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _showRedeemDialog(AppLocalizations loc) async {
    final codeCtl = TextEditingController();
    int? selectedAccountId;
    if (_accounts.isNotEmpty) {
      selectedAccountId = _accounts.first.id;
    }

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: Text(loc.t('site_redeem')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: codeCtl,
                placeholder: loc.t('site_redeem_code_hint'),
                autocorrect: false,
              ),
              if (_accounts.length > 1) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5.resolveFrom(ctx),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedAccountId,
                      isExpanded: true,
                      items: _accounts
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name, style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedAccountId = v),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(loc.t('cancel')),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(loc.t('site_redeem')),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;
    final code = codeCtl.text.trim();
    if (code.isEmpty || selectedAccountId == null) return;

    try {
      final api = context.read<AppProvider>().api;
      final record = await api.redeemCode(_site.id, selectedAccountId!, code);
      if (mounted) {
        String msg;
        switch (record.status) {
          case 'success':
            msg = '${loc.t('site_redeem_success')}${record.value != null ? ' +${record.value}' : ''}';
            break;
          case 'expired':
            msg = loc.t('site_redeem_expired');
            break;
          default:
            msg = loc.t('site_redeem_failed');
        }
        _showMessage(msg);
        _redemptionHistory = [];
        _loadTabData(4);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.colorGreen;
      case 'inactive':
        return AppTheme.colorGray;
      case 'error':
        return AppTheme.colorRed;
      case 'archived':
        return AppTheme.colorOrange;
      default:
        return AppTheme.colorGray;
    }
  }

  String _statusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case 'active':
        return loc.t('site_status_active');
      case 'inactive':
        return loc.t('site_status_inactive');
      case 'error':
        return loc.t('site_status_error');
      case 'archived':
        return loc.t('site_status_archived');
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.getSurfaceLowest(colorScheme),
      child: SafeArea(
        child: Column(
          children: [
            // Header
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
                    child: Icon(
                      CupertinoIcons.back,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _site.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            AppTypeChip(
                              label: _site.platform.toUpperCase(),
                              color: AppTheme.colorBlue,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            AppTypeChip(
                              label: _statusLabel(_site.status, loc),
                              color: _statusColor(_site.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _syncing ? null : () => _syncSite(loc),
                    child: _syncing
                        ? const CupertinoActivityIndicator(radius: 10)
                        : Icon(
                            CupertinoIcons.refresh,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceLow(colorScheme),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                tabs: [
                  Tab(text: loc.t('overview')),
                  Tab(text: loc.t('site_accounts')),
                  Tab(text: loc.t('site_tokens')),
                  Tab(text: loc.t('site_models')),
                  Tab(text: loc.t('site_checkin_history')),
                  Tab(text: loc.t('site_balance')),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(loc, colorScheme),
                  _buildAccountsTab(loc, colorScheme),
                  _buildTokensTab(loc, colorScheme),
                  _buildModelsTab(loc, colorScheme),
                  _buildHistoryTab(loc, colorScheme),
                  _buildBalanceTab(loc, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(AppLocalizations loc, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      children: [
        _InfoCard(
          title: loc.t('overview'),
          children: [
            _InfoRow(label: loc.t('site_name'), value: _site.name),
            _InfoRow(label: loc.t('site_platform'), value: _site.platform),
            _InfoRow(label: loc.t('site_base_url'), value: _site.baseUrl),
            _InfoRow(label: loc.t('site_auth_type'), value: _site.authType),
            _InfoRow(
              label: loc.t('enabled'),
              value: _site.enabled ? loc.t('enabled') : loc.t('disabled'),
            ),
            if (_site.proxyEnabled)
              _InfoRow(label: loc.t('site_proxy_url'), value: _site.proxyUrl ?? loc.t('not_set')),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLg),
        _InfoCard(
          title: loc.t('dashboard'),
          children: [
            _InfoRow(
              label: loc.t('site_channel_count'),
              value: '${_site.channelCount}',
            ),
            _InfoRow(
              label: loc.t('site_model_count'),
              value: '${_site.modelCount}',
            ),
            _InfoRow(
              label: loc.t('site_total_cost'),
              value: _site.totalCost.toStringAsFixed(2),
            ),
            _InfoRow(
              label: loc.t('site_total_requests'),
              value: '${_site.totalRequests}',
            ),
            _InfoRow(
              label: loc.t('site_success_rate'),
              value: '${(_site.successRate * 100).toStringAsFixed(1)}%',
            ),
            _InfoRow(
              label: loc.t('site_last_sync'),
              value: _site.lastSyncAt > 0
                  ? DateTime.fromMillisecondsSinceEpoch(
                      _site.lastSyncAt * 1000,
                    ).toString()
                  : loc.t('never'),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: colorScheme.secondaryContainer,
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => SiteChannelPage(
                      siteId: _site.id,
                      siteName: _site.name,
                    ),
                  ),
                ),
                child: Text(
                  loc.t('site_channel_projection'),
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
              ),
            ),
          ],
        ),
        if (_site.status == 'error' && _site.errorMessage != null) ...[
          const SizedBox(height: AppTheme.spacingLg),
          _InfoCard(
            title: loc.t('site_error_message'),
            children: [
              Text(
                _site.errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppTheme.spacingLg),
        _InfoCard(
          title: loc.t('settings'),
          children: [
            _InfoRow(
              label: loc.t('site_oauth_client_id'),
              value: _site.oauthClientId ?? loc.t('not_set'),
            ),
            _InfoRow(
              label: loc.t('site_oauth_token_url'),
              value: _site.oauthTokenUrl ?? loc.t('not_set'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountsTab(AppLocalizations loc, ColorScheme colorScheme) {
    if (_loadingAccounts) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_accounts.isEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.person_2,
        title: loc.t('no_data'),
        subtitle: loc.t('site_accounts'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  AppTypeChip(
                    label: account.status,
                    color: account.status == 'active'
                        ? AppTheme.colorGreen
                        : AppTheme.colorGray,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    color: colorScheme.primary,
                    onPressed: _checkingIn
                        ? null
                        : () => _checkInAccount(account, loc),
                    child: _checkingIn
                        ? const CupertinoActivityIndicator(
                            radius: 8, color: Colors.white)
                        : Text(
                            loc.t('site_checkin'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _InfoRow(label: loc.t('username'), value: account.email),
              if (account.plan != null)
                _InfoRow(
                    label: loc.t('site_account_plan'), value: account.plan!),
              _InfoRow(
                label: loc.t('site_account_balance'),
                value: account.balance.toStringAsFixed(2),
              ),
              _InfoRow(
                label: loc.t('site_account_total_spent'),
                value: account.totalSpent.toStringAsFixed(2),
              ),
              _InfoRow(
                label: loc.t('site_account_requests_used'),
                value: '${account.requestsUsed} / ${account.requestLimit}',
              ),
              if (_predictions.containsKey(account.id)) ...[
                const Divider(height: 16),
                _InfoRow(
                  label: loc.t('site_daily_average'),
                  value: _predictions[account.id]!.dailyAverage.toStringAsFixed(4),
                ),
                _InfoRow(
                  label: loc.t('site_days_remaining'),
                  value: '${_predictions[account.id]!.estimatedDaysRemaining}',
                  valueColor: _predictions[account.id]!.estimatedDaysRemaining < 7
                      ? AppTheme.colorRed
                      : _predictions[account.id]!.estimatedDaysRemaining < 30
                          ? AppTheme.colorOrange
                          : null,
                ),
                if (_predictions[account.id]!.recommendation != null)
                  _InfoRow(
                    label: loc.t('site_recommendation'),
                    value: _predictions[account.id]!.recommendation!,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTokensTab(AppLocalizations loc, ColorScheme colorScheme) {
    if (_loadingTokens) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_tokens.isEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.lock,
        title: loc.t('no_data'),
        subtitle: loc.t('site_tokens'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      itemCount: _tokens.length,
      itemBuilder: (context, index) {
        final token = _tokens[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      token.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: token.enabled,
                    onChanged: null, // Read-only in detail view
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _InfoRow(
                label: loc.t('site_token_masked'),
                value: token.tokenMasked,
              ),
              _InfoRow(
                label: loc.t('site_token_expires'),
                value: token.expiresAt > 0
                    ? DateTime.fromMillisecondsSinceEpoch(
                        token.expiresAt * 1000,
                      ).toString()
                    : loc.t('never'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelsTab(AppLocalizations loc, ColorScheme colorScheme) {
    if (_loadingModels) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_models.isEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.cube_box,
        title: loc.t('no_data'),
        subtitle: loc.t('site_models'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      itemCount: _models.length,
      itemBuilder: (context, index) {
        final model = _models[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.modelName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  AppTypeChip(
                    label: model.provider,
                    color: AppTheme.colorBlue,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _InfoRow(
                label: loc.t('site_model_input_price'),
                value: model.inputPrice.toStringAsFixed(6),
              ),
              _InfoRow(
                label: loc.t('site_model_output_price'),
                value: model.outputPrice.toStringAsFixed(6),
              ),
              _InfoRow(
                label: loc.t('site_model_context_window'),
                value: '${model.contextWindow}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(AppLocalizations loc, ColorScheme colorScheme) {
    if (_checkInHistory.isEmpty && _redemptionHistory.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          // Redeem button at top
          AppCard(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showRedeemDialog(loc),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.gift, color: colorScheme.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    loc.t('site_redeem'),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppEmptyState(
            icon: CupertinoIcons.clock,
            title: loc.t('no_data'),
            subtitle: '${loc.t('site_checkin_history')} / ${loc.t('site_redemption_history')}',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      children: [
        // Redeem button
        AppCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showRedeemDialog(loc),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.gift, color: colorScheme.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  loc.t('site_redeem'),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Check-in history
        if (_checkInHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: Text(
              loc.t('site_checkin_history'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ...(_checkInHistory.map(
            (record) => AppCard(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Icon(
                    record.status == 'success'
                        ? CupertinoIcons.checkmark_circle_fill
                        : record.status == 'already_checked'
                            ? CupertinoIcons.clock_fill
                            : CupertinoIcons.xmark_circle_fill,
                    size: 20,
                    color: record.status == 'success'
                        ? AppTheme.colorGreen
                        : record.status == 'already_checked'
                            ? AppTheme.colorOrange
                            : AppTheme.colorRed,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.status == 'success'
                              ? loc.t('site_checkin_success')
                              : record.status == 'already_checked'
                                  ? loc.t('site_already_checked')
                                  : loc.t('site_checkin_failed'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (record.reward != null)
                          Text(
                            '${loc.t('site_checkin_reward')}: +${record.reward!.toStringAsFixed(2)} ${record.rewardType ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.colorGreen,
                            ),
                          ),
                        if (record.message != null)
                          Text(
                            record.message!,
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
                  Text(
                    record.checkedAt,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: AppTheme.spacingLg),
        ],
        // Redemption history
        if (_redemptionHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: Text(
              loc.t('site_redemption_history'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ...(_redemptionHistory.map(
            (record) => AppCard(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Icon(
                    record.status == 'success'
                        ? CupertinoIcons.checkmark_circle_fill
                        : record.status == 'expired'
                            ? CupertinoIcons.clock_fill
                            : CupertinoIcons.xmark_circle_fill,
                    size: 20,
                    color: record.status == 'success'
                        ? AppTheme.colorGreen
                        : record.status == 'expired'
                            ? AppTheme.colorOrange
                            : AppTheme.colorRed,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (record.value != null)
                          Text(
                            '${loc.t('site_redeem_value')}: ${record.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.colorGreen,
                            ),
                          ),
                        if (record.description != null)
                          Text(
                            record.description!,
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
                  Text(
                    record.redeemedAt,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildBalanceTab(AppLocalizations loc, ColorScheme colorScheme) {
    if (_accounts.isEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.money_dollar,
        title: loc.t('no_data'),
        subtitle: loc.t('site_balance'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        final balance = _balances[account.id];
        final prediction = _predictions[account.id];
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (prediction != null)
                    AppTypeChip(
                      label:
                          '${prediction.estimatedDaysRemaining} ${loc.t('site_days_remaining')}',
                      color: prediction.estimatedDaysRemaining < 7
                          ? AppTheme.colorRed
                          : prediction.estimatedDaysRemaining < 30
                              ? AppTheme.colorOrange
                              : AppTheme.colorGreen,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _InfoRow(
                label: loc.t('site_balance'),
                value: (balance?.balance ?? account.balance).toStringAsFixed(2),
              ),
              if (balance?.dailyUsage != null)
                _InfoRow(
                  label: loc.t('site_daily_average'),
                  value: balance!.dailyUsage!.toStringAsFixed(4),
                ),
              if (balance?.weeklyUsage != null)
                _InfoRow(
                  label: loc.t('site_weekly_average'),
                  value: balance!.weeklyUsage!.toStringAsFixed(4),
                ),
              if (prediction != null) ...[
                const Divider(height: 16),
                Text(
                  loc.t('site_balance_prediction'),
                  style: Theme.of(context).textTheme.footnote?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _InfoRow(
                  label: loc.t('site_daily_average'),
                  value: prediction.dailyAverage.toStringAsFixed(4),
                ),
                _InfoRow(
                  label: loc.t('site_weekly_average'),
                  value: prediction.weeklyAverage.toStringAsFixed(4),
                ),
                _InfoRow(
                  label: loc.t('site_days_remaining'),
                  value: '${prediction.estimatedDaysRemaining}',
                  valueColor: prediction.estimatedDaysRemaining < 7
                      ? AppTheme.colorRed
                      : prediction.estimatedDaysRemaining < 30
                          ? AppTheme.colorOrange
                          : null,
                ),
                if (prediction.recommendation != null)
                  _InfoRow(
                    label: loc.t('site_recommendation'),
                    value: prediction.recommendation!,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.footnote?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.caption?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
