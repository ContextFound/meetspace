enum Audience { kids, adults, all }

enum EventType {
  workshop,
  performance,
  festival,
  market,
  competition,
  game,
  social,
  meetup,
  club,
  support,
  talk,
  conference,
  exhibition,
  tour,
  ceremony,
}

extension EventTypeX on EventType {
  String get value => name;
}

extension AudienceX on Audience {
  String get value => name;
}

class EventCreate {
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime? endAt;
  final String timezone;
  final String locationName;
  final String? address;
  final double lat;
  final double lng;
  final String? url;
  final double? price;
  final String? currency;
  final Audience audience;
  final EventType eventType;

  EventCreate({
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    required this.timezone,
    required this.locationName,
    this.address,
    required this.lat,
    required this.lng,
    this.url,
    this.price,
    this.currency,
    required this.audience,
    required this.eventType,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'title': title,
      'start_at': startAt.toUtc().toIso8601String(),
      'timezone': timezone,
      'location_name': locationName,
      'lat': lat,
      'lng': lng,
      'audience': audience.value,
      'event_type': eventType.value,
    };
    if (description != null) m['description'] = description;
    if (endAt != null) m['end_at'] = endAt!.toUtc().toIso8601String();
    if (address != null) m['address'] = address;
    if (url != null) m['url'] = url;
    if (price != null) {
      m['price'] = price;
      m['currency'] = currency ?? 'USD';
    }
    return m;
  }
}

class EventResponse {
  final String eventId;
  final String agentId;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime? endAt;
  final String timezone;
  final String locationName;
  final String? address;
  final double lat;
  final double lng;
  final String? url;
  final double? price;
  final String? currency;
  final String audience;
  final String eventType;
  final DateTime createdAt;

  EventResponse({
    required this.eventId,
    required this.agentId,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    required this.timezone,
    required this.locationName,
    this.address,
    required this.lat,
    required this.lng,
    this.url,
    this.price,
    this.currency,
    required this.audience,
    required this.eventType,
    required this.createdAt,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      eventId: json['event_id'] as String,
      agentId: json['agent_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : null,
      timezone: json['timezone'] as String,
      locationName: json['location_name'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      url: json['url'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      currency: json['currency'] as String?,
      audience: json['audience'] as String,
      eventType: json['event_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class EventsNearbyResponse {
  final List<EventResponse> events;
  final String? nextCursor;

  EventsNearbyResponse({required this.events, this.nextCursor});

  factory EventsNearbyResponse.fromJson(Map<String, dynamic> json) {
    return EventsNearbyResponse(
      events: (json['events'] as List<dynamic>)
          .map((e) => EventResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );
  }
}
