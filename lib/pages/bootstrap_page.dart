import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:provider/provider.dart';

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      final success = await provider.createAdmin(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        final loc = provider.loc;
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(loc.t('admin_created')),
            actions: [
              CupertinoDialogAction(
                child: Text(loc.t('ok')),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else if (!success && mounted) {
        final loc = provider.loc;
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text(loc.t('bootstrap_failed')),
            actions: [
              CupertinoDialogAction(
                child: Text(loc.t('ok')),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.light,
    );

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.getSurfaceLowest(colorScheme),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingXxl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusXXLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.shield,
                      size: 44,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    loc.t('initial_setup'),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.37,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    loc.t('create_admin_account'),
                    style: TextStyle(
                      fontSize: 17,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXxl),
                  AppCard(
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _usernameController,
                          placeholder: loc.t('username'),
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              CupertinoIcons.person,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.brightness == Brightness.light
                                ? const Color(0xFFE5E5EA)
                                : const Color(0xFF3A3A3C),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        CupertinoTextField(
                          controller: _passwordController,
                          placeholder: loc.t('password'),
                          obscureText: _obscurePassword,
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              CupertinoIcons.lock,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          suffix: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                _obscurePassword
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.brightness == Brightness.light
                                ? const Color(0xFFE5E5EA)
                                : const Color(0xFF3A3A3C),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              loc.t('password_min_length'),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        CupertinoTextField(
                          controller: _confirmPasswordController,
                          placeholder: loc.t('confirm_password'),
                          obscureText: _obscureConfirm,
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              CupertinoIcons.lock,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          suffix: GestureDetector(
                            onTap: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                _obscureConfirm
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.brightness == Brightness.light
                                ? const Color(0xFFE5E5EA)
                                : const Color(0xFF3A3A3C),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: CupertinoButton(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                            color: colorScheme.primary,
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const CupertinoActivityIndicator(radius: 12)
                                : Text(
                                    loc.t('create_admin'),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
