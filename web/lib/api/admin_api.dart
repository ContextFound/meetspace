import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin.dart';
import '../models/event.dart';
import 'config.dart';

class AdminApiClient {
  AdminApiClient({this.jwt, String? baseUrl})
      : _baseUrl = baseUrl ?? apiBaseUrl;

  final String _baseUrl;
  final String? jwt;

  Map<String, String> get _headers {
    final m = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (jwt != null) {
      m['Authorization'] = 'Bearer $jwt';
    }
    return m;
  }

  String _url(String path) => '$_baseUrl$path';

  Future<AdminAgentListResponse> getAgents() async {
    final url = _url('/v1/admin/agents');
    final r = await http.get(Uri.parse(url), headers: _headers);
    if (r.statusCode == 200) {
      return AdminAgentListResponse.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_extractError(r));
  }

  Future<List<EventResponse>> getAgentEvents(String agentId) async {
    final url = _url('/v1/admin/agents/$agentId/events');
    final r = await http.get(Uri.parse(url), headers: _headers);
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (data['events'] as List)
          .map((e) => EventResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(r));
  }

  Future<void> deleteEvent(String eventId) async {
    final url = _url('/v1/admin/events/$eventId');
    final r = await http.delete(Uri.parse(url), headers: _headers);
    if (r.statusCode != 204) {
      throw Exception(_extractError(r));
    }
  }

  Future<void> deleteAgentEvents(String agentId) async {
    final url = _url('/v1/admin/agents/$agentId/events');
    final r = await http.delete(Uri.parse(url), headers: _headers);
    if (r.statusCode != 204) {
      throw Exception(_extractError(r));
    }
  }

  Future<void> deleteAgent(String agentId) async {
    final url = _url('/v1/admin/agents/$agentId');
    final r = await http.delete(Uri.parse(url), headers: _headers);
    if (r.statusCode != 204) {
      throw Exception(_extractError(r));
    }
  }

  String _extractError(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) {
        if (body.containsKey('detail')) return body['detail'] as String;
        final err = body['error'];
        if (err is Map<String, dynamic>) {
          return err['message'] as String? ?? 'Request failed';
        }
      }
    } catch (_) {}
    return 'Request failed (${r.statusCode})';
  }
}
