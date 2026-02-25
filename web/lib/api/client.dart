import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth.dart';
import '../models/event.dart';
import 'config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException(this.statusCode, this.message, [this.code]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class MeetSpaceApiClient {
  MeetSpaceApiClient({this.apiKey, String? baseUrl})
      : _baseUrl = baseUrl ?? apiBaseUrl;

  final String _baseUrl;
  final String? apiKey;

  Map<String, String> get _headers {
    final m = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      m['X-API-Key'] = apiKey!;
    }
    return m;
  }

  String _url(String path) => '$_baseUrl$path';

  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parse,
  ) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Future.value(parse(body as Map<String, dynamic>));
    }
    String message = 'Request failed';
    String? code;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is Map<String, dynamic>) {
        message = err['message'] as String? ?? message;
        code = err['code'] as String?;
      }
    }
    throw ApiException(response.statusCode, message, code);
  }

  /// Register a new agent. No API key required.
  Future<RegisterResponse> register(RegisterRequest req) async {
    final r = await http.post(
      Uri.parse(_url('/v1/auth/register')),
      headers: _headers,
      body: jsonEncode(req.toJson()),
    );
    return _handleResponse(r, RegisterResponse.fromJson);
  }

  /// Validate API key by calling a protected endpoint. Returns true if valid.
  Future<bool> validateKey(String key) async {
    final client = MeetSpaceApiClient(apiKey: key, baseUrl: _baseUrl);
    try {
      await client.getEventsNearby(0, 0, 1, limit: 1);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) return false;
      rethrow;
    }
  }

  /// List events near (lat, lng) within radius miles.
  Future<EventsNearbyResponse> getEventsNearby(
    double lat,
    double lng,
    double radius, {
    String? cursor,
    int limit = 20,
  }) async {
    final q = 'lat=$lat&lng=$lng&radius=$radius&limit=$limit';
    final uri = cursor != null
        ? _url('/v1/events/nearby?$q&cursor=${Uri.encodeComponent(cursor)}')
        : _url('/v1/events/nearby?$q');
    final r = await http.get(Uri.parse(uri), headers: _headers);
    return _handleResponse(r, EventsNearbyResponse.fromJson);
  }

  /// Get a single event by ID.
  Future<EventResponse> getEvent(String eventId) async {
    final r = await http.get(
      Uri.parse(_url('/v1/events/${Uri.encodeComponent(eventId)}')),
      headers: _headers,
    );
    return _handleResponse(r, EventResponse.fromJson);
  }

  /// Create an event. Requires readwrite tier (403 if read-only).
  Future<EventResponse> createEvent(EventCreate body) async {
    final r = await http.post(
      Uri.parse(_url('/v1/events')),
      headers: _headers,
      body: jsonEncode(body.toJson()),
    );
    return _handleResponse(r, EventResponse.fromJson);
  }
}
