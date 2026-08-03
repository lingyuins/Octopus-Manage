import 'package:octopusmanage/utils/parse_utils.dart';

/// Proxy usage mode for a channel.
enum ProxyUsageMode {
  direct,
  system,
  pool,
  inherit;

  static ProxyUsageMode fromString(String value) {
    return ProxyUsageMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProxyUsageMode.direct,
    );
  }
}

/// Request rewrite profile type
enum RequestRewriteProfile {
  preserve,
  openaiChatCompat,
  codex;

  static RequestRewriteProfile fromString(String value) {
    return RequestRewriteProfile.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RequestRewriteProfile.preserve,
    );
  }
}

/// Tool role rewrite strategy
enum ToolRoleStrategy {
  keep,
  stringifyToUser;

  static ToolRoleStrategy fromString(String value) {
    return ToolRoleStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ToolRoleStrategy.keep,
    );
  }
}

/// System message rewrite strategy
enum SystemMessageStrategy {
  keep,
  merge;

  static SystemMessageStrategy fromString(String value) {
    return SystemMessageStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SystemMessageStrategy.keep,
    );
  }
}

/// Request rewrite configuration for a channel.
class RequestRewriteConfig {
  final bool enabled;
  final RequestRewriteProfile profile;
  final ToolRoleStrategy toolRoleStrategy;
  final SystemMessageStrategy systemMessageStrategy;
  final String? headerProfile;
  final String? promptPrefix;
  final String? promptSuffix;
  final String? systemMessage;

  const RequestRewriteConfig({
    this.enabled = false,
    this.profile = RequestRewriteProfile.preserve,
    this.toolRoleStrategy = ToolRoleStrategy.keep,
    this.systemMessageStrategy = SystemMessageStrategy.keep,
    this.headerProfile,
    this.promptPrefix,
    this.promptSuffix,
    this.systemMessage,
  });

