class StatsMetrics {
  final int inputToken;
  final int outputToken;
  final double inputCost;
  final double outputCost;
  final int waitTime;
  final int requestSuccess;
  final int requestFailed;

  StatsMetrics({
    this.inputToken = 0,
    this.outputToken = 0,
    this.inputCost = 0,
    this.outputCost = 0,
    this.waitTime = 0,
    this.requestSuccess = 0,
    this.requestFailed = 0,
  });

  double get totalCost => inputCost + outputCost;
  int get totalTokens => inputToken + outputToken;
  int get totalRequests => requestSuccess + requestFailed;
  double get successRate =>
      totalRequests > 0 ? requestSuccess / totalRequests : 0;

  factory StatsMetrics.fromJson(Map<String, dynamic> json) {
    return StatsMetrics(
      inputToken: json['input_token'] as int? ?? 0,
      outputToken: json['output_token'] as int? ?? 0,
      inputCost: (json['input_cost'] as num?)?.toDouble() ?? 0,
      outputCost: (json['output_cost'] as num?)?.toDouble() ?? 0,
      waitTime: json['wait_time'] as int? ?? 0,
      requestSuccess: json['request_success'] as int? ?? 0,
      requestFailed: json['request_failed'] as int? ?? 0,
    );
  }
}

class StatsDaily {
  final String date;
  final StatsMetrics metrics;

  StatsDaily({required this.date, required this.metrics});

  factory StatsDaily.fromJson(Map<String, dynamic> json) {
    return StatsDaily(
      date: json['date'] as String? ?? '',
      metrics: StatsMetrics.fromJson(json),
    );
  }
}

class StatsHourly {
  final int hour;
  final String date;
  final StatsMetrics metrics;

  StatsHourly({required this.hour, required this.date, required this.metrics});

  factory StatsHourly.fromJson(Map<String, dynamic> json) {
    return StatsHourly(
      hour: json['hour'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      metrics: StatsMetrics.fromJson(json),
    );
  }
}

class StatsAPIKeyEntry {
  final int apiKeyId;
  final StatsMetrics metrics;

  StatsAPIKeyEntry({required this.apiKeyId, required this.metrics});

  factory StatsAPIKeyEntry.fromJson(Map<String, dynamic> json) {
    return StatsAPIKeyEntry(
      apiKeyId: json['api_key_id'] as int? ?? 0,
      metrics: StatsMetrics.fromJson(json),
    );
  }
}
