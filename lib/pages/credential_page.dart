import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/api_credential.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class CredentialPage extends StatefulWidget {
  const CredentialPage({super.key});

  @override
  State<CredentialPage> createState() => _CredentialPageState();
}

class _CredentialPageState extends State<CredentialPage> {
  List<APICredentialProfile> _credentials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      _credentials = await api.getCredentials();
      _credentials.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final result = await _showEditDialog(null);
    if (result == null || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.createCredential(result);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _edit(APICredentialProfile cred) async {
    final result = await _showEditDialog(cred);
    if (result == null || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.updateCredential(result);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _delete(APICredentialProfile cred) async {
    final loc = context.read<AppProvider>().loc;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete'),
      content: loc.t('credential_confirm_delete', {'name': cred.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteCredential(cred.id);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _verify(APICredentialProfile cred) async {
    final loc = context.read<AppProvider>().loc;
    try {
      final api = context.read<AppProvider>().api;
      final probes = await api.getVerificationProbes();
      if (!mounted) return;

      final selectedProbes = await _showProbeSelector(probes, loc);
      if (selectedProbes == null || selectedProbes.isEmpty || !mounted) return;

      final results = await api.runVerification(cred.id, selectedProbes);
      if (mounted) {
        final buffer = StringBuffer();
        for (final r in results) {
          final icon = r.status == 'pass' ? '✅' : '❌';
          buffer.writeln('$icon ${r.probe}: ${r.status}');
          if (r.message != null && r.message!.isNotEmpty) {
            buffer.writeln('   ${r.message}');
          }
          if (r.latencyMs != null) {
            buffer.writeln('   ${r.latencyMs}ms');
          }
        }
        await AppTextDialog.show(
          context: context,
          title: loc.t('credential_verify'),
          content: buffer.toString(),
          buttonText: loc.t('ok'),
          selectable: true,
        );
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<List<String>?> _showProbeSelector(
      List<VerificationProbe> probes, AppLocalizations loc) async {
    final selected = <String>{};
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return CupertinoAlertDialog(
              title: Text(loc.t('credential_select_probes')),
              content: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    ...probes.map((probe) {
                      return CheckboxListTile(
                        title: Text(probe.name),
                        subtitle: Text(
                          probe.description,
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        value: selected.contains(probe.name),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selected.add(probe.name);
                            } else {
                              selected.remove(probe.name);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(loc.t('cancel')),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(loc.t('credential_run_verify')),
                ),
              ],
            );
          },
        );
      },
    );
    return result == true ? selected.toList() : null;
  }

  Future<void> _exportCli(APICredentialProfile cred) async {
    final loc = context.read<AppProvider>().loc;
    final tools = ['claude-code', 'codex', 'gemini-cli', 'cherry-studio', 'kilo-code'];
    final tool = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(loc.t('credential_export_cli')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ...tools.map((t) => CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, t),
                  child: Text(t),
                )),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('cancel')),
          ),
        ],
      ),
    );
    if (tool == null || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      final config = await api.exportCliConfig(cred.id, tool);
      if (mounted) {
        await AppTextDialog.show(
          context: context,
          title: '$tool ${loc.t('credential_config')}',
          content: config,
          buttonText: loc.t('credential_copy'),
          selectable: true,
        );
        await Clipboard.setData(ClipboardData(text: config));
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<APICredentialProfile?> _showEditDialog(
      APICredentialProfile? existing) async {
    final loc = context.read<AppProvider>().loc;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final baseUrlCtrl =
        TextEditingController(text: existing?.baseUrl ?? '');
    final apiKeyCtrl =
        TextEditingController(text: existing?.apiKey ?? '');
    String apiType = existing?.apiType ?? 'openai';
    bool enabled = existing?.enabled ?? true;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return CupertinoAlertDialog(
              title: Text(existing == null
                  ? loc.t('credential_create')
                  : loc.t('credential_edit')),
              content: Material(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('name'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: apiType,
                        decoration: InputDecoration(
                          labelText: loc.t('credential_api_type'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          'openai',
                          'anthropic',
                          'google',
                          'azure',
                          'custom',
                        ]
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => apiType = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: baseUrlCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('base_url'),
                          hintText: 'https://api.openai.com/v1',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: apiKeyCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: loc.t('api_key'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(loc.t('cancel')),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(loc.t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return null;
    return APICredentialProfile(
      id: existing?.id ?? 0,
      name: nameCtrl.text.trim(),
      apiType: apiType,
      baseUrl: baseUrlCtrl.text.trim(),
      apiKey: apiKeyCtrl.text,
      enabled: enabled,
    );
  }

  Color _healthColor(String status) {
    switch (status) {
      case 'healthy':
        return AppTheme.colorGreen;
      case 'degraded':
        return AppTheme.colorOrange;
      case 'unhealthy':
        return AppTheme.colorRed;
      default:
        return AppTheme.colorGray;
    }
  }

  String _healthLabel(String status, AppLocalizations loc) {
    switch (status) {
      case 'healthy':
        return loc.t('credential_healthy');
      case 'degraded':
        return loc.t('credential_degraded');
      case 'unhealthy':
        return loc.t('credential_unhealthy');
      default:
        return loc.t('credential_unknown');
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
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(loc.t('credentials')),
              backgroundColor: AppTheme.getSurfaceLowest(colorScheme)
                  .withValues(alpha: 0.85),
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: _create,
                child: Icon(
                  CupertinoIcons.add,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (_credentials.isEmpty)
              SliverFillRemaining(
                child: AppEmptyState(
                  icon: CupertinoIcons.lock_shield,
                  title: loc.t('credential_empty'),
                  subtitle: loc.t('credential_empty_hint'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cred = _credentials[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: AppCard(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.all(AppTheme.spacingMd),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cred.name,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                AppTypeChip(
                                  label: cred.apiType,
                                  color: AppTheme.colorBlue,
                                ),
                                AppTypeChip(
                                  label: _healthLabel(
                                      cred.healthStatus, loc),
                                  color: _healthColor(cred.healthStatus),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  cred.baseUrl,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                switch (action) {
                                  case 'verify':
                                    _verify(cred);
                                    break;
                                  case 'export':
                                    _exportCli(cred);
                                    break;
                                  case 'edit':
                                    _edit(cred);
                                    break;
                                  case 'delete':
                                    _delete(cred);
                                    break;
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'verify',
                                  child: Text(loc.t('credential_verify')),
                                ),
                                PopupMenuItem(
                                  value: 'export',
                                  child:
                                      Text(loc.t('credential_export_cli')),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(loc.t('edit')),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    loc.t('delete'),
                                    style: TextStyle(color: AppTheme.colorRed),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _credentials.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
