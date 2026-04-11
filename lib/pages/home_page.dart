import 'package:flutter/material.dart';
import 'package:octopusmanage/pages/dashboard_page.dart';
import 'package:octopusmanage/pages/channel_page.dart';
import 'package:octopusmanage/pages/group_page.dart';
import 'package:octopusmanage/pages/api_key_page.dart';
import 'package:octopusmanage/pages/log_page.dart';
import 'package:octopusmanage/pages/setting_page.dart';
import 'package:octopusmanage/providers/app_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    ChannelPage(),
    GroupPage(),
    ApiKeyPage(),
    LogPage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard),
            label: loc.t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.alt_route),
            label: loc.t('channels'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_tree),
            label: loc.t('groups'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.vpn_key),
            label: loc.t('api_keys'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long),
            label: loc.t('logs'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: loc.t('settings'),
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
