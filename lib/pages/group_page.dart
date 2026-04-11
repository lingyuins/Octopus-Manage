import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List<Group> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      _groups = await api.getGroups();
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

  Future<void> _deleteGroup(Group g, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.t('delete_group')),
        content: Text(loc.t('delete_confirm', {'name': g.name})),
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
      await api.deleteGroup(g.id);
      _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showGroupDialog({Group? existing}) async {
    final loc = context.read<AppProvider>().loc;
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final matchRegexCtl = TextEditingController(
      text: existing?.matchRegex ?? '',
    );
    final timeoutCtl = TextEditingController(
      text: existing?.firstTokenTimeOut.toString() ?? '0',
    );
    final keepTimeCtl = TextEditingController(
      text: existing?.sessionKeepTime.toString() ?? '0',
    );
    int selectedMode = existing?.mode ?? 1;
    List<_GroupItemDraft> items =
        existing?.items
            .map(
              (e) => _GroupItemDraft(
                channelId: e.channelId,
                modelName: e.modelName,
                priority: e.priority,
                weight: e.weight,
              ),
            )
            .toList() ??
        [];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? loc.t('edit_group') : loc.t('create_group')),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtl,
                      decoration: InputDecoration(
                        labelText: loc.t('group_name'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedMode,
                      decoration: InputDecoration(labelText: loc.t('mode')),
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(loc.t('mode_round_robin')),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(loc.t('mode_random')),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(loc.t('mode_failover')),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text(loc.t('mode_weighted')),
                        ),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedMode = v ?? 1),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: matchRegexCtl,
                      decoration: InputDecoration(
                        labelText: loc.t('match_regex'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeoutCtl,
                      decoration: InputDecoration(
                        labelText: loc.t('first_token_timeout'),
                        suffixText: loc.t('second'),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keepTimeCtl,
                      decoration: InputDecoration(
                        labelText: loc.t('session_keep'),
                        suffixText: loc.t('second'),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          loc.t('group_items'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () {
                            setDialogState(() => items.add(_GroupItemDraft()));
                          },
                        ),
                      ],
                    ),
                    ...items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: item.channelId.toString(),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: loc.t('channel_id'),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) =>
                                          item.channelId = int.tryParse(v) ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: item.modelName,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: loc.t('model_name'),
                                        isDense: true,
                                      ),
                                      onChanged: (v) => item.modelName = v,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: item.priority.toString(),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: loc.t('priority'),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) =>
                                          item.priority = int.tryParse(v) ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: item.weight.toString(),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: loc.t('weight'),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) =>
                                          item.weight = int.tryParse(v) ?? 0,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setDialogState(() => items.removeAt(i));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
          );
        },
      ),
    );

    nameCtl.dispose();
    matchRegexCtl.dispose();
    timeoutCtl.dispose();
    keepTimeCtl.dispose();

    if (result != true) return;

    try {
      final api = context.read<AppProvider>().api;
      final group = Group(
        id: existing?.id ?? 0,
        name: nameCtl.text.trim(),
        mode: selectedMode,
        matchRegex: matchRegexCtl.text.trim(),
        firstTokenTimeOut: int.tryParse(timeoutCtl.text) ?? 0,
        sessionKeepTime: int.tryParse(keepTimeCtl.text) ?? 0,
        items: items
            .map(
              (e) => GroupItem(
                channelId: e.channelId,
                modelName: e.modelName,
                priority: e.priority,
                weight: e.weight,
              ),
            )
            .toList(),
      );
      if (isEdit) {
        await api.updateGroup(group);
      } else {
        await api.createGroup(group);
      }
      _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _modeLabel(int mode, AppLocalizations loc) {
    switch (mode) {
      case 1:
        return loc.t('mode_round_robin');
      case 2:
        return loc.t('mode_random');
      case 3:
        return loc.t('mode_failover');
      case 4:
        return loc.t('mode_weighted');
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(title: Text(loc.t('groups')), floating: true),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_groups.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text(loc.t('no_groups'))),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final g = _groups[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _modeLabel(g.mode, loc),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showGroupDialog(existing: g),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteGroup(g, loc),
                              ),
                            ],
                          ),
                          if (g.firstTokenTimeOut > 0)
                            Text(
                              '${loc.t("first_token_timeout")}: ${g.firstTokenTimeOut}${loc.t("second")}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (g.sessionKeepTime > 0)
                            Text(
                              '${loc.t("session_keep")}: ${g.sessionKeepTime}${loc.t("second")}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (g.items.isNotEmpty) ...[
                            Text(
                              '${loc.t("channels")}:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: g.items
                                  .map(
                                    (item) => Chip(
                                      label: Text(
                                        '${item.modelName} (ch:${item.channelId})',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }, childCount: _groups.length),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupItemDraft {
  int channelId;
  String modelName;
  int priority;
  int weight;

  _GroupItemDraft({
    this.channelId = 0,
    this.modelName = '',
    this.priority = 0,
    this.weight = 0,
  });
}
