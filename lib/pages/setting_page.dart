import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/models/setting.dart';
import 'package:octopusmanage/pages/alert_page.dart';
import 'package:octopusmanage/pages/analytics_page.dart';
import 'package:octopusmanage/pages/audit_log_page.dart';
import 'package:octopusmanage/pages/credential_page.dart';
import 'package:octopusmanage/pages/model_mapping_page.dart';
import 'package:octopusmanage/pages/ops_page.dart';
import 'package:octopusmanage/pages/proxy_page.dart';
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

  // WebDAV state
  Map<String, dynamic> _webdavConfig = {};
  List<Map<String, dynamic>> _webdavBackups = [];
  bool _webdavLoading = false;
  bool _webdavTesting = false;
  bool _webdavBackingUp = false;

  // WebAuthn state
  Map<String, dynamic> _webauthnConfig = {};
  List<Map<String, dynamic>> _webauthnCredentials = [];
  bool _webauthnLoading = false;

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
    if (!mounted) return;
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
      // Load WebDAV and WebAuthn in background
      _loadWebDAV();
      _loadWebAuthn();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  bool _isBooleanSetting(String key) =>
      key == 'relay_log_keep_enabled' ||
      key == 'semantic_cache_enabled' ||
      key == 'response_filter_enabled' ||
      key == 'model_normalize_market_dedupe_default';

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
    final result = await showCupertinoDialog<String>(
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
    final payload = await showCupertinoDialog<_PasswordChangeValue>(
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

  // ====== WebDAV ======
  Future<void> _loadWebDAV() async {
    if (_webdavLoading) return;
    setState(() => _webdavLoading = true);
    try {
      final api = context.read<AppProvider>().api;
      final configFuture = api.getWebDAVConfig();
      final backupsFuture = api.listWebDAVBackups();
      final config = await configFuture;
      List<Map<String, dynamic>> backups = [];
      try {
        backups = await backupsFuture;
      } catch (_) {}
      if (!mounted) return;
      // Convert interval_hours to interval string for UI
      final intervalHours = config['interval_hours'] as int? ?? 6;
      String interval;
      if (intervalHours <= 0) {
        interval = 'disabled';
      } else if (intervalHours == 1) {
        interval = 'hourly';
      } else if (intervalHours == 24) {
        interval = 'daily';
      } else if (intervalHours == 168) {
        interval = 'weekly';
      } else {
        interval = 'daily'; // Default to daily for other values
      }
      config['interval'] = interval;
      setState(() {
        _webdavConfig = config;
        _webdavBackups = backups;
        _webdavLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _webdavLoading = false);
    }
  }

  Future<void> _saveWebDAVConfig() async {
    try {
      final api = context.read<AppProvider>().api;
      // Convert interval string to interval_hours for server
      final config = Map<String, dynamic>.from(_webdavConfig);
      final interval = (config['interval'] ?? 'disabled').toString();
      int intervalHours;
      switch (interval) {
        case 'hourly':
          intervalHours = 1;
          break;
        case 'daily':
          intervalHours = 24;
          break;
        case 'weekly':
          intervalHours = 168;
          break;
        default:
          intervalHours = 0; // disabled
      }
      config['interval_hours'] = intervalHours;
      // Remove UI-only field
      config.remove('interval');
      await api.setWebDAVConfig(config);
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _editWebDAVField(String key, String title, AppLocalizations loc,
      {String? hint, TextInputType? keyboardType, bool obscure = false}) async {
    final controller =
        TextEditingController(text: (_webdavConfig[key] ?? '').toString());
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            obscureText: obscure,
            placeholder: hint ?? loc.t('enter_value'),
            padding: const EdgeInsets.all(12),
            keyboardType: keyboardType,
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
    setState(() => _webdavConfig[key] = result);
    await _saveWebDAVConfig();
  }

  Future<void> _testWebDAV(AppLocalizations loc) async {
    if (_webdavTesting) return;
    setState(() => _webdavTesting = true);
    try {
      final api = context.read<AppProvider>().api;
      final ok = await api.testWebDAV();
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('webdav_test'),
        content: ok ? loc.t('webdav_test_success') : loc.t('webdav_test_failed'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, loc.t('webdav_test_failed'));
      }
    } finally {
      if (mounted) setState(() => _webdavTesting = false);
    }
  }

  Future<void> _triggerWebDAVBackup(AppLocalizations loc) async {
    if (_webdavBackingUp) return;
    setState(() => _webdavBackingUp = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.triggerWebDAVBackup();
      if (!mounted) return;
      await AppTextDialog.show(
        context: context,
        title: loc.t('webdav_backup_now'),
        content: loc.t('webdav_backup_success'),
        buttonText: loc.t('ok'),
        selectable: false,
      );
      await _loadWebDAV();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, loc.t('webdav_backup_failed'));
      }
    } finally {
      if (mounted) setState(() => _webdavBackingUp = false);
    }
  }

  Future<void> _restoreWebDAVBackup(String filename, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('webdav_restore'),
      content: loc.t('webdav_restore_confirm', {'name': filename}),
      confirmText: loc.t('webdav_restore'),
      cancelText: loc.t('cancel'),
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.restoreWebDAVBackup(filename);
      await _loadWebDAV();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _deleteWebDAVBackup(String filename, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('webdav_delete'),
      content: loc.t('webdav_delete_confirm', {'name': filename}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteWebDAVBackup(filename);
      await _loadWebDAV();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  String _webdavIntervalLabel(String value, AppLocalizations loc) {
    switch (value) {
      case 'hourly':
        return loc.t('webdav_interval_hourly');
      case 'daily':
        return loc.t('webdav_interval_daily');
      case 'weekly':
        return loc.t('webdav_interval_weekly');
      default:
        return loc.t('webdav_interval_disabled');
    }
  }

  // ====== WebAuthn ======
  Future<void> _loadWebAuthn() async {
    if (_webauthnLoading) return;
    setState(() => _webauthnLoading = true);
    try {
      final api = context.read<AppProvider>().api;
      final settingsFuture = api.getSettings();
      final credsFuture = api.listWebAuthnCredentials();
      final settings = await settingsFuture;
      List<Map<String, dynamic>> creds = [];
      try {
        creds = await credsFuture;
      } catch (_) {}
      if (!mounted) return;
      // Build config from settings
      final settingsByKey = {for (final s in settings) s.key: s.value};
      final config = {
        'rp_id': settingsByKey['webauthn_rp_id'] ?? '',
        'rp_name': settingsByKey['webauthn_rp_name'] ?? 'Octopus',
        'allowed_origins': settingsByKey['webauthn_origins'] ?? '',
      };
      setState(() {
        _webauthnConfig = config;
        _webauthnCredentials = creds;
        _webauthnLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _webauthnLoading = false);
    }
  }

  Future<void> _saveWebAuthnConfig() async {
    try {
      final api = context.read<AppProvider>().api;
      // Map config keys to setting keys
      final settingKeyMap = {
        'rp_id': 'webauthn_rp_id',
        'rp_name': 'webauthn_rp_name',
        'allowed_origins': 'webauthn_origins',
      };
      for (final entry in settingKeyMap.entries) {
        final value = (_webauthnConfig[entry.key] ?? '').toString();
        await api.setSetting(entry.value, value);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _editWebAuthnField(String key, String title, AppLocalizations loc,
      {String? hint}) async {
    final controller =
        TextEditingController(text: (_webauthnConfig[key] ?? '').toString());
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: hint ?? loc.t('enter_value'),
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
    setState(() => _webauthnConfig[key] = result);
    await _saveWebAuthnConfig();
  }

  Future<void> _deleteWebAuthnCredential(
      Map<String, dynamic> cred, AppLocalizations loc) async {
    final id = cred['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('webauthn_delete'),
      content: loc.t('webauthn_delete_confirm'),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteWebAuthnCredential(id);
      await _loadWebAuthn();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
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
      'auto_strategy_latency_weight':
          'setting_auto_strategy_latency_weight',
      'alert_notify_language': 'setting_alert_notify_language',
      'semantic_cache_enabled': 'setting_semantic_cache_enabled',
      'semantic_cache_embedding_base_url':
          'setting_semantic_cache_embedding_base_url',
      'semantic_cache_embedding_model':
          'setting_semantic_cache_embedding_model',
      'semantic_cache_embedding_api_key':
          'setting_semantic_cache_embedding_api_key',
      'semantic_cache_threshold':
          'setting_semantic_cache_threshold',
      'semantic_cache_ttl':
          'setting_semantic_cache_ttl',
      'semantic_cache_max_entries':
          'setting_semantic_cache_max_entries',
      'semantic_cache_embedding_dimensions':
          'setting_semantic_cache_embedding_dimensions',
      // New setting keys
      'relay_route_retries': 'setting_relay_route_retries',
      'relay_log_keep_count': 'setting_relay_log_keep_count',
      'log_level': 'setting_log_level',
      'stats_timezone_offset': 'setting_stats_timezone_offset',
      'response_filter_enabled': 'setting_response_filter_enabled',
      'response_filter_keywords': 'setting_response_filter_keywords',
      'response_filter_action': 'setting_response_filter_action',
      'jwt_default_expiry_minutes': 'setting_jwt_default_expiry_minutes',
      'jwt_remember_me_expiry_days': 'setting_jwt_remember_me_expiry_days',
      'login_rate_limit_window': 'setting_login_rate_limit_window',
      'login_rate_limit_max_failed': 'setting_login_rate_limit_max_failed',
      'stream_session_ttl_minutes': 'setting_stream_session_ttl_minutes',
      'stream_session_max_events': 'setting_stream_session_max_events',
      'stream_session_max_bytes_mb': 'setting_stream_session_max_bytes_mb',
      'notify_http_timeout_seconds': 'setting_notify_http_timeout_seconds',
      'site_sync_interval': 'setting_site_sync_interval',
      'site_checkin_interval': 'setting_site_checkin_interval',
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
                  icon: CupertinoIcons.rectangle_stack,
                  title: loc.t('ops'),
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                    0,
                  ),
                  children: [
                    _ActionRow(
                      title: loc.t('ops'),
                      icon: CupertinoIcons.chevron_right,
                      busy: false,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const OpsPage()),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('alerts'),
                      icon: CupertinoIcons.chevron_right,
                      busy: false,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const AlertPage()),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('analytics'),
                      icon: CupertinoIcons.chevron_right,
                      busy: false,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const AnalyticsPage()),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('audit_logs'),
                      icon: CupertinoIcons.chevron_right,
                      busy: false,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const AuditLogPage()),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('proxy'),
                      icon: CupertinoIcons.chevron_right,
                      busy: false,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const ProxyPage()),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('model_mapping'),
                      icon: CupertinoIcons.chevron_right,
                      busy: false,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const ModelMappingPage()),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionRow(
                      title: loc.t('api_credentials'),
                      icon: CupertinoIcons.chevron_right,
                      busy: false,
                      onTap: () => Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const CredentialPage()),
                      ),
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
                child: _WebDAVCard(
                  config: _webdavConfig,
                  backups: _webdavBackups,
                  loading: _webdavLoading,
                  testing: _webdavTesting,
                  backingUp: _webdavBackingUp,
                  loc: loc,
                  colorScheme: colorScheme,
                  onRefresh: _loadWebDAV,
                  onEditField: _editWebDAVField,
                  onIntervalChanged: (value) async {
                    setState(() => _webdavConfig['interval'] = value);
                    await _saveWebDAVConfig();
                  },
                  onMaxBackupsChanged: (value) async {
                    setState(() => _webdavConfig['max_backups'] = value);
                    await _saveWebDAVConfig();
                  },
                  onTest: () => _testWebDAV(loc),
                  onBackupNow: () => _triggerWebDAVBackup(loc),
                  onRestore: (fn) => _restoreWebDAVBackup(fn, loc),
                  onDelete: (fn) => _deleteWebDAVBackup(fn, loc),
                  intervalLabel: _webdavIntervalLabel,
                  onIncludeStatsChanged: (value) async {
                    setState(() => _webdavConfig['include_stats'] = value);
                    await _saveWebDAVConfig();
                  },
                  onIncludeLogsChanged: (value) async {
                    setState(() => _webdavConfig['include_logs'] = value);
                    await _saveWebDAVConfig();
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _WebAuthnCard(
                  config: _webauthnConfig,
                  credentials: _webauthnCredentials,
                  loading: _webauthnLoading,
                  loc: loc,
                  colorScheme: colorScheme,
                  onRefresh: _loadWebAuthn,
                  onEditField: _editWebAuthnField,
                  onDeleteCredential: (cred) =>
                      _deleteWebAuthnCredential(cred, loc),
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
                      value: '${_settingValue('sync_llm_interval', '24')} ${loc.t('hour_unit')}',
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
                          '${_settingValue('model_info_update_interval', '24')} ${loc.t('hour_unit')}',
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
                          provider.locale == AppLocale.en
                              ? loc.t('language_english')
                              : loc.t('language_chinese'),
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
  final IconData? icon;
  final bool busy;
  final VoidCallback onTap;
  final bool isDanger;

  const _ActionRow({
    required this.title,
    this.subtitle,
    this.buttonLabel = '',
    this.icon,
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
        if (icon != null)
          GestureDetector(
            onTap: busy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            ),
          )
        else
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

// ====== WebDAV Card ======
class _WebDAVCard extends StatelessWidget {
  final Map<String, dynamic> config;
  final List<Map<String, dynamic>> backups;
  final bool loading;
  final bool testing;
  final bool backingUp;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final VoidCallback onRefresh;
  final Future<void> Function(String key, String title, AppLocalizations loc,
      {String? hint, TextInputType? keyboardType, bool obscure}) onEditField;
  final ValueChanged<String> onIntervalChanged;
  final ValueChanged<int> onMaxBackupsChanged;
  final VoidCallback onTest;
  final VoidCallback onBackupNow;
  final ValueChanged<String> onRestore;
  final ValueChanged<String> onDelete;
  final String Function(String, AppLocalizations) intervalLabel;
  final ValueChanged<bool> onIncludeStatsChanged;
  final ValueChanged<bool> onIncludeLogsChanged;

  const _WebDAVCard({
    required this.config,
    required this.backups,
    required this.loading,
    required this.testing,
    required this.backingUp,
    required this.loc,
    required this.colorScheme,
    required this.onRefresh,
    required this.onEditField,
    required this.onIntervalChanged,
    required this.onMaxBackupsChanged,
    required this.onTest,
    required this.onBackupNow,
    required this.onRestore,
    required this.onDelete,
    required this.intervalLabel,
    required this.onIncludeStatsChanged,
    required this.onIncludeLogsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SettingsActionCard(
      icon: CupertinoIcons.cloud,
      title: loc.t('webdav'),
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        0,
      ),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else ...[
          _ValueActionRow(
            title: loc.t('webdav_base_url'),
            value: (config['base_url'] ?? '').toString().isEmpty
                ? loc.t('empty')
                : (config['base_url'] ?? '').toString(),
            onTap: () => onEditField(
              'base_url',
              loc.t('webdav_base_url'),
              loc,
              hint: 'https://dav.example.com',
              keyboardType: TextInputType.url,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ValueActionRow(
            title: loc.t('webdav_username'),
            value: (config['username'] ?? '').toString().isEmpty
                ? loc.t('empty')
                : (config['username'] ?? '').toString(),
            onTap: () => onEditField(
              'username',
              loc.t('webdav_username'),
              loc,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ValueActionRow(
            title: loc.t('webdav_password'),
            value: (config['password'] ?? '').toString().isEmpty
                ? loc.t('empty')
                : '••••••',
            onTap: () => onEditField(
              'password',
              loc.t('webdav_password'),
              loc,
              obscure: true,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ValueActionRow(
            title: loc.t('webdav_remote_path'),
            value: (config['remote_path'] ?? '/').toString(),
            onTap: () => onEditField(
              'remote_path',
              loc.t('webdav_remote_path'),
              loc,
              hint: '/backups',
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Interval dropdown
          GestureDetector(
            onTap: () {
              final intervals = ['disabled', 'hourly', 'daily', 'weekly'];
              final current = (config['interval'] ?? 'disabled').toString();
              final idx = intervals.indexOf(current);
              final next = intervals[(idx + 1) % intervals.length];
              onIntervalChanged(next);
            },
            child: Row(
              children: [
                Expanded(child: Text(loc.t('webdav_auto_backup'))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      intervalLabel(
                        (config['interval'] ?? 'disabled').toString(),
                        loc,
                      ),
                      style: theme.textTheme.caption?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ValueActionRow(
            title: loc.t('webdav_max_backups'),
            value: (config['max_backups'] ?? 10).toString(),
            onTap: () async {
              final controller = TextEditingController(
                  text: (config['max_backups'] ?? 10).toString());
              final result = await showCupertinoDialog<String>(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: Text(loc.t('webdav_max_backups')),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CupertinoTextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      placeholder: '10',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.brightness ==
                                Brightness.light
                            ? const Color(0xFFE5E5EA)
                            : const Color(0xFF3A3A3C),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
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
              if (result != null) {
                final parsed = int.tryParse(result.trim());
                if (parsed != null && parsed > 0) {
                  onMaxBackupsChanged(parsed);
                }
              }
            },
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SwitchLine(
            title: loc.t('include_stats'),
            value: config['include_stats'] == true,
            onChanged: onIncludeStatsChanged,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SwitchLine(
            title: loc.t('include_logs'),
            value: config['include_logs'] == true,
            onChanged: onIncludeLogsChanged,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Test & Backup buttons
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: colorScheme.secondaryContainer,
                  onPressed: testing ? null : onTest,
                  child: testing
                      ? const CupertinoActivityIndicator()
                      : Text(
                          loc.t('webdav_test'),
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: backingUp ? null : onBackupNow,
                  child: backingUp
                      ? const CupertinoActivityIndicator()
                      : Text(loc.t('webdav_backup_now')),
                ),
              ),
            ],
          ),
          // Remote backups list
          if (backups.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              loc.t('webdav_backups'),
              style: theme.textTheme.caption?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...backups.map((backup) {
              final filename = backup['filename']?.toString() ??
                  backup['name']?.toString() ??
                  '';
              final size = backup['size']?.toString() ?? '';
              final date = backup['modified']?.toString() ??
                  backup['created_at']?.toString() ??
                  '';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filename,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (date.isNotEmpty || size.isNotEmpty)
                            Text(
                              [date, size].where((s) => s.isNotEmpty).join(' · '),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      onPressed: () => onRestore(filename),
                      child: Text(
                        loc.t('webdav_restore'),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      onPressed: () => onDelete(filename),
                      child: Text(
                        loc.t('webdav_delete'),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ],
    );
  }
}

// ====== WebAuthn Card ======
class _WebAuthnCard extends StatelessWidget {
  final Map<String, dynamic> config;
  final List<Map<String, dynamic>> credentials;
  final bool loading;
  final AppLocalizations loc;
  final ColorScheme colorScheme;
  final VoidCallback onRefresh;
  final Future<void> Function(String key, String title, AppLocalizations loc,
      {String? hint}) onEditField;
  final ValueChanged<Map<String, dynamic>> onDeleteCredential;

  const _WebAuthnCard({
    required this.config,
    required this.credentials,
    required this.loading,
    required this.loc,
    required this.colorScheme,
    required this.onRefresh,
    required this.onEditField,
    required this.onDeleteCredential,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SettingsActionCard(
      icon: CupertinoIcons.lock_shield,
      title: loc.t('webauthn'),
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        0,
      ),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else ...[
          _ValueActionRow(
            title: loc.t('webauthn_rp_id'),
            value: (config['rp_id'] ?? '').toString().isEmpty
                ? loc.t('empty')
                : (config['rp_id'] ?? '').toString(),
            onTap: () => onEditField(
              'rp_id',
              loc.t('webauthn_rp_id'),
              loc,
              hint: 'example.com',
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ValueActionRow(
            title: loc.t('webauthn_rp_name'),
            value: (config['rp_name'] ?? '').toString().isEmpty
                ? loc.t('empty')
                : (config['rp_name'] ?? '').toString(),
            onTap: () => onEditField(
              'rp_name',
              loc.t('webauthn_rp_name'),
              loc,
              hint: 'Octopus Manager',
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ValueActionRow(
            title: loc.t('webauthn_origins'),
            value: (config['allowed_origins'] ?? '').toString().isEmpty
                ? loc.t('empty')
                : (config['allowed_origins'] ?? '').toString(),
            subtitle: loc.t('webauthn_origins_hint'),
            onTap: () => onEditField(
              'allowed_origins',
              loc.t('webauthn_origins'),
              loc,
              hint: 'https://example.com,https://app.example.com',
            ),
          ),
          // Credentials list
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            loc.t('webauthn_credentials'),
            style: theme.textTheme.caption?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (credentials.isEmpty)
            Text(
              loc.t('webauthn_no_credentials'),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...credentials.map((cred) {
              final id = cred['id']?.toString() ?? '';
              final name = cred['name']?.toString() ??
                  cred['credential_name']?.toString() ??
                  id;
              final createdAt = cred['created_at']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (createdAt.isNotEmpty)
                            Text(
                              createdAt,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      onPressed: () => onDeleteCredential(cred),
                      child: Text(
                        loc.t('webauthn_delete'),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }
}
