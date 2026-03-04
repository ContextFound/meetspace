import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../api/client.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/api_log_dialog.dart';
import '../widgets/logotype_header.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

const List<double> _radiusOptions = [5, 10, 25, 50];

/// Default center (SF) when location is unavailable.
const double _defaultLat = 37.7749;
const double _defaultLng = -122.4194;

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({
    super.key,
    required this.apiKey,
    required this.onLogout,
  });

  final String apiKey;
  final VoidCallback onLogout;

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  late MeetSpaceApiClient _client;
  double _lat = _defaultLat;
  double _lng = _defaultLng;
  double _selectedRadius = 25;
  bool _anyDistance = true;
  List<EventResponse> _events = [];
  int _count = 0;
  int _total = 0;
  bool _loading = true;
  String? _error;

  /// Incremented each time the user manually triggers a load (e.g. filter
  /// change) so a stale geolocation callback doesn't fire a duplicate load.
  int _loadGeneration = 0;

  double? get _effectiveRadius => _anyDistance ? null : _selectedRadius;

  @override
  void initState() {
    super.initState();
    _client = AuthService.instance.clientWithKey(widget.apiKey);
    _getLocationThenLoad();
  }

  /// Wraps [Geolocator.getCurrentPosition] in a guarded zone so that
  /// interop type errors from geolocator_web (LegacyJavaScriptObject cast
  /// failure) are caught instead of crashing the app. Times out after 5s
  /// to avoid hanging forever when the browser never resolves.
  Future<Position?> _safeGetCurrentPosition() {
    final completer = Completer<Position?>();
    final timer = Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.complete(null);
    });
    runZonedGuarded(() async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        if (!completer.isCompleted) completer.complete(pos);
      } catch (_) {
        if (!completer.isCompleted) completer.complete(null);
      }
    }, (_, __) {
      if (!completer.isCompleted) completer.complete(null);
    });
    return completer.future.whenComplete(() => timer.cancel());
  }

  Future<void> _getLocationThenLoad() async {
    final gen = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await _safeGetCurrentPosition();
          if (pos != null && mounted) {
            setState(() {
              _lat = pos.latitude;
              _lng = pos.longitude;
            });
          }
        }
      }
    } catch (_) {
      // Geolocation unavailable – fall back to defaults.
    }
    if (gen == _loadGeneration) {
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _events = [];
      _count = 0;
      _total = 0;
    });
    try {
      final res = await _client.getEventsNearby(_lat, _lng, _effectiveRadius);
      if (!mounted) return;
      setState(() {
        _events = res.events;
        _count = res.count;
        _total = res.total;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onRadiusChanged(double value) {
    _loadGeneration++;
    setState(() {
      _selectedRadius = value;
      _anyDistance = false;
    });
    _loadEvents();
  }

  void _onAnyDistance() {
    _loadGeneration++;
    setState(() => _anyDistance = true);
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 160,
        leading: const LogotypeHeader(),
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'API call log',
            onPressed: () => showApiLogDialog(context),
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
            onPressed: widget.onLogout,
            tooltip: 'Log out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateEvent(context),
        tooltip: 'Create event',
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Within',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _selectedRadius,
                  items: _radiusOptions
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text('$r mi'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _onRadiusChanged(v);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Any'),
                  selected: _anyDistance,
                  onSelected: (selected) {
                    if (selected) {
                      _onAnyDistance();
                    } else {
                      _onRadiusChanged(_selectedRadius);
                    }
                  },
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!_loading && _events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _total > _count
                    ? 'Showing $_count of $_total events'
                    : '$_total events',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Text(
                          'No events nearby',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 24,
                          ),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return _EventTile(
                              event: event,
                              onTap: () => _openDetail(event.eventId),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openDetail(String eventId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(
          eventId: eventId,
          client: _client,
        ),
      ),
    );
  }

  void _openCreateEvent(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          client: _client,
          onCreated: _loadEvents,
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onTap,
  });

  final EventResponse event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = event.startAt;
    final dateStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final timeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
          '$dateStr $timeStr · ${event.locationName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
