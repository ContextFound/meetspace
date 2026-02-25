class RegisterRequest {
  final String email;
  final String agentName;

  RegisterRequest({required this.email, required this.agentName});

  Map<String, dynamic> toJson() => {
        'email': email,
        'agent_name': agentName,
      };
}

class RegisterResponse {
  final String apiKey;
  final String keyPrefix;
  final String tier;
  final int rateLimit;
  final DateTime createdAt;

  RegisterResponse({
    required this.apiKey,
    required this.keyPrefix,
    required this.tier,
    required this.rateLimit,
    required this.createdAt,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      apiKey: json['api_key'] as String,
      keyPrefix: json['key_prefix'] as String,
      tier: json['tier'] as String,
      rateLimit: json['rate_limit'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
