import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../api/client.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
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
  double _radius = 25;
  List<EventResponse> _events = [];
  String? _nextCursor;
  bool _loading = true;
  String? _error;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _client = AuthService.instance.clientWithKey(widget.apiKey);
    _getLocationThenLoad();
  }

  Future<void> _getLocationThenLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _loadEvents();
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
          });
        }
      } catch (_) {
        // keep defaults
      }
    }
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _events = [];
      _nextCursor = null;
    });
    try {
      final res = await _client.getEventsNearby(_lat, _lng, _radius);
      if (!mounted) return;
      setState(() {
        _events = res.events;
        _nextCursor = res.nextCursor;
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

  Future<void> _loadMore() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _client.getEventsNearby(
        _lat,
        _lng,
        _radius,
        cursor: _nextCursor,
      );
      if (!mounted) return;
      setState(() {
        _events = [..._events, ...res.events];
        _nextCursor = res.nextCursor;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onRadiusChanged(double value) {
    setState(() => _radius = value);
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('meetspace'),
        actions: [
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
                  value: _radius,
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
                          itemCount: _events.length + (_nextCursor != null ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _events.length) {
                              if (_loadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: TextButton(
                                  onPressed: _loadMore,
                                  child: const Text('Load more'),
                                ),
                              );
                            }
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
