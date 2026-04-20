import 'package:octopusmanage/utils/parse_utils.dart';

// ====== Channel Test ======

class ChannelTestResult {
  final String baseUrl;
  final String keyRemark;
  final String keyMasked;
  final int statusCode;
  final bool passed;
  final int latencyMs;
  final String message;
  final String responseBody;

  ChannelTestResult({
    required this.baseUrl,
    this.keyRemark = '',
    this.keyMasked = '',
    this.statusCode = 0,
    this.passed = false,
    this.latencyMs = 0,
    this.message = '',
    this.responseBody = '',
  });

  factory ChannelTestResult.fromJson(Map<String, dynamic> json) {
    return ChannelTestResult(
      baseUrl: json['base_url'] as String? ?? '',
      keyRemark: json['key_remark'] as String? ?? '',
      keyMasked: json['key_masked'] as String? ?? '',
      statusCode: parseInt(json['status_code']),
      passed: json['passed'] as bool? ?? false,
      latencyMs: parseInt(json['latency_ms']),
      message: json['message'] as String? ?? '',
      responseBody: json['response_body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'base_url': baseUrl,
        'key_remark': keyRemark,
        'key_masked': keyMasked,
        'status_code': statusCode,
        'passed': passed,
        'latency_ms': latencyMs,
        'message': message,
        'response_body': responseBody,
      };
}

class ChannelTestSummary {
  final bool passed;
  final List<ChannelTestResult> results;

  ChannelTestSummary({
    this.passed = false,
    this.results = const [],
  });

  factory ChannelTestSummary.fromJson(Map<String, dynamic> json) {
    return ChannelTestSummary(
      passed: json['passed'] as bool? ?? false,
      results: (json['results'] as List?)
              ?.map((e) => ChannelTestResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
