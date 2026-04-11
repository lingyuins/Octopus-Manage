import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/setting.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  List<Setting> _settings = [];
  bool _loading = true;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      final results = await Future.wait([
        api.getSettings(),
        api.getCurrentVersion(),
      ]);
      if (mounted) {
        setState(() {
          _settings = results[0] as List<Setting>;
          _version = results[1] as String;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isBooleanSetting(String key) {
    return key == 'relay_log_keep_enabled';
  }

  Future<void> _toggleBoolSetting(Setting setting) async {
    final newValue = setting.value == 'true' ? 'false' : 'true';
    try {
      final api = context.read<AppProvider>().api;
      await api.setSetting(setting.key, newValue);
      _loadSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _editSetting(Setting setting, AppLocalizations loc) async {
    final controller = TextEditingController(text: setting.value);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_settingLabel(setting.key, loc)),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(loc.t('save')),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.setSetting(setting.key, result);
      _loadSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
    };
    return loc.t(keyMap[key] ?? key);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final loc = provider.loc;
    return RefreshIndicator(
      onRefresh: _loadSettings,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(title: Text(loc.t('settings')), floating: true),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(loc.t('server_version')),
                  trailing: Text(
                    _version,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(loc.t('language')),
                  trailing: DropdownButton<AppLocale>(
                    value: provider.locale,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: AppLocale.en,
                        child: Text('English'),
                      ),
                      DropdownMenuItem(value: AppLocale.zh, child: Text('中文')),
                    ],
                    onChanged: (v) {
                      if (v != null) provider.setLocale(v);
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text(loc.t('wait_time_unit')),
                  trailing: DropdownButton<WaitTimeUnit>(
                    value: provider.waitTimeUnit,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: WaitTimeUnit.auto,
                        child: Text(loc.t('wait_time_unit_auto')),
                      ),
                      DropdownMenuItem(
                        value: WaitTimeUnit.s,
                        child: Text(loc.t('wait_time_unit_s')),
                      ),
                      DropdownMenuItem(
                        value: WaitTimeUnit.ms,
                        child: Text(loc.t('wait_time_unit_ms')),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) provider.setWaitTimeUnit(v);
                    },
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final s = _settings[index];
                final label = _settingLabel(s.key, loc);
                final isBool = _isBooleanSetting(s.key);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(label, style: const TextStyle(fontSize: 13)),
                    subtitle: isBool
                        ? null
                        : Text(
                            s.value.isEmpty ? loc.t('empty') : s.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                    trailing: isBool
                        ? Switch(
                            value: s.value == 'true',
                            onChanged: (_) => _toggleBoolSetting(s),
                          )
                        : const Icon(Icons.chevron_right, size: 18),
                    onTap: isBool ? null : () => _editSetting(s, loc),
                  ),
                );
              }, childCount: _settings.length),
            ),
          ],
        ],
      ),
    );
  }
}
