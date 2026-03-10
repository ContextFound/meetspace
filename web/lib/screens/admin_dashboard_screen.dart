import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/admin_api.dart';
import '../firebase_options.dart';
import '../models/admin.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminApiClient? _client;
  List<AdminAgent>? _agents;
  bool _loading = true;
  String? _error;

  String? _expandedAgentId;
  List<EventResponse>? _expandedEvents;
  bool _eventsLoading = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  Future<void> _initClient() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    final user = _user;
    if (user == null) {
      if (mounted) context.go('/admin');
      return;
    }
    final token = await user.getIdToken();
    if (!mounted) return;
    _client = AdminApiClient(jwt: token);
    _loadAgents();
  }

  Future<void> _refreshToken() async {
    final token = await _user?.getIdToken(true);
    if (token != null) {
      _client = AdminApiClient(jwt: token);
    }
  }

  Future<void> _loadAgents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _refreshToken();
      final response = await _client!.getAgents();
      if (mounted) {
        setState(() {
          _agents = response.agents;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleAgent(String agentId) async {
    if (_expandedAgentId == agentId) {
      setState(() {
        _expandedAgentId = null;
        _expandedEvents = null;
      });
      return;
    }

    setState(() {
      _expandedAgentId = agentId;
      _expandedEvents = null;
      _eventsLoading = true;
    });

    try {
      await _refreshToken();
      final events = await _client!.getAgentEvents(agentId);
      if (mounted) {
        setState(() {
          _expandedEvents = events;
          _eventsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _eventsLoading = false;
          _expandedEvents = [];
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('meetspace admin'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.photoURL != null)
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(user.photoURL!),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    user.email ?? '',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(
              themeNotifier.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: themeNotifier.isDark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: themeNotifier.toggle,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadAgents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final agents = _agents ?? [];
    if (agents.isEmpty) {
      return const Center(child: Text('No registered agents.'));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: RefreshIndicator(
          onRefresh: _loadAgents,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agents.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Text(
                        'Registered Agents',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${agents.length}',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        onPressed: _loadAgents,
                      ),
                    ],
                  ),
                );
              }

              final agent = agents[index - 1];
              final isExpanded = _expandedAgentId == agent.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleAgent(agent.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    agent.agentName,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    agent.email,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            _chip(theme, agent.tier),
                            const SizedBox(width: 12),
                            _chip(
                              theme,
                              '${agent.eventCount} event${agent.eventCount == 1 ? '' : 's'}',
                            ),
                            const SizedBox(width: 12),
                            if (!agent.isActive)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _chip(theme, 'inactive'),
                              ),
                            Text(
                              _formatDate(agent.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded) _buildExpandedEvents(theme),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withAlpha(120)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _buildExpandedEvents(ThemeData theme) {
    if (_eventsLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final events = _expandedEvents ?? [];
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No events created by this agent.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(15),
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Events',
              style: theme.textTheme.labelLarge,
            ),
          ),
          ...events.map((e) => _buildEventRow(theme, e)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEventRow(ThemeData theme, EventResponse event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  event.locationName,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _chip(theme, event.eventType),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              _formatDateTime(event.startAt),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$date $hour:$min';
  }
}