  factory RequestRewriteConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RequestRewriteConfig();
    return RequestRewriteConfig(
      enabled: parseBool(json['enabled']),
      profile: RequestRewriteProfile.fromString(
        parseString(json['profile'], fallback: 'preserve'),
      ),
      toolRoleStrategy: ToolRoleStrategy.fromString(
        parseString(json['tool_role_strategy'], fallback: 'keep'),
      ),
      systemMessageStrategy: SystemMessageStrategy.fromString(
        parseString(json['system_message_strategy'], fallback: 'keep'),
      ),
      headerProfile: json['header_profile'] == null
          ? null
          : parseString(json['header_profile']),
      promptPrefix: json['prompt_prefix'] == null
          ? null
          : parseString(json['prompt_prefix']),
      promptSuffix: json['prompt_suffix'] == null
          ? null
          : parseString(json['prompt_suffix']),
      systemMessage: json['system_message'] == null
          ? null
          : parseString(json['system_message']),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'profile': profile.name,
        'tool_role_strategy': toolRoleStrategy.name.toLowerCase(),
        'system_message_strategy': systemMessageStrategy.name.toLowerCase(),
        if (headerProfile != null) 'header_profile': headerProfile,
        if (promptPrefix != null) 'prompt_prefix': promptPrefix,
        if (promptSuffix != null) 'prompt_suffix': promptSuffix,
        if (systemMessage != null) 'system_message': systemMessage,
      };
}

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
  final bool skipModelTest;
  final bool disposable;
  final String? expireAt;
  final int? notifChannelId;
  final String keySelectionStrategy;
  final List<CustomHeader> customHeader;
  final List<CustomHeaderOp> customHeaderOps;
  final String? paramOverride;
  final String? channelProxy;
  final RequestRewriteConfig? requestRewrite;
  final StatsChannel? stats;
  final String? matchRegex;
  final bool? keyHealthPassed;
  final bool? keyHealthAllFailed;
  final int keyHealthAt;
  final bool managed;
  final ManagedChannelSource? managedSource;

  // Phase 2.4: New fields
  final int? groupId;
  final ProxyUsageMode proxyMode;
  final int? proxyConfigId;

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
    this.skipModelTest = false,
    this.disposable = false,
    this.expireAt,
    this.notifChannelId,
    this.keySelectionStrategy = '',
    this.customHeader = const [],
    this.customHeaderOps = const [],
    this.paramOverride,
    this.channelProxy,
    this.requestRewrite,
    this.stats,
    this.matchRegex,
    this.keyHealthPassed,
    this.keyHealthAllFailed,
    this.keyHealthAt = 0,
    this.managed = false,
    this.managedSource,
    this.groupId,
    this.proxyMode = ProxyUsageMode.direct,
    this.proxyConfigId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      type: parseInt(json['type']),
      enabled: parseBool(json['enabled'], fallback: true),
      baseUrls: parseJsonMapList(
        json['base_urls'],
      ).map(BaseUrl.fromJson).toList(),
      keys: parseJsonMapList(json['keys']).map(ChannelKey.fromJson).toList(),
      model: parseString(json['model']),
      customModel: parseString(json['custom_model']),
      proxy: parseBool(json['proxy']),
      autoSync: parseBool(json['auto_sync']),
      autoGroup: parseInt(json['auto_group']),
      skipModelTest: parseBool(json['skip_model_test']),
      disposable: parseBool(json['disposable']),
      expireAt: json['expire_at'] == null
          ? null
          : parseString(json['expire_at']),
      notifChannelId: json['notif_channel_id'] == null
          ? null
          : parseInt(json['notif_channel_id']),
      keySelectionStrategy: parseString(json['key_selection_strategy']),
      customHeader: parseJsonMapList(
        json['custom_header'],
      ).map(CustomHeader.fromJson).toList(),
      customHeaderOps: parseJsonMapList(
        json['custom_header_ops'],
      ).map(CustomHeaderOp.fromJson).toList(),
      paramOverride: json['param_override'] == null
          ? null
          : parseString(json['param_override']),
      channelProxy: json['channel_proxy'] == null
          ? null
          : parseString(json['channel_proxy']),
      requestRewrite: RequestRewriteConfig.fromJson(
        parseJsonMap(json['request_rewrite']),
      ),
      stats: parseJsonMap(json['stats']) != null
          ? StatsChannel.fromJson(parseJsonMap(json['stats'])!)
          : null,
      matchRegex: json['match_regex'] == null
          ? null
          : parseString(json['match_regex']),
      keyHealthPassed: json['key_health_passed'],
      keyHealthAllFailed: json['key_health_all_failed'],
      keyHealthAt: parseInt(json['key_health_at']),
      managed: parseBool(json['managed']),
      managedSource: parseJsonMap(json['managed_source']) != null
          ? ManagedChannelSource.fromJson(parseJsonMap(json['managed_source'])!)
          : null,
      // Phase 2.4 new fields
      groupId: json['group_id'] == null ? null : parseInt(json['group_id']),
      proxyMode: ProxyUsageMode.fromString(
        parseString(json['proxy_mode'], fallback: 'direct'),
      ),
      proxyConfigId: json['proxy_config_id'] == null
          ? null
          : parseInt(json['proxy_config_id']),
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
      'skip_model_test': skipModelTest,
      'disposable': disposable,
      if (expireAt != null) 'expire_at': expireAt,
      if (notifChannelId != null) 'notif_channel_id': notifChannelId,
      'key_selection_strategy': keySelectionStrategy,
      'custom_header': customHeader.map((e) => e.toJson()).toList(),
      'custom_header_ops': customHeaderOps.map((e) => e.toJson()).toList(),
      if (paramOverride != null) 'param_override': paramOverride,
      if (channelProxy != null) 'channel_proxy': channelProxy,
      if (requestRewrite != null) 'request_rewrite': requestRewrite!.toJson(),
      if (matchRegex != null) 'match_regex': matchRegex,
      if (keyHealthPassed != null) 'key_health_passed': keyHealthPassed,
      if (keyHealthAllFailed != null) 'key_health_all_failed': keyHealthAllFailed,
      'key_health_at': keyHealthAt,
      'managed': managed,
      if (managedSource != null) 'managed_source': managedSource!.toJson(),
      // Phase 2.4 new fields
      if (groupId != null) 'group_id': groupId,
      'proxy_mode': proxyMode.name,
      if (proxyConfigId != null) 'proxy_config_id': proxyConfigId,
    };
  }
}

