import 'package:flutter/cupertino.dart';
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.light,
    );

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: colorScheme.brightness == Brightness.light
            ? const Color(0xFFF9F9F9).withValues(alpha: 0.94)
            : const Color(0xFF1C1C1E).withValues(alpha: 0.94),
        activeColor: colorScheme.primary,
        inactiveColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        height: 56,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            label: loc.t('home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.arrow_3_trianglepath),
            label: loc.t('channels'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.folder),
            label: loc.t('groups'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tag),
            label: loc.t('api_keys'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text),
            label: loc.t('logs'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: loc.t('settings'),
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(builder: (context) => _pages[index]);
      },
    );
  }
}
