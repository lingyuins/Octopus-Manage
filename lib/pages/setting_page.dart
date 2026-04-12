import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/setting.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_list_tile.dart';
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
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
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
    if (result == null) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.setSetting(setting.key, result);
      _loadSettings();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.getSurfaceLowest(colorScheme),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(loc.t('settings')),
              backgroundColor: AppTheme.getSurfaceLowest(
                colorScheme,
              ).withValues(alpha: 0.85),
              border: null,
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingState(),
              )
            else ...[
              SliverToBoxAdapter(
                child: AppCard(
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingSm,
                    AppTheme.spacingLg,
                    0,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.info_circle,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.t('server_version'),
                              style: theme.textTheme.footnote?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _version,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final s = _settings[index];
                  final label = _settingLabel(s.key, loc);
                  final isBool = _isBooleanSetting(s.key);
                  final EdgeInsets margin = index == 0
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
                        : (s.value.isEmpty ? loc.t('empty') : s.value),
                    valueWidget: isBool
                        ? CupertinoSwitch(
                            value: s.value == 'true',
                            onChanged: (_) => _toggleBoolSetting(s),
                          )
                        : null,
                    showArrow: !isBool,
                    margin: margin,
                    onTap: isBool ? null : () => _editSetting(s, loc),
                  );
                }, childCount: _settings.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
            ],
          ],
        ),
      ),
    );
  }
}