/// Managed channel source info
class ManagedChannelSource {
  final String sourceType;
  final String sourceId;
  final String? importTimestamp;

  const ManagedChannelSource({
    required this.sourceType,
    required this.sourceId,
    this.importTimestamp,
  });

  factory ManagedChannelSource.fromJson(Map<String, dynamic> json) {
    return ManagedChannelSource(
      sourceType: parseString(json['source_type']),
      sourceId: parseString(json['source_id']),
      importTimestamp: json['import_timestamp'] == null
          ? null
          : parseString(json['import_timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'source_type': sourceType,
        'source_id': sourceId,
        if (importTimestamp != null) 'import_timestamp': importTimestamp,
      };
}

class BaseUrl {
  final String url;
  final int delay;
  final String? suffixMode;

  BaseUrl({required this.url, this.delay = 0, this.suffixMode});

  factory BaseUrl.fromJson(Map<String, dynamic> json) {
    return BaseUrl(
      url: parseString(json['url']),
      delay: parseInt(json['delay']),
      suffixMode: json['suffix_mode'] == null
          ? null
          : parseString(json['suffix_mode']),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'delay': delay,
        if (suffixMode != null) 'suffix_mode': suffixMode,
      };
}

class CustomHeader {
  final String headerKey;
  final String headerValue;

  CustomHeader({required this.headerKey, required this.headerValue});

  factory CustomHeader.fromJson(Map<String, dynamic> json) {
    return CustomHeader(
      headerKey: parseString(json['header_key']),
      headerValue: parseString(json['header_value']),
    );
  }

  Map<String, dynamic> toJson() => {
    'header_key': headerKey,
    'header_value': headerValue,
  };
}

enum HeaderOpType {
  set,
  add,
  delete,
  rename,
  copy;

  static HeaderOpType fromString(String value) {
    return HeaderOpType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HeaderOpType.set,
    );
  }
}

/// A single header rewrite instruction (matches Octopus mod2 backend).
/// Sequence semantics: ops apply in array order on the outbound request
/// after copyHeaders. Effective behavior:
///   set    (name, value)  overwrite header to value
///   add    (name, value)  append a value (multi-valued)
///   delete (name)         remove header
///   rename (name, to)     rename header name (preserves value)
///   copy   (name, from)   copy value from `from` to `name`
class CustomHeaderOp {
  final HeaderOpType op;
  final String name;
  final String? value;
  final String? to;
  final String? from;

  const CustomHeaderOp({
    required this.op,
    required this.name,
    this.value,
    this.to,
    this.from,
  });

  factory CustomHeaderOp.fromJson(Map<String, dynamic> json) {
    return CustomHeaderOp(
      op: HeaderOpType.fromString(parseString(json['op'], fallback: 'set')),
      name: parseString(json['name']),
      value: json['value'] == null ? null : parseString(json['value']),
      to: json['to'] == null ? null : parseString(json['to']),
      from: json['from'] == null ? null : parseString(json['from']),
    );
  }

  Map<String, dynamic> toJson() => {
        'op': op.name,
        'name': name,
        if (value != null && value!.isNotEmpty) 'value': value,
        if (to != null && to!.isNotEmpty) 'to': to,
        if (from != null && from!.isNotEmpty) 'from': from,
      };

  CustomHeaderOp copyWith({
    HeaderOpType? op,
    String? name,
    String? value,
    String? to,
    String? from,
  }) {
    return CustomHeaderOp(
      op: op ?? this.op,
      name: name ?? this.name,
      value: value ?? this.value,
      to: to ?? this.to,
      from: from ?? this.from,
    );
  }

  /// Human-readable summary for UI display.
  String summary() {
    switch (op) {
      case HeaderOpType.set:
        return 'Set $name = ${value ?? ""}';
      case HeaderOpType.add:
        return 'Add $name: ${value ?? ""}';
      case HeaderOpType.delete:
        return 'Delete $name';
      case HeaderOpType.rename:
        return 'Rename $name -> ${to ?? ""}';
      case HeaderOpType.copy:
        return 'Copy ${from ?? ""} -> $name';
    }
  }
}

class ChannelKey {
  final int id;
  final int channelId;
  final bool enabled;
  final String channelKey;
  final int statusCode;
  final int lastUseTimeStamp;
  final double totalCost;
  final int priority;
  final String remark;

  ChannelKey({
    required this.id,
    this.channelId = 0,
    this.enabled = true,
    this.channelKey = '',
    this.statusCode = 0,
    this.lastUseTimeStamp = 0,
    this.totalCost = 0,
    this.priority = 0,
    this.remark = '',
  });

  factory ChannelKey.fromJson(Map<String, dynamic> json) {
    return ChannelKey(
      id: parseInt(json['id']),
      channelId: parseInt(json['channel_id']),
      enabled: parseBool(json['enabled'], fallback: true),
      channelKey: parseString(json['channel_key']),
      statusCode: parseInt(json['status_code']),
      lastUseTimeStamp: parseInt(json['last_use_time_stamp']),
      totalCost: parseDouble(json['total_cost']),
      priority: parseInt(json['priority']),
      remark: parseString(json['remark']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'channel_id': channelId,
    'enabled': enabled,
    'channel_key': channelKey,
    'status_code': statusCode,
    'last_use_time_stamp': lastUseTimeStamp,
    'total_cost': totalCost,
    'priority': priority,
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
      inputToken: parseInt(json['input_token']),
      outputToken: parseInt(json['output_token']),
      inputCost: parseDouble(json['input_cost']),
      outputCost: parseDouble(json['output_cost']),
      waitTime: parseInt(json['wait_time']),
      requestSuccess: parseInt(json['request_success']),
      requestFailed: parseInt(json['request_failed']),
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

/// Incremental update request for a channel.
/// Only includes fields that have changed from the previous state.
class ChannelUpdateRequest {
  final int id;
  final String? name;
  final int? type;
  final bool? enabled;
  final List<BaseUrl>? baseUrls;
  final List<ChannelKey>? keys;
  final String? model;
  final String? customModel;
  final bool? proxy;
  final bool? autoSync;
  final int? autoGroup;
  final List<CustomHeader>? customHeader;
  final List<CustomHeaderOp>? customHeaderOps;
  final String? paramOverride;
  final String? channelProxy;
  final String? matchRegex;
  final int? groupId;
  final ProxyUsageMode? proxyMode;
  final int? proxyConfigId;
  final bool? skipModelTest;
  final RequestRewriteConfig? requestRewrite;
  final bool? managed;
  final ManagedChannelSource? managedSource;

  const ChannelUpdateRequest({
    required this.id,
    this.name,
    this.type,
    this.enabled,
    this.baseUrls,
    this.keys,
    this.model,
    this.customModel,
    this.proxy,
    this.autoSync,
    this.autoGroup,
    this.customHeader,
    this.customHeaderOps,
    this.paramOverride,
    this.channelProxy,
    this.matchRegex,
    this.groupId,
    this.proxyMode,
    this.proxyConfigId,
    this.skipModelTest,
    this.requestRewrite,
    this.managed,
    this.managedSource,
  });

  /// Creates an update request by diffing [previous] and [next] Channel states.
  /// Only changed fields are included in the resulting request.
  factory ChannelUpdateRequest.fromDiff(Channel previous, Channel next) {
    return ChannelUpdateRequest(
      id: next.id,
      name: previous.name != next.name ? next.name : null,
      type: previous.type != next.type ? next.type : null,
      enabled: previous.enabled != next.enabled ? next.enabled : null,
      baseUrls: !_listEquals(previous.baseUrls, next.baseUrls, (b) => '${b.url}:${b.delay}:${b.suffixMode}')
          ? next.baseUrls
          : null,
      keys: !_listEquals(previous.keys, next.keys, (k) => '${k.id}:${k.channelKey}:${k.enabled}:${k.remark}')
          ? next.keys
          : null,
      model: previous.model != next.model ? next.model : null,
      customModel: previous.customModel != next.customModel ? next.customModel : null,
      proxy: previous.proxy != next.proxy ? next.proxy : null,
      autoSync: previous.autoSync != next.autoSync ? next.autoSync : null,
      autoGroup: previous.autoGroup != next.autoGroup ? next.autoGroup : null,
      customHeader: !_listEquals(previous.customHeader, next.customHeader, (h) => '${h.headerKey}:${h.headerValue}')
          ? next.customHeader
          : null,
      customHeaderOps: !_listEquals(previous.customHeaderOps, next.customHeaderOps, (h) => '${h.op.name}:${h.name}:${h.value}:${h.to}:${h.from}')
          ? next.customHeaderOps
          : null,
      paramOverride: previous.paramOverride != next.paramOverride ? next.paramOverride : null,
      channelProxy: previous.channelProxy != next.channelProxy ? next.channelProxy : null,
      matchRegex: previous.matchRegex != next.matchRegex ? next.matchRegex : null,
      groupId: previous.groupId != next.groupId ? next.groupId : null,
      proxyMode: previous.proxyMode != next.proxyMode ? next.proxyMode : null,
      proxyConfigId: previous.proxyConfigId != next.proxyConfigId ? next.proxyConfigId : null,
      skipModelTest: previous.skipModelTest != next.skipModelTest ? next.skipModelTest : null,
      requestRewrite: previous.requestRewrite?.toJson().toString() != next.requestRewrite?.toJson().toString()
          ? next.requestRewrite
          : null,
      managed: previous.managed != next.managed ? next.managed : null,
      managedSource: previous.managedSource != next.managedSource ? next.managedSource : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (enabled != null) 'enabled': enabled,
      if (baseUrls != null) 'base_urls': baseUrls!.map((e) => e.toJson()).toList(),
      if (keys != null) 'keys': keys!.map((e) => e.toJson()).toList(),
      if (model != null) 'model': model,
      if (customModel != null) 'custom_model': customModel,
      if (proxy != null) 'proxy': proxy,
      if (autoSync != null) 'auto_sync': autoSync,
      if (autoGroup != null) 'auto_group': autoGroup,
      if (customHeader != null) 'custom_header': customHeader!.map((e) => e.toJson()).toList(),
      if (customHeaderOps != null) 'custom_header_ops': customHeaderOps!.map((e) => e.toJson()).toList(),
      if (paramOverride != null) 'param_override': paramOverride,
      if (channelProxy != null) 'channel_proxy': channelProxy,
      if (matchRegex != null) 'match_regex': matchRegex,
      if (groupId != null) 'group_id': groupId,
      if (proxyMode != null) 'proxy_mode': proxyMode!.name,
      if (proxyConfigId != null) 'proxy_config_id': proxyConfigId,
      if (skipModelTest != null) 'skip_model_test': skipModelTest,
      if (requestRewrite != null) 'request_rewrite': requestRewrite!.toJson(),
      if (managed != null) 'managed': managed,
      if (managedSource != null) 'managed_source': managedSource!.toJson(),
    };
  }

  static bool _listEquals<T>(List<T> a, List<T> b, String Function(T) key) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (key(a[i]) != key(b[i])) return false;
    }
    return true;
  }
}
