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
      id: json['id'] as int? ?? 0,
      time: json['time'] as int? ?? 0,
      requestModelName: json['request_model_name'] as String? ?? '',
      requestApiKeyName: json['request_api_key_name'] as String? ?? '',
      channelId: json['channel'] as int? ?? 0,
      channelName: json['channel_name'] as String? ?? '',
      actualModelName: json['actual_model_name'] as String? ?? '',
      inputTokens: json['input_tokens'] as int? ?? 0,
      outputTokens: json['output_tokens'] as int? ?? 0,
      ftut: json['ftut'] as int? ?? 0,
      useTime: json['use_time'] as int? ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      error: json['error'] as String? ?? '',
    );
  }

  bool get hasError => error.isNotEmpty;
}
