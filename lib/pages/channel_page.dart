import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

class ChannelPage extends StatefulWidget {
  const ChannelPage({super.key});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  List<Channel> _channels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      _channels = await api.getChannels();
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

  Future<void> _toggleEnabled(Channel ch) async {
    try {
      final api = context.read<AppProvider>().api;
      await api.enableChannel(ch.id, !ch.enabled);
      _loadChannels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteChannel(Channel ch, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.t('delete_channel')),
        content: Text(loc.t('delete_confirm', {'name': ch.name})),
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
      await api.deleteChannel(ch.id);
      _loadChannels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showChannelDialog({Channel? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final modelCtl = TextEditingController(text: existing?.model ?? '');
    final customModelCtl = TextEditingController(
      text: existing?.customModel ?? '',
    );
    final urlCtl = TextEditingController(
      text: existing?.baseUrls.isNotEmpty == true
          ? existing!.baseUrls.first.url
          : '',
    );
    final keyCtl = TextEditingController(
      text: existing?.keys.isNotEmpty == true
          ? existing!.keys.first.channelKey
          : '',
    );
    int selectedType = existing?.type ?? 1;
    bool enabled = existing?.enabled ?? true;
    bool proxy = existing?.proxy ?? false;
    bool autoSync = existing?.autoSync ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? loc.t('edit_channel') : loc.t('create_channel')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: InputDecoration(
                      labelText: loc.t('channel_name'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: loc.t('channel_type'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(loc.t('type_openai_chat')),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(loc.t('type_openai_response')),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(loc.t('type_openai_embedding')),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text(loc.t('type_anthropic')),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text(loc.t('type_gemini')),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child: Text(loc.t('type_volcengine')),
                      ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedType = v ?? 1),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtl,
                    decoration: InputDecoration(
                      labelText: loc.t('base_url'),
                      hintText: 'https://api.openai.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtl,
                    decoration: InputDecoration(labelText: loc.t('api_key')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelCtl,
                    decoration: InputDecoration(labelText: loc.t('model')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customModelCtl,
                    decoration: InputDecoration(
                      labelText: loc.t('custom_model'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(loc.t('enabled')),
                    value: enabled,
                    onChanged: (v) => setDialogState(() => enabled = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.t('proxy')),
                    value: proxy,
                    onChanged: (v) => setDialogState(() => proxy = v),
                  ),
                  SwitchListTile(
                    title: Text(loc.t('auto_sync')),
                    value: autoSync,
                    onChanged: (v) => setDialogState(() => autoSync = v),
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
    modelCtl.dispose();
    customModelCtl.dispose();
    urlCtl.dispose();
    keyCtl.dispose();

    if (result != true) return;

    try {
      final api = context.read<AppProvider>().api;
      final channel = Channel(
        id: existing?.id ?? 0,
        name: nameCtl.text.trim(),
        type: selectedType,
        enabled: enabled,
        baseUrls: urlCtl.text.trim().isNotEmpty
            ? [BaseUrl(url: urlCtl.text.trim())]
            : [],
        keys: keyCtl.text.trim().isNotEmpty
            ? [
                ChannelKey(
                  id: 0,
                  channelId: existing?.id ?? 0,
                  channelKey: keyCtl.text.trim(),
                ),
              ]
            : [],
        model: modelCtl.text.trim(),
        customModel: customModelCtl.text.trim(),
        proxy: proxy,
        autoSync: autoSync,
      );
      if (isEdit) {
        await api.updateChannel(channel);
      } else {
        await api.createChannel(channel);
      }
      _loadChannels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _channelTypeName(int type, AppLocalizations loc) {
    switch (type) {
      case 1:
        return loc.t('type_openai_chat');
      case 2:
        return loc.t('type_openai_response');
      case 3:
        return loc.t('type_openai_embedding');
      case 4:
        return loc.t('type_anthropic');
      case 5:
        return loc.t('type_gemini');
      case 6:
        return loc.t('type_volcengine');
      default:
        return 'Type $type';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChannelDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChannels,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(title: Text(loc.t('channels')), floating: true),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_channels.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text(loc.t('no_channels'))),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ch = _channels[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Switch(
                        value: ch.enabled,
                        onChanged: (_) => _toggleEnabled(ch),
                      ),
                      title: Text(
                        ch.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_channelTypeName(ch.type, loc)),
                          if (ch.keys.isNotEmpty)
                            Text(
                              '${loc.t("keys")}: ${ch.keys.where((k) => k.enabled).length}/${ch.keys.length}',
                            ),
                          if (ch.stats != null)
                            Text(
                              '${loc.t("success")}: ${ch.stats!.requestSuccess}  ${loc.t("failed")}: ${ch.stats!.requestFailed}',
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showChannelDialog(existing: ch),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteChannel(ch, loc),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                }, childCount: _channels.length),
              ),
          ],
        ),
      ),
    );
  }
}
