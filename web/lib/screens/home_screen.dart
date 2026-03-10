import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'events_list_screen.dart';
import 'landing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_apiKey == null) {
      return LandingScreen(onLoggedIn: _onLoggedIn);
    }
    return EventsListScreen(
      apiKey: _apiKey!,
      onLogout: _onLogout,
    );
  }
}
