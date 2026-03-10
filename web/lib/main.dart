import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MeetSpaceApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);

class MeetSpaceApp extends StatefulWidget {
  const MeetSpaceApp({super.key});

  @override
  State<MeetSpaceApp> createState() => _MeetSpaceAppState();
}

class _MeetSpaceAppState extends State<MeetSpaceApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'meetspace',
      debugShowCheckedModeBanner: false,
      theme: meetSpaceLightTheme,
      darkTheme: meetSpaceDarkTheme,
      themeMode: themeNotifier.value,
      routerConfig: _router,
    );
  }
}
