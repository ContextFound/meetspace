import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth.dart';
import '../models/event.dart';
import 'config.dart';

class ApiLogEntry {
  ApiLogEntry({
    required this.method,
    required this.url,
    required this.statusCode,
    required this.timestamp,
    this.requestBody,
    this.responseBody,
    this.error,
    required this.duration,
  });

  final String method;
  final String url;
  final int? statusCode;
  final DateTime timestamp;
  final String? requestBody;
  final String? responseBody;
  final String? error;
  final Duration duration;
}

class ApiLog {
  ApiLog._();
  static final instance = ApiLog._();

  final List<ApiLogEntry> entries = [];
  static const _maxEntries = 100;

  void add(ApiLogEntry entry) {
    entries.insert(0, entry);
    if (entries.length > _maxEntries) entries.removeLast();
  }

  void clear() => entries.clear();
}

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

  Future<http.Response> _loggedRequest(
    String method,
    String url,
    Future<http.Response> Function() action, {
    String? requestBody,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final r = await action();
      stopwatch.stop();
      ApiLog.instance.add(ApiLogEntry(
        method: method,
        url: url,
        statusCode: r.statusCode,
        timestamp: DateTime.now(),
        requestBody: requestBody,
        responseBody: r.body.isEmpty ? null : r.body,
        duration: stopwatch.elapsed,
      ));
      return r;
    } catch (e) {
      stopwatch.stop();
      ApiLog.instance.add(ApiLogEntry(
        method: method,
        url: url,
        statusCode: null,
        timestamp: DateTime.now(),
        requestBody: requestBody,
        error: e.toString(),
        duration: stopwatch.elapsed,
      ));
      rethrow;
    }
  }

  /// Register a new agent. No API key required.
  Future<RegisterResponse> register(RegisterRequest req) async {
    final body = jsonEncode(req.toJson());
    final url = _url('/v1/auth/register');
    final r = await _loggedRequest('POST', url, requestBody: body, () {
      return http.post(Uri.parse(url), headers: _headers, body: body);
    });
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

  /// List events near (lat, lng) within radius miles. Omit radius for all events.
  Future<EventsNearbyResponse> getEventsNearby(
    double lat,
    double lng,
    double? radius, {
    String? cursor,
    int limit = 20,
  }) async {
    var q = 'lat=$lat&lng=$lng&limit=$limit';
    if (radius != null) q += '&radius=$radius';
    final url = cursor != null
        ? _url('/v1/events/nearby?$q&cursor=${Uri.encodeComponent(cursor)}')
        : _url('/v1/events/nearby?$q');
    final r = await _loggedRequest('GET', url, () {
      return http.get(Uri.parse(url), headers: _headers);
    });
    return _handleResponse(r, EventsNearbyResponse.fromJson);
  }

  /// Get a single event by ID.
  Future<EventResponse> getEvent(String eventId) async {
    final url = _url('/v1/events/${Uri.encodeComponent(eventId)}');
    final r = await _loggedRequest('GET', url, () {
      return http.get(Uri.parse(url), headers: _headers);
    });
    return _handleResponse(r, EventResponse.fromJson);
  }

  /// Health check. No API key required.
  Future<bool> healthCheck() async {
    final url = _url('/health');
    final r = await _loggedRequest('GET', url, () {
      return http.get(Uri.parse(url), headers: _headers);
    });
    return r.statusCode == 200;
  }

  /// Create an event. Requires readwrite tier (403 if read-only).
  Future<EventResponse> createEvent(EventCreate body) async {
    final reqBody = jsonEncode(body.toJson());
    final url = _url('/v1/events');
    final r = await _loggedRequest('POST', url, requestBody: reqBody, () {
      return http.post(Uri.parse(url), headers: _headers, body: reqBody);
    });
    return _handleResponse(r, EventResponse.fromJson);
  }
}
