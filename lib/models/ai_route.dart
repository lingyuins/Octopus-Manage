import 'package:octopusmanage/utils/parse_utils.dart';

enum AIRouteScope { table, group }

extension AIRouteScopeValue on AIRouteScope {
  String get value => this == AIRouteScope.group ? 'group' : 'table';
}

AIRouteScope parseAIRouteScope(String? value) {
  return value == 'group' ? AIRouteScope.group : AIRouteScope.table;
}

class AIRouteResult {
  final AIRouteScope scope;
  final int groupId;
  final int groupCount;
  final int routeCount;
  final int itemCount;

  const AIRouteResult({
    this.scope = AIRouteScope.table,
    this.groupId = 0,
    this.groupCount = 0,
    this.routeCount = 0,
    this.itemCount = 0,
  });

  factory AIRouteResult.fromJson(Map<String, dynamic> json) {
    return AIRouteResult(
      scope: parseAIRouteScope(json['scope'] as String?),
      groupId: parseInt(json['group_id']),
      groupCount: parseInt(json['group_count']),
      routeCount: parseInt(json['route_count']),
      itemCount: parseInt(json['item_count']),
    );
  }
}

class AIRouteProgressSummary {
  final int totalChannels;
  final int completedChannels;
  final int runningChannels;
  final int pendingChannels;
  final int failedChannels;
  final int totalModels;
  final int completedModels;

  const AIRouteProgressSummary({
    this.totalChannels = 0,
    this.completedChannels = 0,
    this.runningChannels = 0,
    this.pendingChannels = 0,
    this.failedChannels = 0,
    this.totalModels = 0,
    this.completedModels = 0,
  });

  factory AIRouteProgressSummary.fromJson(Map<String, dynamic> json) {
    return AIRouteProgressSummary(
      totalChannels: parseInt(json['total_channels']),
      completedChannels: parseInt(json['completed_channels']),
      runningChannels: parseInt(json['running_channels']),
      pendingChannels: parseInt(json['pending_channels']),
      failedChannels: parseInt(json['failed_channels']),
      totalModels: parseInt(json['total_models']),
      completedModels: parseInt(json['completed_models']),
    );
  }
}

class AIRouteBatchProgress {
  final int index;
  final int total;
  final String endpointType;
  final int modelCount;
  final List<int> channelIds;
  final List<String> channelNames;
  final String serviceName;
  final int attempt;
  final String status;
  final String message;

  const AIRouteBatchProgress({
    this.index = 0,
    this.total = 0,
    this.endpointType = '',
    this.modelCount = 0,
    this.channelIds = const [],
    this.channelNames = const [],
    this.serviceName = '',
    this.attempt = 0,
    this.status = '',
    this.message = '',
  });

  factory AIRouteBatchProgress.fromJson(Map<String, dynamic> json) {
    return AIRouteBatchProgress(
      index: parseInt(json['index']),
      total: parseInt(json['total']),
      endpointType: json['endpoint_type'] as String? ?? '',
      modelCount: parseInt(json['model_count']),
      channelIds:
          (json['channel_ids'] as List?)
              ?.map((item) => parseInt(item))
              .toList() ??
          const [],
      channelNames:
          (json['channel_names'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      serviceName: json['service_name'] as String? ?? '',
      attempt: parseInt(json['attempt']),
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class AIRouteChannelProgress {
  final int channelId;
  final String channelName;
  final String provider;
  final String status;
  final int totalModels;
  final int processedModels;
  final String message;

  const AIRouteChannelProgress({
    this.channelId = 0,
    this.channelName = '',
    this.provider = '',
    this.status = 'pending',
    this.totalModels = 0,
    this.processedModels = 0,
    this.message = '',
  });

  factory AIRouteChannelProgress.fromJson(Map<String, dynamic> json) {
    return AIRouteChannelProgress(
      channelId: parseInt(json['channel_id']),
      channelName: json['channel_name'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      totalModels: parseInt(json['total_models']),
      processedModels: parseInt(json['processed_models']),
      message: json['message'] as String? ?? '',
    );
  }
}

class AIRouteProgress {
  final String id;
  final AIRouteScope scope;
  final int groupId;
  final String status;
  final String currentStep;
  final int progressPercent;
  final int totalBatches;
  final int completedBatches;
  final bool done;
  final bool resultReady;
  final String message;
  final String errorReason;
  final String startedAt;
  final String updatedAt;
  final String heartbeatAt;
  final String finishedAt;
  final int eventSequence;
  final AIRouteProgressSummary? summary;
  final AIRouteBatchProgress? currentBatch;
  final List<AIRouteBatchProgress> runningBatches;
  final List<AIRouteChannelProgress> channels;
  final AIRouteResult? result;

  const AIRouteProgress({
    this.id = '',
    this.scope = AIRouteScope.table,
    this.groupId = 0,
    this.status = 'queued',
    this.currentStep = 'queued',
    this.progressPercent = 0,
    this.totalBatches = 0,
    this.completedBatches = 0,
    this.done = false,
    this.resultReady = false,
    this.message = '',
    this.errorReason = '',
    this.startedAt = '',
    this.updatedAt = '',
    this.heartbeatAt = '',
    this.finishedAt = '',
    this.eventSequence = 0,
    this.summary,
    this.currentBatch,
    this.runningBatches = const [],
    this.channels = const [],
    this.result,
  });

  bool get isTerminal =>
      status == 'completed' || status == 'failed' || status == 'timeout';

  bool get isCompletedWithResult =>
      done && status == 'completed' && resultReady;

  factory AIRouteProgress.fromJson(Map<String, dynamic> json) {
    final channelList =
        (json['channels'] as List?)
            ?.map(
              (item) =>
                  AIRouteChannelProgress.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        const <AIRouteChannelProgress>[];

    return AIRouteProgress(
      id: json['id'] as String? ?? '',
      scope: parseAIRouteScope(json['scope'] as String?),
      groupId: parseInt(json['group_id']),
      status:
          json['status'] as String? ??
          (json['done'] == true ? 'completed' : 'queued'),
      currentStep:
          json['current_step'] as String? ??
          (json['done'] == true ? 'completed' : 'queued'),
      progressPercent: parseInt(json['progress_percent']),
      totalBatches: parseInt(json['total_batches']),
      completedBatches: parseInt(json['completed_batches']),
      done: json['done'] as bool? ?? false,
      resultReady: json['result_ready'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      errorReason: json['error_reason'] as String? ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      heartbeatAt: json['heartbeat_at']?.toString() ?? '',
      finishedAt: json['finished_at']?.toString() ?? '',
      eventSequence: parseInt(json['event_sequence']),
      summary: json['summary'] is Map<String, dynamic>
          ? AIRouteProgressSummary.fromJson(
              json['summary'] as Map<String, dynamic>,
            )
          : null,
      currentBatch: json['current_batch'] is Map<String, dynamic>
          ? AIRouteBatchProgress.fromJson(
              json['current_batch'] as Map<String, dynamic>,
            )
          : null,
      runningBatches:
          (json['running_batches'] as List?)
              ?.map(
                (item) =>
                    AIRouteBatchProgress.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const <AIRouteBatchProgress>[],
      channels: channelList,
      result: json['result'] is Map<String, dynamic>
          ? AIRouteResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }
}
