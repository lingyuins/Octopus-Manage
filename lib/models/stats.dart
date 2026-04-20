import 'package:octopusmanage/utils/parse_utils.dart';

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
      inputToken: parseInt(json['input_token']),
      outputToken: parseInt(json['output_token']),
      inputCost: (json['input_cost'] as num?)?.toDouble() ?? 0,
      outputCost: (json['output_cost'] as num?)?.toDouble() ?? 0,
      waitTime: parseInt(json['wait_time']),
      requestSuccess: parseInt(json['request_success']),
      requestFailed: parseInt(json['request_failed']),
    );
  }

  Map<String, dynamic> toJson() => {
    'input_token': inputToken,
    'output_token': outputToken,
    'input_cost': inputCost,
    'output_cost': outputCost,
    'wait_time': waitTime,
    'request_success': requestSuccess,
    'request_failed': requestFailed,
  };
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

  Map<String, dynamic> toJson() => {
    'date': date,
    ...metrics.toJson(),
  };
}

class StatsHourly {
  final int hour;
  final String date;
  final StatsMetrics metrics;

  StatsHourly({required this.hour, required this.date, required this.metrics});

  factory StatsHourly.fromJson(Map<String, dynamic> json) {
    return StatsHourly(
      hour: parseInt(json['hour']),
      date: json['date'] as String? ?? '',
      metrics: StatsMetrics.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'date': date,
    ...metrics.toJson(),
  };
}

class StatsAPIKeyEntry {
  final int apiKeyId;
  final StatsMetrics metrics;

  StatsAPIKeyEntry({required this.apiKeyId, required this.metrics});

  factory StatsAPIKeyEntry.fromJson(Map<String, dynamic> json) {
    return StatsAPIKeyEntry(
      apiKeyId: parseInt(json['api_key_id']),
      metrics: StatsMetrics.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'api_key_id': apiKeyId,
    ...metrics.toJson(),
  };
}
