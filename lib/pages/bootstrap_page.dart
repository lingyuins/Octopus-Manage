import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
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
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final loc = context.read<AppProvider>().loc;

    if (username.isEmpty || password.isEmpty) {
      showErrorDialog(context, loc.t('required'));
      return;
    }
    if (password.length < 12) {
      showErrorDialog(context, loc.t('password_too_short'));
      return;
    }
    if (password != confirm) {
      showErrorDialog(context, loc.t('password_mismatch'));
      return;
    }

    setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      final success = await provider.createAdmin(username, password);
      if (success && mounted) {
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
        showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required ColorScheme colorScheme,
    bool obscureText = false,
    Widget? suffix,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          obscureText: obscureText,
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          ),
          suffix: suffix,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.getInputBackground(colorScheme),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppTheme.colorBlue,
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
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.colorOrange,
                          AppTheme.colorOrange.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusXXLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colorOrange.withValues(alpha: 0.25),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.shield,
                      size: 40,
                      color: Colors.white,
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
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXxl),
                  AppCard(
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    elevated: true,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _usernameController,
                          placeholder: loc.t('username'),
                          icon: CupertinoIcons.person,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildTextField(
                          controller: _passwordController,
                          placeholder: loc.t('password'),
                          icon: CupertinoIcons.lock,
                          colorScheme: colorScheme,
                          obscureText: _obscurePassword,
                          hint: loc.t('password_min_length'),
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
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          placeholder: loc.t('confirm_password'),
                          icon: CupertinoIcons.lock,
                          colorScheme: colorScheme,
                          obscureText: _obscureConfirm,
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
