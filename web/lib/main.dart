import 'package:flutter/material.dart';

import 'screens/events_list_screen.dart';
import 'screens/landing_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MeetSpaceApp());
}

class MeetSpaceApp extends StatefulWidget {
  const MeetSpaceApp({super.key});

  @override
  State<MeetSpaceApp> createState() => _MeetSpaceAppState();
}

class _MeetSpaceAppState extends State<MeetSpaceApp> {
  String? _apiKey;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await AuthService.instance.getStoredApiKey();
    if (mounted) {
      setState(() {
        _apiKey = key;
        _loading = false;
      });
    }
  }

  void _onLoggedIn(String key) async {
    await AuthService.instance.saveApiKey(key);
    if (mounted) setState(() => _apiKey = key);
  }

  void _onLogout() async {
    await AuthService.instance.clearApiKey();
    if (mounted) setState(() => _apiKey = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'meetspace',
      debugShowCheckedModeBanner: false,
      theme: meetSpaceTheme,
      home: _loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _apiKey == null
              ? LandingScreen(onLoggedIn: _onLoggedIn)
              : EventsListScreen(
                  apiKey: _apiKey!,
                  onLogout: _onLogout,
                ),
    );
  }
}
