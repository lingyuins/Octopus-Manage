import 'package:octopusmanage/utils/parse_utils.dart';

class Channel {
  final int id;
  final String name;
  final int type;
  final bool enabled;
  final List<BaseUrl> baseUrls;
  final List<ChannelKey> keys;
  final String model;
  final String customModel;
  final bool proxy;
  final bool autoSync;
  final int autoGroup;
  final List<CustomHeader> customHeader;
  final String? paramOverride;
  final String? channelProxy;
  final StatsChannel? stats;
  final String? matchRegex;

  Channel({
    required this.id,
    required this.name,
    required this.type,
    required this.enabled,
    this.baseUrls = const [],
    this.keys = const [],
    this.model = '',
    this.customModel = '',
    this.proxy = false,
    this.autoSync = false,
    this.autoGroup = 0,
    this.customHeader = const [],
    this.paramOverride,
    this.channelProxy,
    this.stats,
    this.matchRegex,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      type: json['type'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      baseUrls:
          (json['base_urls'] as List?)
              ?.map((e) => BaseUrl.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keys:
          (json['keys'] as List?)
              ?.map((e) => ChannelKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      model: json['model'] as String? ?? '',
      customModel: json['custom_model'] as String? ?? '',
      proxy: json['proxy'] as bool? ?? false,
      autoSync: json['auto_sync'] as bool? ?? false,
      autoGroup: json['auto_group'] as int? ?? 0,
      customHeader:
          (json['custom_header'] as List?)
              ?.map((e) => CustomHeader.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paramOverride: json['param_override'] as String?,
      channelProxy: json['channel_proxy'] as String?,
      stats: json['stats'] != null
          ? StatsChannel.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      matchRegex: json['match_regex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'type': type,
      'enabled': enabled,
      'base_urls': baseUrls.map((e) => e.toJson()).toList(),
      'keys': keys.map((e) => e.toJson()).toList(),
      'model': model,
      'custom_model': customModel,
      'proxy': proxy,
      'auto_sync': autoSync,
      'auto_group': autoGroup,
      'custom_header': customHeader.map((e) => e.toJson()).toList(),
      if (paramOverride != null) 'param_override': paramOverride,
      if (channelProxy != null) 'channel_proxy': channelProxy,
      if (matchRegex != null) 'match_regex': matchRegex,
    };
  }
}

class BaseUrl {
  final String url;
  final int delay;

  BaseUrl({required this.url, this.delay = 0});

  factory BaseUrl.fromJson(Map<String, dynamic> json) {
    return BaseUrl(
      url: json['url'] as String? ?? '',
      delay: json['delay'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'delay': delay};
}

class CustomHeader {
  final String headerKey;
  final String headerValue;

  CustomHeader({required this.headerKey, required this.headerValue});

  factory CustomHeader.fromJson(Map<String, dynamic> json) {
    return CustomHeader(
      headerKey: json['header_key'] as String? ?? '',
      headerValue: json['header_value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'header_key': headerKey,
    'header_value': headerValue,
  };
}

class ChannelKey {
  final int id;
  final int channelId;
  final bool enabled;
  final String channelKey;
  final int statusCode;
  final int lastUseTimeStamp;
  final double totalCost;
  final String remark;

  ChannelKey({
    required this.id,
    this.channelId = 0,
    this.enabled = true,
    this.channelKey = '',
    this.statusCode = 0,
    this.lastUseTimeStamp = 0,
    this.totalCost = 0,
    this.remark = '',
  });

  factory ChannelKey.fromJson(Map<String, dynamic> json) {
    return ChannelKey(
      id: parseInt(json['id']),
      channelId: parseInt(json['channel_id']),
      enabled: json['enabled'] as bool? ?? true,
      channelKey: json['channel_key'] as String? ?? '',
      statusCode: json['status_code'] as int? ?? 0,
      lastUseTimeStamp: json['last_use_time_stamp'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      remark: json['remark'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'channel_id': channelId,
    'enabled': enabled,
    'channel_key': channelKey,
    'status_code': statusCode,
    'remark': remark,
  };
}

class StatsChannel {
  final int channelId;
  final int inputToken;
  final int outputToken;
  final double inputCost;
  final double outputCost;
  final int waitTime;
  final int requestSuccess;
  final int requestFailed;

  StatsChannel({
    this.channelId = 0,
    this.inputToken = 0,
    this.outputToken = 0,
    this.inputCost = 0,
    this.outputCost = 0,
    this.waitTime = 0,
    this.requestSuccess = 0,
    this.requestFailed = 0,
  });

  factory StatsChannel.fromJson(Map<String, dynamic> json) {
    return StatsChannel(
      channelId: parseInt(json['channel_id']),
      inputToken: json['input_token'] as int? ?? 0,
      outputToken: json['output_token'] as int? ?? 0,
      inputCost: (json['input_cost'] as num?)?.toDouble() ?? 0,
      outputCost: (json['output_cost'] as num?)?.toDouble() ?? 0,
      waitTime: json['wait_time'] as int? ?? 0,
      requestSuccess: json['request_success'] as int? ?? 0,
      requestFailed: json['request_failed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'channel_id': channelId,
    'input_token': inputToken,
    'output_token': outputToken,
    'input_cost': inputCost,
    'output_cost': outputCost,
    'wait_time': waitTime,
    'request_success': requestSuccess,
    'request_failed': requestFailed,
  };
}
