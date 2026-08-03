import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/models/model_mapping.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_chips.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class ModelMappingPage extends StatefulWidget {
  const ModelMappingPage({super.key});

  @override
  State<ModelMappingPage> createState() => _ModelMappingPageState();
}

class _ModelMappingPageState extends State<ModelMappingPage> {
  List<ModelMapping> _mappings = [];
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
      _mappings = await api.getModelMappings();
      _mappings.sort((a, b) => a.priority.compareTo(b.priority));
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
      await api.createModelMapping(result);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _edit(ModelMapping mapping) async {
    final result = await _showEditDialog(mapping);
    if (result == null || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.updateModelMapping(result);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<void> _delete(ModelMapping mapping) async {
    final loc = context.read<AppProvider>().loc;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete'),
      content:
          loc.t('mapping_confirm_delete', {'name': mapping.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteModelMapping(mapping.id);
      await _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  Future<ModelMapping?> _showEditDialog(ModelMapping? existing) async {
    final loc = context.read<AppProvider>().loc;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final patternCtrl =
        TextEditingController(text: existing?.pattern ?? '');
    final targetCtrl =
        TextEditingController(text: existing?.targetModel ?? '');
    final priorityCtrl = TextEditingController(
        text: existing != null ? '${existing.priority}' : '0');
    String matchType = existing?.matchType ?? 'exact';
    bool enabled = existing?.enabled ?? true;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return CupertinoAlertDialog(
              title: Text(existing == null
                  ? loc.t('mapping_create')
                  : loc.t('mapping_edit')),
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
                        controller: patternCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('mapping_pattern'),
                          hintText: 'gpt-4*',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: matchType,
                        decoration: InputDecoration(
                          labelText: loc.t('mapping_match_type'),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['exact', 'wildcard', 'regex']
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => matchType = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: targetCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('mapping_target_model'),
                          hintText: 'claude-3-5-sonnet',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priorityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: loc.t('mapping_priority'),
                          hintText: '0',
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
    return ModelMapping(
      id: existing?.id ?? 0,
      name: nameCtrl.text.trim(),
      pattern: patternCtrl.text.trim(),
      matchType: matchType,
      targetModel: targetCtrl.text.trim(),
      priority: int.tryParse(priorityCtrl.text) ?? 0,
      enabled: enabled,
    );
  }

  Color _matchTypeColor(String type) {
    switch (type) {
      case 'exact':
        return AppTheme.colorBlue;
      case 'wildcard':
        return AppTheme.colorOrange;
      case 'regex':
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
              largeTitle: Text(loc.t('model_mappings')),
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
            else if (_mappings.isEmpty)
              SliverFillRemaining(
                child: AppEmptyState(
                  icon: CupertinoIcons.arrow_swap,
                  title: loc.t('mapping_empty'),
                  subtitle: loc.t('mapping_empty_hint'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mapping = _mappings[index];
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
                                    mapping.name,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                AppTypeChip(
                                  label: mapping.matchType,
                                  color: _matchTypeColor(mapping.matchType),
                                ),
                                if (!mapping.enabled) ...[
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        mapping.pattern,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontFamily: 'monospace',
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Icon(
                                        CupertinoIcons.arrow_right,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        mapping.targetModel,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontFamily: 'monospace',
                                          color: colorScheme.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${loc.t('mapping_priority')}: ${mapping.priority}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                switch (action) {
                                  case 'edit':
                                    _edit(mapping);
                                    break;
                                  case 'delete':
                                    _delete(mapping);
                                    break;
                                }
                              },
                              itemBuilder: (_) => [
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
                    childCount: _mappings.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
