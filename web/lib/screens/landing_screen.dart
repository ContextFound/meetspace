import 'package:flutter/material.dart';

import '../api/client.dart';
import '../models/auth.dart';
import '../services/auth_service.dart';
import '../widgets/api_log_dialog.dart';
import 'show_key_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    required this.onLoggedIn,
  });

  final void Function(String apiKey) onLoggedIn;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _keyController = TextEditingController();
  bool _loginLoading = false;
  String? _loginError;

  final _registerFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _agentNameController = TextEditingController();
  bool _registerLoading = false;
  String? _registerError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    _agentNameController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _loginError = 'Enter your API key');
      return;
    }
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });
    try {
      final valid = await AuthService.instance.validateKey(key);
      if (!mounted) return;
      if (valid) {
        widget.onLoggedIn(key);
      } else {
        setState(() {
          _loginError = 'Invalid or inactive API key';
          _loginLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = e.toString();
        _loginLoading = false;
      });
    }
  }

  Future<void> _submitRegister() async {
    _registerError = null;
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() {
      _registerLoading = true;
      _registerError = null;
    });
    try {
      final client = MeetSpaceApiClient();
      final res = await client.register(RegisterRequest(
        email: _emailController.text.trim(),
        agentName: _agentNameController.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ShowKeyScreen(
            apiKey: res.apiKey,
            keyPrefix: res.keyPrefix,
            tier: res.tier,
            onContinue: () {
              widget.onLoggedIn(res.apiKey);
              if (!context.mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(context).popUntil((r) => r.isFirst);
              });
            },
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _registerError = e.message;
        _registerLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _registerError = e.toString();
        _registerLoading = false;
      });
    }
  }

  void _showApiLog() => showApiLogDialog(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/meetspace_logotype.png',
                        width: 500,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(text: 'Log in'),
                                Tab(text: 'Register'),
                              ],
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: _tabController.index == 0
                                    ? _buildLoginForm()
                                    : _buildRegisterForm(),
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
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.bug_report_outlined),
                tooltip: 'API call log',
                onPressed: _showApiLog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Paste the API key you received when you registered.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        if (_loginError != null) ...[
          Text(
            _loginError!,
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
          onSubmitted: (_) => _submitLogin(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loginLoading ? null : _submitLogin,
          child: _loginLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Log in'),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_registerError != null) ...[
            Text(
              _registerError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agentNameController,
            decoration: const InputDecoration(
              labelText: 'Agent name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _registerLoading ? null : _submitRegister,
            child: _registerLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Register'),
          ),
        ],
      ),
    );
  }
}

