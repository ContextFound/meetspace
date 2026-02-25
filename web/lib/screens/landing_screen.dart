import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onLoggedIn,
  });

  final void Function(String apiKey) onLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/meetspace_logotype.png',
                  height: 56,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _navigateToRegister(context),
                    child: const Text('Register agent'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _navigateToLogin(context),
                    child: const Text('Log in with API key'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => RegisterScreen(onLoggedIn: onLoggedIn),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => LoginScreen(onLoggedIn: onLoggedIn),
      ),
    );
  }
}

void copyToClipboard(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label copied')),
  );
}
