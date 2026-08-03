import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/models/proxy.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class ProxyPage extends StatefulWidget {
  const ProxyPage({super.key});

  @override
  State<ProxyPage> createState() => _ProxyPageState();
}

class _ProxyPageState extends State<ProxyPage> {
  List<ProxyConfiguration> _proxies = [];
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
      _proxies = await api.getProxies();
      _proxies.sort((a, b) => a.name.compareTo(b.name));
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
      await api.createProxy(result);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _edit(ProxyConfiguration proxy) async {
    final result = await _showEditDialog(proxy);
    if (result == null || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.updateProxy(result);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _delete(ProxyConfiguration proxy) async {
    final loc = context.read<AppProvider>().loc;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete'),
      content: loc.t('proxy_confirm_delete', {'name': proxy.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteProxy(proxy.id);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _test(ProxyConfiguration proxy) async {
    final loc = context.read<AppProvider>().loc;
    try {
      final api = context.read<AppProvider>().api;
      final result = await api.testProxy(
        proxy.url,
        proxy.type,
        username: proxy.username,
        password: proxy.password,
      );
      if (mounted) {
        final ok = result['success'] == true;
        await AppTextDialog.show(
          context: context,
          title: loc.t('proxy_test'),
          content: ok
              ? loc.t('proxy_test_success')
              : '${loc.t('proxy_test_failed')}\n${result['message'] ?? ''}',
          buttonText: loc.t('ok'),
        );
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<ProxyConfiguration?> _showEditDialog(
      ProxyConfiguration? existing) async {
    final loc = context.read<AppProvider>().loc;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    final userCtrl = TextEditingController(text: existing?.username ?? '');
    final passCtrl = TextEditingController(text: existing?.password ?? '');
    String type = existing?.type ?? 'http';
    String authType = existing?.authType ?? 'none';
    bool enabled = existing?.enabled ?? true;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return CupertinoAlertDialog(
              title: Text(existing == null
                  ? loc.t('proxy_create')
                  : loc.t('proxy_edit')),
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
                      TextField(
                        controller: urlCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('proxy_url'),
                          hintText: 'http://proxy:8080',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: InputDecoration(
                          labelText: loc.t('proxy_type'),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['http', 'https', 'socks5']
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => type = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: authType,
                        decoration: InputDecoration(
                          labelText: loc.t('proxy_auth_type'),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['none', 'basic']
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => authType = v);
                        },
                      ),
                      if (authType == 'basic') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: userCtrl,
                          decoration: InputDecoration(
                            labelText: loc.t('username'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: loc.t('password'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
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
    return ProxyConfiguration(
      id: existing?.id ?? 0,
      name: nameCtrl.text.trim(),
      url: urlCtrl.text.trim(),
      type: type,
      enabled: enabled,
      authType: authType,
      username: authType == 'basic' ? userCtrl.text.trim() : null,
      password: authType == 'basic' ? passCtrl.text : null,
      referenceCount: existing?.referenceCount ?? 0,
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'http':
        return AppTheme.colorBlue;
      case 'https':
        return AppTheme.colorGreen;
      case 'socks5':
        return AppTheme.colorPurple;
      default:
        return AppTheme.colorGray;
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
              largeTitle: Text(loc.t('proxy_pool')),
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
            else if (_proxies.isEmpty)
              SliverFillRemaining(
                child: AppEmptyState(
                  icon: CupertinoIcons.cloud,
                  title: loc.t('proxy_empty'),
                  subtitle: loc.t('proxy_empty_hint'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final proxy = _proxies[index];
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
                                    proxy.name,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                AppTypeChip(
                                  label: proxy.type.toUpperCase(),
                                  color: _typeColor(proxy.type),
                                ),
                                if (!proxy.enabled) ...[
                                  const SizedBox(width: 4),
                                  AppTypeChip(
                                    label: loc.t('disabled'),
                                    color: AppTheme.colorGray,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  proxy.url,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (proxy.referenceCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    loc.t('proxy_references',
                                        {'count': '${proxy.referenceCount}'}),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                switch (action) {
                                  case 'test':
                                    _test(proxy);
                                    break;
                                  case 'edit':
                                    _edit(proxy);
                                    break;
                                  case 'delete':
                                    _delete(proxy);
                                    break;
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'test',
                                  child: Text(loc.t('proxy_test')),
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
                    childCount: _proxies.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
