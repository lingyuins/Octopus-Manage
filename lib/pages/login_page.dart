import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:octopusmanage/theme/app_theme.dart';
import 'package:octopusmanage/widgets/app_card.dart';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.setBaseUrl(_urlController.text.trim());
      await provider.checkBootstrapStatus();
      if (!provider.needsBootstrap) {
        final success = await provider.login(
          _usernameController.text.trim(),
          _passwordController.text,
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
                      CupertinoIcons.settings,
                      size: 44,
                      color: colorScheme.onPrimary,
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
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXxl),
                  AppCard(
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _urlController,
                          placeholder: loc.t('server_url'),
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              CupertinoIcons.globe,
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
}
