import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoggedIn,
  });

  final void Function(String apiKey) onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _keyController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Enter your API key');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final valid = await AuthService.instance.validateKey(key);
      if (!mounted) return;
      if (valid) {
        widget.onLoggedIn(key);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).popUntil((r) => r.isFirst);
        });
      } else {
        setState(() {
          _error = 'Invalid or inactive API key';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log in'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste the API key you received when you registered.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'API key',
                  border: OutlineInputBorder(),
                  hintText: 'ms_test_xxxxxxxx...',
                ),
                obscureText: true,
                autocorrect: false,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
