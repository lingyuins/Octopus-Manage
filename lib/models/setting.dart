class Setting {
  final String key;
  final String value;

  Setting({required this.key, required this.value});

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}

const settingLabels = {
  'proxy_url': 'Proxy URL',
  'stats_save_interval': 'Stats Save Interval (min)',
  'model_info_update_interval': 'Model Info Update Interval (hr)',
  'sync_llm_interval': 'LLM Sync Interval (hr)',
  'relay_log_keep_period': 'Log Keep Period (days)',
  'relay_log_keep_enabled': 'Keep Logs Enabled',
  'cors_allow_origins': 'CORS Allow Origins',
  'relay_retry_count': 'Relay Retry Count',
  'circuit_breaker_threshold': 'Circuit Breaker Threshold',
  'circuit_breaker_cooldown': 'Circuit Breaker Cooldown (sec)',
  'circuit_breaker_max_cooldown': 'Circuit Breaker Max Cooldown (sec)',
  'public_api_base_url': 'Public API Base URL',
};
