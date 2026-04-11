import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({super.key});

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  List<APIKey> _keys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      _keys = await api.getApiKeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleEnabled(APIKey key) async {
    try {
      final api = context.read<AppProvider>().api;
      await api.updateApiKey(
        APIKey(
          id: key.id,
          name: key.name,
          enabled: !key.enabled,
          expireAt: key.expireAt,
          maxCost: key.maxCost,
          supportedModels: key.supportedModels,
        ),
      );
      _loadKeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteKey(APIKey key, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.t('delete_api_key')),
        content: Text(loc.t('delete_confirm', {'name': key.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              loc.t('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteApiKey(key.id);
      _loadKeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showApiKeyDialog({APIKey? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final maxCostCtl = TextEditingController(
      text: existing?.maxCost.toString() ?? '0',
    );
    final expireAtCtl = TextEditingController(
      text: existing?.expireAt.toString() ?? '0',
    );
    final supportedModelsCtl = TextEditingController(
      text: existing?.supportedModels ?? '',
    );
    bool enabled = existing?.enabled ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? loc.t('edit_api_key') : loc.t('create_api_key')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: InputDecoration(labelText: loc.t('name')),
                    autofocus: !isEdit,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxCostCtl,
                    decoration: InputDecoration(
                      labelText: loc.t('max_cost'),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expireAtCtl,
                    decoration: InputDecoration(
                      labelText: loc.t('expire_at'),
                      hintText: loc.t('expire_at_hint'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: supportedModelsCtl,
                    decoration: InputDecoration(
                      labelText: loc.t('supported_models'),
                      hintText: loc.t('supported_models_hint'),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(loc.t('enabled')),
                    value: enabled,
                    onChanged: (v) => setDialogState(() => enabled = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.t('save')),
            ),
          ],
        ),
      ),
    );

    nameCtl.dispose();
    maxCostCtl.dispose();
    expireAtCtl.dispose();
    supportedModelsCtl.dispose();

    if (result != true) return;

    try {
      final api = context.read<AppProvider>().api;
      final key = APIKey(
        id: existing?.id ?? 0,
        name: nameCtl.text.trim(),
        enabled: enabled,
        expireAt: int.tryParse(expireAtCtl.text) ?? 0,
        maxCost: double.tryParse(maxCostCtl.text) ?? 0,
        supportedModels: supportedModelsCtl.text.trim(),
      );
      if (isEdit) {
        await api.updateApiKey(key);
      } else {
        final newKey = await api.createApiKey(key);
        if (mounted && newKey.apiKey.isNotEmpty) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(loc.t('api_key_created')),
              content: SelectableText(
                newKey.apiKey,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.t('ok')),
                ),
              ],
            ),
          );
        }
      }
      _loadKeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showApiKeyDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadKeys,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(title: Text(loc.t('api_keys')), floating: true),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_keys.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text(loc.t('no_api_keys'))),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final key = _keys[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Switch(
                        value: key.enabled,
                        onChanged: (_) => _toggleEnabled(key),
                      ),
                      title: Text(
                        key.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        key.apiKey.length > 16
                            ? '${key.apiKey.substring(0, 16)}...'
                            : key.apiKey,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showApiKeyDialog(existing: key),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteKey(key, loc),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: _keys.length),
              ),
          ],
        ),
      ),
    );
  }
}
