import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/models/setting.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:octopusmanage/widgets/app_list_tile.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  List<Setting> _settings = [];
  List<Group> _groups = [];
  bool _loading = true;
  String _version = '';
  String _latestVersion = '';
  String _lastSyncTime = '';
  String _lastModelUpdateTime = '';
  String? _updateError;
  String? _error;
  bool _exportIncludeLogs = false;
  bool _exportIncludeStats = false;
  bool _changingUsername = false;
  bool _changingPassword = false;
  bool _exporting = false;
  bool _importing = false;
  bool _updatingCore = false;
  bool _syncingLLM = false;
  bool _updatingPrices = false;
  bool _deletingGroups = false;
  bool _loggingOut = false;

  bool get _hasUpdate =>
      _latestVersion.isNotEmpty &&
      _version.isNotEmpty &&
      _latestVersion != _version;

  Map<String, Setting> get _settingsByKey => {
    for (final setting in _settings) setting.key: setting,
  };

  List<Setting> get _remainingSettings {
    const dedicatedKeys = {
      'model_info_update_interval',
      'sync_llm_interval',
      'relay_retry_count',
      'ratelimit_cooldown',
      'relay_max_total_attempts',
      'circuit_breaker_threshold',
      'circuit_breaker_cooldown',
      'circuit_breaker_max_cooldown',
      'auto_strategy_min_samples',
      'auto_strategy_time_window',
      'auto_strategy_sample_threshold',
      'ai_route_group_id',
      'ai_route_base_url',
      'ai_route_api_key',
      'ai_route_model',
      'ai_route_timeout_seconds',
      'ai_route_parallelism',
      'ai_route_services',
    };
    final settings =
        _settings
            .where((setting) => !dedicatedKeys.contains(setting.key))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return settings;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = null;
      _updateError = null;
    });

    try {
      final api = context.read<AppProvider>().api;
      final settingsFuture = api.getSettings();
      final groupsFuture = api.getGroups();
      final versionFuture = api.getCurrentVersion();
      final latestFuture = api.checkUpdate();
      final lastSyncFuture = api.getLastSyncTime();
      final lastUpdateFuture = api.getLastModelUpdateTime();

      final settings = await settingsFuture;
      final groups = await groupsFuture;
      final version = await versionFuture;

      String latestVersion = '';
      String? updateError;
      String lastSyncTime = '';
      String lastUpdateTime = '';
      try {
        final latest = await latestFuture;
        latestVersion = latest['tag_name']?.toString() ?? '';
      } catch (e) {
        updateError = e.toString();
      }
      try {
        lastSyncTime = await lastSyncFuture;
      } catch (_) {}
      try {
        lastUpdateTime = await lastUpdateFuture;
      } catch (_) {}

      if (!mounted) return;
      groups.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _settings = settings;
        _groups = groups;
        _version = version;
        _latestVersion = latestVersion;
        _lastSyncTime = lastSyncTime;
        _lastModelUpdateTime = lastUpdateTime;
        _updateError = updateError;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  bool _isBooleanSetting(String key) => key == 'relay_log_keep_enabled';

  Future<void> _toggleBoolSetting(Setting setting) async {
    final newValue = setting.value == 'true' ? 'false' : 'true';
    try {
      final api = context.read<AppProvider>().api;
      await api.setSetting(setting.key, newValue);
      await _loadSettings();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _editSetting(Setting setting, AppLocalizations loc) async {
    final controller = TextEditingController(text: setting.value);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(_settingLabel(setting.key, loc)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: loc.t('enter_value'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.brightness == Brightness.light
                  ? const Color(0xFFE5E5EA)
                  : const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('cancel')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(loc.t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      await api.setSetting(setting.key, result);
      await _loadSettings();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _changeUsername(AppLocalizations loc) async {
    final nextUsername = await AppInputDialog.show(
      context: context,
      title: loc.t('change_username'),
      hint: loc.t('new_username'),
      confirmText: loc.t('save'),
      cancelText: loc.t('cancel'),
    );
    final trimmed = nextUsername?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;

    setState(() => _changingUsername = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.changeUsername(trimmed);
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('change_username'),
        content: loc.t('username_updated'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
      if (!mounted) return;
      await context.read<AppProvider>().logout();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _changingUsername = false);
    }
  }

  Future<void> _changePassword(AppLocalizations loc) async {
    final payload = await showDialog<_PasswordChangeValue>(
      context: context,
      builder: (_) => _PasswordChangeDialog(loc: loc),
    );
    if (payload == null || !mounted) return;

    if (payload.newPassword != payload.confirmPassword) {
      await showErrorDialog(context, loc.t('password_mismatch'));
      return;
    }
    if (payload.oldPassword.isEmpty || payload.newPassword.isEmpty) {
      await showErrorDialog(context, loc.t('required'));
      return;
    }

    setState(() => _changingPassword = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.changePassword(payload.oldPassword, payload.newPassword);
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('change_password'),
        content: loc.t('password_updated'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
      if (!mounted) return;
      await context.read<AppProvider>().logout();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await context.read<AppProvider>().logout();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _exportData(AppLocalizations loc) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final api = context.read<AppProvider>().api;
      final jsonText = await api.exportSettings(
        includeLogs: _exportIncludeLogs,
        includeStats: _exportIncludeStats,
      );
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('export_success'),
        content: jsonText,
        buttonText: loc.t('ok'),
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importData(AppLocalizations loc) async {
    final jsonText = await AppInputDialog.show(
      context: context,
      title: loc.t('import_data'),
      hint: loc.t('paste_import_json'),
      confirmText: loc.t('import_data'),
      cancelText: loc.t('cancel'),
      maxLines: 12,
      keyboardType: TextInputType.multiline,
    );
    final trimmed = jsonText?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;

    setState(() => _importing = true);
    try {
      final api = context.read<AppProvider>().api;
      final result = await api.importSettings(trimmed);
      await _loadSettings();
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('import_success'),
        content: _formatImportResult(result),
        buttonText: loc.t('ok'),
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _updateCore(AppLocalizations loc) async {
    if (_updatingCore) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('update_now'),
      content: _hasUpdate
          ? '${loc.t('server_version')}: $_version\n${loc.t('latest_version')}: $_latestVersion'
          : loc.t('up_to_date'),
      confirmText: loc.t('update_now'),
      cancelText: loc.t('cancel'),
    );
    if (!confirmed || !mounted) return;

    setState(() => _updatingCore = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.updateCore();
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('update_now'),
        content: loc.t('update_started'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _updatingCore = false);
    }
  }

  String _formatImportResult(Map<String, dynamic> result) {
    final rowsAffected = result['rows_affected'];
    if (rowsAffected is Map<String, dynamic>) {
      final lines = rowsAffected.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return lines.map((entry) => '${entry.key}: ${entry.value}').join('\n');
    }
    return const JsonEncoder.withIndent('  ').convert(result);
  }

  String _settingValue(String key, [String fallback = '']) {
    return _settingsByKey[key]?.value ?? fallback;
  }

  void _upsertSetting(String key, String value) {
    final index = _settings.indexWhere((setting) => setting.key == key);
    if (index >= 0) {
      _settings[index] = Setting(key: key, value: value);
      return;
    }
    _settings.add(Setting(key: key, value: value));
  }

  Future<void> _setSettingValue(String key, String value) async {
    try {
      final api = context.read<AppProvider>().api;
      await api.setSetting(key, value);
      if (!mounted) return;
      setState(() => _upsertSetting(key, value));
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _editSettingValue({
    required String key,
    required String title,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool trim = true,
  }) async {
    final initialValue = _settingValue(key);
    final next = await AppInputDialog.show(
      context: context,
      title: title,
      hint: hint,
      initialValue: initialValue,
      confirmText: context.read<AppProvider>().loc.t('save'),
      cancelText: context.read<AppProvider>().loc.t('cancel'),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
    if (next == null || !mounted) return;
    final normalized = trim ? next.trim() : next;
    if (normalized == initialValue) return;
    await _setSettingValue(key, normalized);
  }

  Future<void> _editAIRouteServices(AppLocalizations loc) async {
    final initialValue = _settingValue('ai_route_services', '[]');
    final next = await AppInputDialog.show(
      context: context,
      title: loc.t('ai_route_services'),
      hint: loc.t('ai_route_services_hint'),
      initialValue: initialValue,
      confirmText: loc.t('save'),
      cancelText: loc.t('cancel'),
      keyboardType: TextInputType.multiline,
      maxLines: 12,
    );
    if (next == null || !mounted) return;

    final normalized = next.trim().isEmpty ? '[]' : next.trim();
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is! List) {
        throw const FormatException('Expected a JSON array');
      }
    } catch (_) {
      await showErrorDialog(context, loc.t('ai_route_services_invalid_json'));
      return;
    }

    if (normalized == initialValue) return;
    await _setSettingValue('ai_route_services', normalized);
  }

  Future<void> _chooseAIRouteGroup(AppLocalizations loc) async {
    await AppActionSheet.show(
      context: context,
      title: loc.t('ai_route_target_group'),
      actions: [
        AppActionItem(
          label: loc.t('not_set'),
          onTap: () => _setSettingValue('ai_route_group_id', '0'),
        ),
        ..._groups.map(
          (group) => AppActionItem(
            label: group.name,
            onTap: () => _setSettingValue('ai_route_group_id', '${group.id}'),
          ),
        ),
      ],
    );
  }

  Future<void> _syncLLMNow(AppLocalizations loc) async {
    if (_syncingLLM) return;
    setState(() => _syncingLLM = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.syncChannels();
      String lastSyncTime = _lastSyncTime;
      try {
        lastSyncTime = await api.getLastSyncTime();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _lastSyncTime = lastSyncTime);
      await AppTextDialog.show(
        context: context,
        title: loc.t('sync_channels'),
        content: loc.t('channel_sync_success'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _syncingLLM = false);
    }
  }

  Future<void> _updateLLMPriceNow(AppLocalizations loc) async {
    if (_updatingPrices) return;
    setState(() => _updatingPrices = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.updateModelPrice();
      String lastUpdateTime = _lastModelUpdateTime;
      try {
        lastUpdateTime = await api.getLastModelUpdateTime();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _lastModelUpdateTime = lastUpdateTime);
      await AppTextDialog.show(
        context: context,
        title: loc.t('sync_prices'),
        content: loc.t('model_price_sync_success'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _updatingPrices = false);
    }
  }

  Future<void> _deleteAllGroups(AppLocalizations loc) async {
    if (_deletingGroups) return;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete_all_groups'),
      content: loc.t('delete_all_groups_confirm', {
        'count': '${_groups.length}',
      }),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingGroups = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteAllGroups();
      if (_settingValue('ai_route_group_id', '0') != '0') {
        await api.setSetting('ai_route_group_id', '0');
        _upsertSetting('ai_route_group_id', '0');
      }
      await _loadSettings();
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('delete_all_groups'),
        content: loc.t('delete_all_groups_success'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _deletingGroups = false);
    }
  }

  String _formatDateTimeValue(String value, AppLocalizations loc) {
    if (value.trim().isEmpty) return loc.t('never');
    final parsed = DateTime.tryParse(value);
    if (parsed == null || parsed.year <= 1) return loc.t('never');
    final local = parsed.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final sec = local.second.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$min:$sec';
  }

  String _maskSecret(String value, AppLocalizations loc) {
    if (value.trim().isEmpty) return loc.t('empty');
    if (value.length <= 8) return '••••••';
    return '${value.substring(0, 4)}••••${value.substring(value.length - 4)}';
  }

  String _groupDisplayName(int id, AppLocalizations loc) {
    if (id <= 0) return loc.t('not_set');
    for (final group in _groups) {
      if (group.id == id) return group.name;
    }
    return '#$id';
  }

  String _servicesSummary(AppLocalizations loc) {
    final raw = _settingValue('ai_route_services', '[]').trim();
    if (raw.isEmpty || raw == '[]') return loc.t('empty');
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return loc.t('ai_route_services_count', {'count': '${decoded.length}'});
      }
    } catch (_) {}
    return loc.t('ai_route_services_invalid_json');
  }

  String _settingLabel(String key, AppLocalizations loc) {
    const keyMap = {
      'proxy_url': 'setting_proxy_url',
      'stats_save_interval': 'setting_stats_save_interval',
      'model_info_update_interval': 'setting_model_info_update_interval',
      'sync_llm_interval': 'setting_sync_llm_interval',
      'relay_log_keep_period': 'setting_relay_log_keep_period',
      'relay_log_keep_enabled': 'setting_relay_log_keep_enabled',
      'cors_allow_origins': 'setting_cors_allow_origins',
      'relay_retry_count': 'setting_relay_retry_count',
      'circuit_breaker_threshold': 'setting_circuit_breaker_threshold',
      'circuit_breaker_cooldown': 'setting_circuit_breaker_cooldown',
      'circuit_breaker_max_cooldown': 'setting_circuit_breaker_max_cooldown',
      'public_api_base_url': 'setting_public_api_base_url',
      'ratelimit_cooldown': 'setting_ratelimit_cooldown',
      'relay_max_total_attempts': 'setting_relay_max_total_attempts',
      'auto_strategy_min_samples': 'setting_auto_strategy_min_samples',
      'auto_strategy_time_window': 'setting_auto_strategy_time_window',
      'auto_strategy_sample_threshold':
          'setting_auto_strategy_sample_threshold',
      'ai_route_group_id': 'setting_ai_route_group_id',
      'ai_route_base_url': 'setting_ai_route_base_url',
      'ai_route_api_key': 'setting_ai_route_api_key',
      'ai_route_model': 'setting_ai_route_model',
      'ai_route_timeout_seconds': 'setting_ai_route_timeout_seconds',
      'ai_route_parallelism': 'setting_ai_route_parallelism',
      'ai_route_services': 'setting_ai_route_services',
    };
    return loc.t(keyMap[key] ?? key);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final loc = provider.loc;
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
              largeTitle: Text(loc.t('settings')),
              backgroundColor: AppTheme.getSurfaceLowest(
                colorScheme,
              ).withValues(alpha: 0.85),
              border: null,
            ),
            CupertinoSliverRefreshControl(onRefresh: _loadSettings),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingState(),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: AppErrorState(message: _error!, onRetry: _loadSettings),
              )
            else ...[
              SliverToBoxAdapter(
                child: _SettingsInfoCard(
                  version: _version,
                  latestVersion: _latestVersion,
                  updateError: _updateError,
                  hasUpdate: _hasUpdate,
                  onUpdate: () => _updateCore(loc),
                  updating: _updatingCore,
                  loc: loc,
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: CupertinoIcons.person_crop_circle,
                  title: loc.t('account_settings'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ActionRow(
                      title: loc.t('change_username'),
                      buttonLabel: loc.t('change_action'),
                      busy: _changingUsername,
                      onTap: () => _changeUsername(loc),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('change_password'),
                      buttonLabel: loc.t('change_action'),
                      busy: _changingPassword,
                      onTap: () => _changePassword(loc),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.tune,
                  title: loc.t('app_preferences'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _SwitchLine(
                      title: loc.t('auto_refresh'),
                      value: provider.autoRefreshEnabled,
                      onChanged: provider.setAutoRefreshEnabled,
                    ),
                    if (provider.autoRefreshEnabled) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        loc.t('refresh_interval'),
                        style: theme.textTheme.caption?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<int>(
                          groupValue: provider.autoRefreshIntervalSeconds,
                          onValueChanged: (value) {
                            if (value != null) {
                              provider.setAutoRefreshIntervalSeconds(value);
                            }
                          },
                          children: {
                            15: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text('15${loc.t('second')}'),
                            ),
                            30: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text('30${loc.t('second')}'),
                            ),
                            60: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text('60${loc.t('second')}'),
                            ),
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingMd),
                    _ActionRow(
                      title: loc.t('logout_action'),
                      subtitle: loc.t('logout_subtitle'),
                      buttonLabel: loc.t('logout_action'),
                      busy: _loggingOut,
                      onTap: _logout,
                      isDanger: true,
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: CupertinoIcons.arrow_2_circlepath,
                  title: loc.t('backup_restore'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _SwitchLine(
                      title: loc.t('include_logs'),
                      value: _exportIncludeLogs,
                      onChanged: (value) =>
                          setState(() => _exportIncludeLogs = value),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _SwitchLine(
                      title: loc.t('include_stats'),
                      value: _exportIncludeStats,
                      onChanged: (value) =>
                          setState(() => _exportIncludeStats = value),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: _exporting
                                ? null
                                : () => _exportData(loc),
                            child: _exporting
                                ? const CupertinoActivityIndicator()
                                : Text(loc.t('export_data')),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: colorScheme.secondaryContainer,
                            onPressed: _importing
                                ? null
                                : () => _importData(loc),
                            child: _importing
                                ? const CupertinoActivityIndicator()
                                : Text(
                                    loc.t('import_data'),
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.auto_awesome,
                  title: loc.t('ai_route_settings'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ValueActionRow(
                      title: loc.t('ai_route_target_group'),
                      value: _groupDisplayName(
                        int.tryParse(_settingValue('ai_route_group_id', '0')) ??
                            0,
                        loc,
                      ),
                      subtitle: loc.t('ai_route_target_group_hint'),
                      onTap: () => _chooseAIRouteGroup(loc),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('ai_route_base_url'),
                      value: _settingValue('ai_route_base_url', loc.t('empty')),
                      onTap: () => _editSettingValue(
                        key: 'ai_route_base_url',
                        title: loc.t('ai_route_base_url'),
                        hint: loc.t('base_url'),
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('ai_route_api_key'),
                      value: _maskSecret(
                        _settingValue('ai_route_api_key'),
                        loc,
                      ),
                      onTap: () => _editSettingValue(
                        key: 'ai_route_api_key',
                        title: loc.t('ai_route_api_key'),
                        hint: loc.t('api_key'),
                        trim: false,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('ai_route_model'),
                      value: _settingValue('ai_route_model', loc.t('empty')),
                      onTap: () => _editSettingValue(
                        key: 'ai_route_model',
                        title: loc.t('ai_route_model'),
                        hint: loc.t('model_name'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('ai_route_timeout_seconds'),
                      value:
                          '${_settingValue('ai_route_timeout_seconds', '180')} ${loc.t('second')}',
                      onTap: () => _editSettingValue(
                        key: 'ai_route_timeout_seconds',
                        title: loc.t('ai_route_timeout_seconds'),
                        hint: '180',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('ai_route_parallelism'),
                      value: _settingValue('ai_route_parallelism', '3'),
                      onTap: () => _editSettingValue(
                        key: 'ai_route_parallelism',
                        title: loc.t('ai_route_parallelism'),
                        hint: '3',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('ai_route_services'),
                      value: _servicesSummary(loc),
                      subtitle: loc.t('ai_route_services_hint'),
                      onTap: () => _editAIRouteServices(loc),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.sync,
                  title: loc.t('llm_sync_settings'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ValueActionRow(
                      title: loc.t('setting_sync_llm_interval'),
                      value: '${_settingValue('sync_llm_interval', '24')} h',
                      onTap: () => _editSettingValue(
                        key: 'sync_llm_interval',
                        title: loc.t('setting_sync_llm_interval'),
                        hint: '24',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('sync_channels'),
                      subtitle:
                          '${loc.t('last_sync_time')}: ${_formatDateTimeValue(_lastSyncTime, loc)}',
                      buttonLabel: loc.t('sync_now'),
                      busy: _syncingLLM,
                      onTap: () => _syncLLMNow(loc),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.attach_money,
                  title: loc.t('llm_price_settings'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ValueActionRow(
                      title: loc.t('setting_model_info_update_interval'),
                      value:
                          '${_settingValue('model_info_update_interval', '24')} h',
                      onTap: () => _editSettingValue(
                        key: 'model_info_update_interval',
                        title: loc.t('setting_model_info_update_interval'),
                        hint: '24',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('sync_prices'),
                      subtitle:
                          '${loc.t('last_update_time')}: ${_formatDateTimeValue(_lastModelUpdateTime, loc)}',
                      buttonLabel: loc.t('update_now'),
                      busy: _updatingPrices,
                      onTap: () => _updateLLMPriceNow(loc),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.refresh,
                  title: loc.t('retry_settings'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ValueActionRow(
                      title: loc.t('setting_relay_retry_count'),
                      value: _settingValue('relay_retry_count', '3'),
                      onTap: () => _editSettingValue(
                        key: 'relay_retry_count',
                        title: loc.t('setting_relay_retry_count'),
                        hint: '3',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('setting_ratelimit_cooldown'),
                      value:
                          '${_settingValue('ratelimit_cooldown', '300')} ${loc.t('second')}',
                      onTap: () => _editSettingValue(
                        key: 'ratelimit_cooldown',
                        title: loc.t('setting_ratelimit_cooldown'),
                        hint: '300',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('setting_relay_max_total_attempts'),
                      value: _settingValue('relay_max_total_attempts', '0'),
                      onTap: () => _editSettingValue(
                        key: 'relay_max_total_attempts',
                        title: loc.t('setting_relay_max_total_attempts'),
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.bolt,
                  title: loc.t('circuit_breaker_settings'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ValueActionRow(
                      title: loc.t('setting_circuit_breaker_threshold'),
                      value: _settingValue('circuit_breaker_threshold', '5'),
                      onTap: () => _editSettingValue(
                        key: 'circuit_breaker_threshold',
                        title: loc.t('setting_circuit_breaker_threshold'),
                        hint: '5',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('setting_circuit_breaker_cooldown'),
                      value:
                          '${_settingValue('circuit_breaker_cooldown', '60')} ${loc.t('second')}',
                      onTap: () => _editSettingValue(
                        key: 'circuit_breaker_cooldown',
                        title: loc.t('setting_circuit_breaker_cooldown'),
                        hint: '60',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('setting_circuit_breaker_max_cooldown'),
                      value:
                          '${_settingValue('circuit_breaker_max_cooldown', '600')} ${loc.t('second')}',
                      onTap: () => _editSettingValue(
                        key: 'circuit_breaker_max_cooldown',
                        title: loc.t('setting_circuit_breaker_max_cooldown'),
                        hint: '600',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.tune,
                  title: loc.t('auto_strategy_settings'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ValueActionRow(
                      title: loc.t('setting_auto_strategy_min_samples'),
                      value: _settingValue('auto_strategy_min_samples', '10'),
                      onTap: () => _editSettingValue(
                        key: 'auto_strategy_min_samples',
                        title: loc.t('setting_auto_strategy_min_samples'),
                        hint: '10',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('setting_auto_strategy_time_window'),
                      value:
                          '${_settingValue('auto_strategy_time_window', '300')} ${loc.t('second')}',
                      onTap: () => _editSettingValue(
                        key: 'auto_strategy_time_window',
                        title: loc.t('setting_auto_strategy_time_window'),
                        hint: '300',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ValueActionRow(
                      title: loc.t('setting_auto_strategy_sample_threshold'),
                      value: _settingValue(
                        'auto_strategy_sample_threshold',
                        '100',
                      ),
                      onTap: () => _editSettingValue(
                        key: 'auto_strategy_sample_threshold',
                        title: loc.t('setting_auto_strategy_sample_threshold'),
                        hint: '100',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingSm,
                  ),
                  child: Text(
                    loc.t('preferences'),
                    style: theme.textTheme.caption?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AppSettingItem(
                  title: loc.t('language'),
                  valueWidget: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.locale == AppLocale.en ? 'English' : '中文',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onPressed: () {
                      final newLocale = provider.locale == AppLocale.en
                          ? AppLocale.zh
                          : AppLocale.en;
                      provider.setLocale(newLocale);
                    },
                  ),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingSm,
                    AppTheme.spacingLg,
                    0,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AppSettingItem(
                  title: loc.t('wait_time_unit'),
                  valueWidget: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.waitTimeUnit == WaitTimeUnit.auto
                              ? loc.t('wait_time_unit_auto')
                              : provider.waitTimeUnit == WaitTimeUnit.s
                              ? loc.t('wait_time_unit_s')
                              : loc.t('wait_time_unit_ms'),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onPressed: () {
                      final units = WaitTimeUnit.values;
                      final idx = units.indexOf(provider.waitTimeUnit);
                      final next = units[(idx + 1) % units.length];
                      provider.setWaitTimeUnit(next);
                    },
                  ),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingSm,
                    AppTheme.spacingLg,
                    0,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingSm,
                  ),
                  child: Text(
                    loc.t('server_settings'),
                    style: theme.textTheme.caption?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsActionCard(
                  icon: Icons.warning_amber_rounded,
                  title: loc.t('route_group_danger'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ActionRow(
                      title: loc.t('delete_all_groups'),
                      subtitle: loc.t('route_group_count', {
                        'count': '${_groups.length}',
                      }),
                      buttonLabel: loc.t('delete'),
                      busy: _deletingGroups,
                      onTap: () => _deleteAllGroups(loc),
                      isDanger: true,
                    ),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final setting = _remainingSettings[index];
                  final label = _settingLabel(setting.key, loc);
                  final isBool = _isBooleanSetting(setting.key);
                  final margin = index == 0
                      ? const EdgeInsets.fromLTRB(
                          AppTheme.spacingLg,
                          AppTheme.spacingSm,
                          AppTheme.spacingLg,
                          0,
                        )
                      : const EdgeInsets.fromLTRB(
                          AppTheme.spacingLg,
                          0,
                          AppTheme.spacingLg,
                          0,
                        );
                  return AppSettingItem(
                    title: label,
                    value: isBool
                        ? null
                        : (setting.value.isEmpty
                              ? loc.t('empty')
                              : setting.value),
                    valueWidget: isBool
                        ? CupertinoSwitch(
                            value: setting.value == 'true',
                            onChanged: (_) => _toggleBoolSetting(setting),
                          )
                        : null,
                    showArrow: !isBool,
                    margin: margin,
                    onTap: isBool ? null : () => _editSetting(setting, loc),
                  );
                }, childCount: _remainingSettings.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  final String version;
  final String latestVersion;
  final String? updateError;
  final bool hasUpdate;
  final bool updating;
  final VoidCallback onUpdate;
  final AppLocalizations loc;

  const _SettingsInfoCard({
    required this.version,
    required this.latestVersion,
    required this.updateError,
    required this.hasUpdate,
    required this.updating,
    required this.onUpdate,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingLg,
        0,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: CupertinoIcons.info_circle,
            title: loc.t('server_version'),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _InfoLine(title: loc.t('server_version'), value: version),
          const SizedBox(height: AppTheme.spacingSm),
          _InfoLine(
            title: loc.t('latest_version'),
            value: latestVersion.isEmpty ? loc.t('no_data') : latestVersion,
          ),
          if (updateError != null && updateError!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '${loc.t('update_check_failed')}: $updateError',
              style: TextStyle(fontSize: 12, color: colorScheme.error),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasUpdate ? loc.t('update_available') : loc.t('up_to_date'),
                  style: theme.textTheme.footnote?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasUpdate
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                color: hasUpdate
                    ? colorScheme.primary
                    : colorScheme.secondaryContainer,
                onPressed: updating ? null : onUpdate,
                child: updating
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        loc.t('update_now'),
                        style: TextStyle(
                          color: hasUpdate
                              ? Colors.white
                              : colorScheme.onSecondaryContainer,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final EdgeInsetsGeometry? margin;
  final List<Widget> children;

  const _SettingsActionCard({
    required this.icon,
    required this.title,
    this.margin,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: icon, title: title),
          const SizedBox(height: AppTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 18),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String title;
  final String value;

  const _InfoLine({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onTap;
  final bool isDanger;

  const _ActionRow({
    required this.title,
    this.subtitle,
    required this.buttonLabel,
    required this.busy,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isDanger ? colorScheme.error : colorScheme.secondaryContainer,
          onPressed: busy ? null : onTap,
          child: busy
              ? const CupertinoActivityIndicator()
              : Text(
                  buttonLabel,
                  style: TextStyle(
                    color: isDanger
                        ? Colors.white
                        : colorScheme.onSecondaryContainer,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ValueActionRow extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  const _ValueActionRow({
    required this.title,
    required this.value,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.caption?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchLine({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _PasswordChangeValue {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const _PasswordChangeValue({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}

class _PasswordChangeDialog extends StatefulWidget {
  final AppLocalizations loc;

  const _PasswordChangeDialog({required this.loc});

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  late final TextEditingController _oldCtl;
  late final TextEditingController _newCtl;
  late final TextEditingController _confirmCtl;

  @override
  void initState() {
    super.initState();
    _oldCtl = TextEditingController();
    _newCtl = TextEditingController();
    _confirmCtl = TextEditingController();
  }

  @override
  void dispose() {
    _oldCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CupertinoAlertDialog(
      title: Text(widget.loc.t('change_password')),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            CupertinoTextField(
              controller: _oldCtl,
              obscureText: true,
              placeholder: widget.loc.t('old_password'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.brightness == Brightness.light
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            CupertinoTextField(
              controller: _newCtl,
              obscureText: true,
              placeholder: widget.loc.t('new_password'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.brightness == Brightness.light
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            CupertinoTextField(
              controller: _confirmCtl,
              obscureText: true,
              placeholder: widget.loc.t('confirm_password'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.brightness == Brightness.light
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.loc.t('cancel')),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(
            context,
            _PasswordChangeValue(
              oldPassword: _oldCtl.text,
              newPassword: _newCtl.text,
              confirmPassword: _confirmCtl.text,
            ),
          ),
          child: Text(widget.loc.t('save')),
        ),
      ],
    );
  }
}
