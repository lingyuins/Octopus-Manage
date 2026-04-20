import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/llm.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_dialogs.dart';
import 'package:octopusmanage/widgets/app_empty_state.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class ModelPage extends StatefulWidget {
  const ModelPage({super.key});

  @override
  State<ModelPage> createState() => _ModelPageState();
}

class _ModelPageState extends State<ModelPage> {
  List<LLMInfo> _models = [];
  List<LLMChannel> _modelChannels = [];
  bool _loading = true;
  bool _syncingPrice = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AppProvider>().api;
      final results = await Future.wait([
        api.getModels(),
        api.getModelChannels(),
      ]);
      if (!mounted) return;
      setState(() {
        _models = (results[0] as List<LLMInfo>)
          ..sort((a, b) => a.name.compareTo(b.name));
        _modelChannels = results[1] as List<LLMChannel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _syncModelPrice(AppLocalizations loc) async {
    if (_syncingPrice) return;
    setState(() => _syncingPrice = true);
    try {
      final api = context.read<AppProvider>().api;
      await api.updateModelPrice();
      await _loadModels();
      if (mounted) {
        await AppTextDialog.show(
          context: context,
          title: loc.t('sync_prices'),
          content: loc.t('model_price_sync_success'),
          buttonText: loc.t('ok'),
          selectable: false,
        );
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(
          context,
          e.toString(),
          title: loc.t('model_price_sync_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _syncingPrice = false);
    }
  }

  Future<void> _deleteModel(LLMInfo model, AppLocalizations loc) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: loc.t('delete_model'),
      content: loc.t('delete_confirm', {'name': model.name}),
      confirmText: loc.t('delete'),
      cancelText: loc.t('cancel'),
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      final api = context.read<AppProvider>().api;
      await api.deleteModel(model.name);
      await _loadModels();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Future<void> _showModelDialog({
    LLMInfo? existing,
    required AppLocalizations loc,
  }) async {
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final inputCtl = TextEditingController(
      text: existing != null ? existing.input.toString() : '0',
    );
    final outputCtl = TextEditingController(
      text: existing != null ? existing.output.toString() : '0',
    );
    final cacheReadCtl = TextEditingController(
      text: existing != null ? existing.cacheRead.toString() : '0',
    );
    final cacheWriteCtl = TextEditingController(
      text: existing != null ? existing.cacheWrite.toString() : '0',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(isEdit ? loc.t('edit_model') : loc.t('create_model')),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNumberField(
                  ctx,
                  controller: nameCtl,
                  placeholder: loc.t('model_name'),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildNumberField(
                  ctx,
                  controller: inputCtl,
                  placeholder: loc.t('input_price'),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildNumberField(
                  ctx,
                  controller: outputCtl,
                  placeholder: loc.t('output_price'),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildNumberField(
                  ctx,
                  controller: cacheReadCtl,
                  placeholder: loc.t('cache_read_price'),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildNumberField(
                  ctx,
                  controller: cacheWriteCtl,
                  placeholder: loc.t('cache_write_price'),
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
      ),
    );

    final nextModel = LLMInfo(
      name: nameCtl.text.trim(),
      input: double.tryParse(inputCtl.text.trim()) ?? 0,
      output: double.tryParse(outputCtl.text.trim()) ?? 0,
      cacheRead: double.tryParse(cacheReadCtl.text.trim()) ?? 0,
      cacheWrite: double.tryParse(cacheWriteCtl.text.trim()) ?? 0,
    );

    nameCtl.dispose();
    inputCtl.dispose();
    outputCtl.dispose();
    cacheReadCtl.dispose();
    cacheWriteCtl.dispose();

    if (result != true || nextModel.name.isEmpty || !mounted) return;

    try {
      final api = context.read<AppProvider>().api;
      if (isEdit) {
        await api.updateModel(nextModel);
      } else {
        await api.createModel(nextModel);
      }
      await _loadModels();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, e.toString());
      }
    }
  }

  Widget _buildNumberField(
    BuildContext context, {
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      padding: const EdgeInsets.all(12),
      keyboardType: keyboardType,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
    );
  }

  List<LLMChannel> _channelsForModel(String modelName) {
    return _modelChannels.where((item) => item.name == modelName).toList()
      ..sort((a, b) => a.channelName.compareTo(b.channelName));
  }

  String _formatPrice(double value) {
    return value == 0 ? '0' : value.toStringAsFixed(6);
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
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text(loc.t('models')),
                  backgroundColor: AppTheme.getSurfaceLowest(
                    colorScheme,
                  ).withValues(alpha: 0.85),
                  border: null,
                  trailing: GestureDetector(
                    onTap: _syncingPrice ? null : () => _syncModelPrice(loc),
                    child: _syncingPrice
                        ? const CupertinoActivityIndicator(radius: 10)
                        : Icon(
                            CupertinoIcons.refresh,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                  ),
                ),
                CupertinoSliverRefreshControl(onRefresh: _loadModels),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoadingState(),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: AppErrorState(
                      message: _error!,
                      onRetry: _loadModels,
                    ),
                  )
                else if (_models.isEmpty)
                  SliverFillRemaining(
                    child: AppEmptyState(
                      icon: CupertinoIcons.cube_box,
                      title: loc.t('no_models'),
                      subtitle: loc.t('create_first_model'),
                      action: CupertinoButton.filled(
                        onPressed: () => _showModelDialog(loc: loc),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.add, size: 18),
                            const SizedBox(width: 4),
                            Text(loc.t('create_model')),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final model = _models[index];
                        final channels = _channelsForModel(model.name);
                        return AppCard(
                          margin: const EdgeInsets.fromLTRB(
                            AppTheme.spacingLg,
                            AppTheme.spacingSm,
                            AppTheme.spacingLg,
                            0,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          model.name,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppTheme.spacingXs,
                                        ),
                                        Text(
                                          '${loc.t('linked_channels')}: ${channels.length}',
                                          style: theme.textTheme.caption
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showModelDialog(
                                      existing: model,
                                      loc: loc,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.pencil,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  GestureDetector(
                                    onTap: () => _deleteModel(model, loc),
                                    child: Icon(
                                      CupertinoIcons.delete,
                                      size: 20,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Wrap(
                                spacing: AppTheme.spacingSm,
                                runSpacing: AppTheme.spacingSm,
                                children: [
                                  _PriceChip(
                                    label: loc.t('input'),
                                    value: _formatPrice(model.input),
                                    color: AppTheme.colorBlue,
                                  ),
                                  _PriceChip(
                                    label: loc.t('output'),
                                    value: _formatPrice(model.output),
                                    color: AppTheme.colorGreen,
                                  ),
                                  _PriceChip(
                                    label: loc.t('cache_read_price_short'),
                                    value: _formatPrice(model.cacheRead),
                                    color: AppTheme.colorPurple,
                                  ),
                                  _PriceChip(
                                    label: loc.t('cache_write_price_short'),
                                    value: _formatPrice(model.cacheWrite),
                                    color: AppTheme.colorOrange,
                                  ),
                                ],
                              ),
                              if (channels.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingMd),
                                Wrap(
                                  spacing: AppTheme.spacingSm,
                                  runSpacing: AppTheme.spacingXs,
                                  children: channels
                                      .map(
                                        (item) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingSm,
                                            vertical: AppTheme.spacingXs,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (item.enabled
                                                        ? AppTheme.colorBlue
                                                        : AppTheme.colorGray)
                                                    .withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusXLarge,
                                            ),
                                          ),
                                          child: Text(
                                            item.channelName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: item.enabled
                                                  ? AppTheme.colorBlue
                                                  : AppTheme.colorGray,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        );
                      }, childCount: _models.length),
                    ),
                  ),
              ],
            ),
            if (!_loading && _models.isNotEmpty)
              Positioned(
                right: AppTheme.spacingLg,
                bottom: 24,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.getShadowMedium(colorScheme),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(28),
                    color: colorScheme.primary,
                    onPressed: () => _showModelDialog(loc: loc),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 16),
                        const Icon(
                          CupertinoIcons.add,
                          size: 22,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.t('create_model'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
