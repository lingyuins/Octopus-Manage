class APIKey {
  final int id;
  final String name;
  final String apiKey;
  final bool enabled;
  final int expireAt;
  final double maxCost;
  final String supportedModels;

  APIKey({
    this.id = 0,
    required this.name,
    this.apiKey = '',
    this.enabled = true,
    this.expireAt = 0,
    this.maxCost = 0,
    this.supportedModels = '',
  });

  factory APIKey.fromJson(Map<String, dynamic> json) {
    return APIKey(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      apiKey: json['api_key'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      expireAt: json['expire_at'] as int? ?? 0,
      maxCost: (json['max_cost'] as num?)?.toDouble() ?? 0,
      supportedModels: json['supported_models'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      if (apiKey.isNotEmpty) 'api_key': apiKey,
      'enabled': enabled,
      if (expireAt > 0) 'expire_at': expireAt,
      if (maxCost > 0) 'max_cost': maxCost,
      if (supportedModels.isNotEmpty) 'supported_models': supportedModels,
    };
  }
}
