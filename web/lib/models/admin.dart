class AdminAgent {
  final String id;
  final String email;
  final String agentName;
  final String tier;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int eventCount;

  AdminAgent({
    required this.id,
    required this.email,
    required this.agentName,
    required this.tier,
    required this.isActive,
    required this.createdAt,
    this.lastUsedAt,
    required this.eventCount,
  });

  factory AdminAgent.fromJson(Map<String, dynamic> json) {
    return AdminAgent(
      id: json['id'] as String,
      email: json['email'] as String,
      agentName: json['agent_name'] as String,
      tier: json['tier'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      eventCount: json['event_count'] as int,
    );
  }
}

class AdminAgentListResponse {
  final List<AdminAgent> agents;
  final int total;

  AdminAgentListResponse({required this.agents, required this.total});

  factory AdminAgentListResponse.fromJson(Map<String, dynamic> json) {
    return AdminAgentListResponse(
      agents: (json['agents'] as List)
          .map((e) => AdminAgent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}
