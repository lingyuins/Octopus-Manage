class LLMInfo {
  final String name;
  final double input;
  final double output;
  final double cacheRead;
  final double cacheWrite;

  LLMInfo({
    required this.name,
    this.input = 0,
    this.output = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
  });

  factory LLMInfo.fromJson(Map<String, dynamic> json) {
    final price = json['LLMPrice'] as Map<String, dynamic>? ?? json;
    return LLMInfo(
      name: json['name'] as String? ?? '',
      input: (price['input'] as num?)?.toDouble() ?? 0,
      output: (price['output'] as num?)?.toDouble() ?? 0,
      cacheRead: (price['cache_read'] as num?)?.toDouble() ?? 0,
      cacheWrite: (price['cache_write'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LLMChannel {
  final String name;
  final bool enabled;
  final int channelId;
  final String channelName;

  LLMChannel({
    required this.name,
    this.enabled = true,
    this.channelId = 0,
    this.channelName = '',
  });

  factory LLMChannel.fromJson(Map<String, dynamic> json) {
    return LLMChannel(
      name: json['name'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      channelId: json['channel_id'] as int? ?? 0,
      channelName: json['channel_name'] as String? ?? '',
    );
  }
}
