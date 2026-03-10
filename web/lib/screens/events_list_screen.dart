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

const List<double> _radiusOptions = [5, 10, 25, 50];

/// Default center (SF) when location is unavailable.
const double _defaultLat = 37.7749;
const double _defaultLng = -122.4194;

enum _SortOrder { date, distance }

const _metersPerMile = 1609.34;

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
  _SortOrder _sortOrder = _SortOrder.date;
  List<EventResponse> _events = [];
  int _count = 0;
  int _total = 0;
  bool _loading = true;
  String? _error;
  String? _expandedEventId;

  /// Incremented each time the user manually triggers a load (e.g. filter
  /// change) so a stale geolocation callback doesn't fire a duplicate load.
  int _loadGeneration = 0;

  double? get _effectiveRadius => _anyDistance ? null : _selectedRadius;

  double _distanceMiles(EventResponse e) =>
      Geolocator.distanceBetween(_lat, _lng, e.lat, e.lng) / _metersPerMile;

  List<EventResponse> get _sortedEvents {
    if (_sortOrder == _SortOrder.distance) {
      return List<EventResponse>.from(_events)
        ..sort((a, b) => _distanceMiles(a).compareTo(_distanceMiles(b)));
    }
    return _events;
  }

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
        leadingWidth: 300,
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Within',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                const SizedBox(width: 8),
                SegmentedButton<_SortOrder>(
                  segments: const [
                    ButtonSegment(
                      value: _SortOrder.date,
                      label: Text('Date'),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: _SortOrder.distance,
                      label: Text('Distance'),
                      icon: Icon(Icons.near_me, size: 16),
                    ),
                  ],
                  selected: {_sortOrder},
                  onSelectionChanged: (v) =>
                      setState(() => _sortOrder = v.first),
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
                        child: Builder(builder: (context) {
                          final sorted = _sortedEvents;
                          return ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 24,
                            ),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final event = sorted[index];
                              return _EventTile(
                                key: ValueKey(event.eventId),
                                event: event,
                                distanceMiles: _distanceMiles(event),
                                showDistance:
                                    _sortOrder == _SortOrder.distance,
                                isExpanded:
                                    _expandedEventId == event.eventId,
                                onTap: () {
                                  setState(() {
                                    _expandedEventId =
                                        _expandedEventId == event.eventId
                                            ? null
                                            : event.eventId;
                                  });
                                },
                              );
                            },
                          );
                        }),
                      ),
          ),
        ],
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
    super.key,
    required this.event,
    required this.distanceMiles,
    this.showDistance = false,
    required this.isExpanded,
    required this.onTap,
  });

  final EventResponse event;
  final double distanceMiles;
  final bool showDistance;
  final bool isExpanded;
  final VoidCallback onTap;

  static String _formatDt(DateTime dt) {
    final d = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = event.startAt;
    final dateStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final timeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final distStr = distanceMiles < 0.1
        ? '< 0.1 mi'
        : '${distanceMiles.toStringAsFixed(1)} mi';
    final subtitle = showDistance
        ? '$distStr · $dateStr $timeStr · ${event.locationName}'
        : '$dateStr $timeStr · ${event.locationName}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(event.title),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            onTap: onTap,
          ),
          if (isExpanded) _buildDetails(theme),
        ],
      ),
    );
  }

  Widget _buildDetails(ThemeData theme) {
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(150),
    );
    final valueStyle = theme.textTheme.bodySmall;

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: labelStyle),
            ),
            Expanded(child: Text(value, style: valueStyle)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(20),
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null && event.description!.isNotEmpty)
              row('Description', event.description!),
            row('Start', _formatDt(event.startAt)),
            if (event.endAt != null)
              row('End', _formatDt(event.endAt!)),
            row('Timezone', event.timezone),
            row('Location', event.locationName),
            if (event.address != null && event.address!.isNotEmpty)
              row('Address', event.address!),
            row('Type', event.eventType),
            row('Audience', event.audience),
            if (event.cost != null && event.cost!.isNotEmpty)
              row('Cost', event.cost!),
            if (event.url != null && event.url!.isNotEmpty)
              row('URL', event.url!),
            row('Distance', distanceMiles < 0.1
                ? '< 0.1 mi'
                : '${distanceMiles.toStringAsFixed(1)} mi'),
          ],
        ),
      ),
    );
  }
}
