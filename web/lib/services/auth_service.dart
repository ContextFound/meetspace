import 'package:shared_preferences/shared_preferences.dart';

import '../api/client.dart';
import '../api/config.dart';

const String _keyStorageKey = 'meetspace_api_key';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final MeetSpaceApiClient _client = MeetSpaceApiClient();

  Future<String?> getStoredApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStorageKey);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStorageKey, key);
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStorageKey);
  }

  Future<bool> validateKey(String key) async {
    return _client.validateKey(key);
  }

  MeetSpaceApiClient clientWithKey(String? key) {
    return MeetSpaceApiClient(apiKey: key, baseUrl: apiBaseUrl);
  }
}
