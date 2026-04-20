import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
import 'package:octopusmanage/widgets/app_error_dialog.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      _urlController.text = provider.baseUrl;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      final loc = context.read<AppProvider>().loc;
      showErrorDialog(context, loc.t('required'));
      return;
    }

    setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.setBaseUrl(url);
      await provider.checkBootstrapStatus();
      if (!provider.needsBootstrap) {
        final success = await provider.login(
          username,
          password,
          rememberMe: _rememberMe,
        );
        if (!success && mounted) {
          final loc = provider.loc;
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: Text(loc.t('login_failed')),
              actions: [
                CupertinoDialogAction(
                  child: Text(loc.t('ok')),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  // App Icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.colorBlue,
                          AppTheme.colorBlue.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusXXLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colorBlue.withValues(alpha: 0.25),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.settings,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Octopus',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.37,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    loc.t('llm_api_manager'),
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
                          controller: _urlController,
                          placeholder: loc.t('server_url'),
                          icon: CupertinoIcons.globe,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
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
                        Row(
                          children: [
                            CupertinoSwitch(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loc.t('remember_me'),
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
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
                                    loc.t('login'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required ColorScheme colorScheme,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return CupertinoTextField(
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
    );
  }
}
