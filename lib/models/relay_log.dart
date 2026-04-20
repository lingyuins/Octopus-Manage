import 'package:octopusmanage/utils/parse_utils.dart';

class RelayLog {
  final int id;
  final int time;
  final String requestModelName;
  final String requestApiKeyName;
  final int channelId;
  final String channelName;
  final String actualModelName;
  final int inputTokens;
  final int outputTokens;
  final int ftut;
  final int useTime;
  final double cost;
  final String error;

  RelayLog({
    required this.id,
    this.time = 0,
    this.requestModelName = '',
    this.requestApiKeyName = '',
    this.channelId = 0,
    this.channelName = '',
    this.actualModelName = '',
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.ftut = 0,
    this.useTime = 0,
    this.cost = 0,
    this.error = '',
  });

  factory RelayLog.fromJson(Map<String, dynamic> json) {
    return RelayLog(
      id: parseInt(json['id']),
      time: parseInt(json['time']),
      requestModelName: json['request_model_name'] as String? ?? '',
      requestApiKeyName: json['request_api_key_name'] as String? ?? '',
      channelId: parseInt(json['channel_id'] ?? json['channel']),
      channelName: json['channel_name'] as String? ?? '',
      actualModelName: json['actual_model_name'] as String? ?? '',
      inputTokens: parseInt(json['input_tokens']),
      outputTokens: parseInt(json['output_tokens']),
      ftut: parseInt(json['ftut']),
      useTime: parseInt(json['use_time']),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      error: json['error'] as String? ?? '',
    );
  }

  bool get hasError => error.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'request_model_name': requestModelName,
    'request_api_key_name': requestApiKeyName,
    'channel_id': channelId,
    'channel_name': channelName,
    'actual_model_name': actualModelName,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'ftut': ftut,
    'use_time': useTime,
    'cost': cost,
    'error': error,
  };
}
