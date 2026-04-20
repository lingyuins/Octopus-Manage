import 'package:octopusmanage/utils/parse_utils.dart';

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
    final price = json['LLMPrice'] as Map<String, dynamic>?;
    return LLMInfo(
      name: json['name'] as String? ?? '',
      input:
          (json['input'] as num?)?.toDouble() ??
          (price?['input'] as num?)?.toDouble() ??
          0,
      output:
          (json['output'] as num?)?.toDouble() ??
          (price?['output'] as num?)?.toDouble() ??
          0,
      cacheRead:
          (json['cache_read'] as num?)?.toDouble() ??
          (price?['cache_read'] as num?)?.toDouble() ??
          0,
      cacheWrite:
          (json['cache_write'] as num?)?.toDouble() ??
          (price?['cache_write'] as num?)?.toDouble() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'input': input,
    'output': output,
    'cache_read': cacheRead,
    'cache_write': cacheWrite,
  };
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
      channelId: parseInt(json['channel_id']),
      channelName: json['channel_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'enabled': enabled,
    'channel_id': channelId,
    'channel_name': channelName,
  };
}
