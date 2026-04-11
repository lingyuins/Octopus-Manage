import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:octopusmanage/pages/login_page.dart';
import 'package:octopusmanage/pages/home_page.dart';
import 'package:octopusmanage/pages/bootstrap_page.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'Octopus Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      locale: provider.flutterLocale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final error = provider.error;

    return Scaffold(
      body: Column(
        children: [
          if (error != null)
            Material(
              color: Colors.red.shade100,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(error, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: provider.clearError,
                ),
              ),
            ),
          Expanded(
            child: provider.isLoggedIn
                ? const HomePage()
                : provider.needsBootstrap
                ? const BootstrapPage()
                : const LoginPage(),
          ),
        ],
      ),
    );
  }
}
