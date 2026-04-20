import 'package:octopusmanage/utils/parse_utils.dart';

class Group {
  final int id;
  final String name;
  final String endpointType;
  final int mode;
  final String matchRegex;
  final int firstTokenTimeOut;
  final int sessionKeepTime;
  final String createdTime;
  final List<GroupItem> items;

  Group({
    required this.id,
    required this.name,
    this.endpointType = '*',
    this.mode = 1,
    this.matchRegex = '',
    this.firstTokenTimeOut = 0,
    this.sessionKeepTime = 0,
    this.createdTime = '',
    this.items = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      endpointType: normalizeGroupEndpointType(
        json['endpoint_type'] as String? ?? '*',
      ),
      mode: parseInt(json['mode']),
      matchRegex: json['match_regex'] as String? ?? '',
      firstTokenTimeOut: parseInt(json['first_token_time_out']),
      sessionKeepTime: parseInt(json['session_keep_time']),
      createdTime: json['created_time'] as String? ?? '',
      items:
          (json['items'] as List?)
              ?.map((e) => GroupItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'endpoint_type': normalizeGroupEndpointType(endpointType),
      'mode': mode,
      'match_regex': matchRegex,
      'first_token_time_out': firstTokenTimeOut,
      'session_keep_time': sessionKeepTime,
      if (createdTime.isNotEmpty) 'created_time': createdTime,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class GroupItem {
  final int id;
  final int groupId;
  final int channelId;
  final String modelName;
  final int priority;
  final int weight;

  GroupItem({
    this.id = 0,
    this.groupId = 0,
    required this.channelId,
    required this.modelName,
    this.priority = 0,
    this.weight = 0,
  });

  factory GroupItem.fromJson(Map<String, dynamic> json) {
    return GroupItem(
      id: parseInt(json['id']),
      groupId: parseInt(json['group_id']),
      channelId: parseInt(json['channel_id']),
      modelName: json['model_name'] as String? ?? '',
      priority: parseInt(json['priority']),
      weight: parseInt(json['weight']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    if (groupId > 0) 'group_id': groupId,
    'channel_id': channelId,
    'model_name': modelName,
    'priority': priority,
    'weight': weight,
  };
}

class GroupUpdateRequest {
  final int id;
  final String? name;
  final String? endpointType;
  final int? mode;
  final String? matchRegex;
  final int? firstTokenTimeOut;
  final int? sessionKeepTime;
  final List<GroupItemAddRequest> itemsToAdd;
  final List<GroupItemUpdateRequest> itemsToUpdate;
  final List<int> itemsToDelete;

  const GroupUpdateRequest({
    required this.id,
    this.name,
    this.endpointType,
    this.mode,
    this.matchRegex,
    this.firstTokenTimeOut,
    this.sessionKeepTime,
    this.itemsToAdd = const [],
    this.itemsToUpdate = const [],
    this.itemsToDelete = const [],
  });

  bool get hasChanges =>
      name != null ||
      endpointType != null ||
      mode != null ||
      matchRegex != null ||
      firstTokenTimeOut != null ||
      sessionKeepTime != null ||
      itemsToAdd.isNotEmpty ||
      itemsToUpdate.isNotEmpty ||
      itemsToDelete.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    if (name != null) 'name': name,
    if (endpointType != null)
      'endpoint_type': normalizeGroupEndpointType(endpointType!),
    if (mode != null) 'mode': mode,
    if (matchRegex != null) 'match_regex': matchRegex,
    if (firstTokenTimeOut != null) 'first_token_time_out': firstTokenTimeOut,
    if (sessionKeepTime != null) 'session_keep_time': sessionKeepTime,
    if (itemsToAdd.isNotEmpty)
      'items_to_add': itemsToAdd.map((item) => item.toJson()).toList(),
    if (itemsToUpdate.isNotEmpty)
      'items_to_update': itemsToUpdate.map((item) => item.toJson()).toList(),
    if (itemsToDelete.isNotEmpty) 'items_to_delete': itemsToDelete,
  };

  factory GroupUpdateRequest.fromDiff(Group previous, Group next) {
    final previousItems = previous.items
        .map(
          (item) => GroupItem(
            id: item.id,
            groupId: item.groupId,
            channelId: item.channelId,
            modelName: item.modelName.trim(),
            priority: item.priority,
            weight: item.weight > 0 ? item.weight : 1,
          ),
        )
        .where((item) => item.channelId > 0 && item.modelName.isNotEmpty)
        .toList();

    final nextItems = <GroupItem>[];
    for (var index = 0; index < next.items.length; index++) {
      final item = next.items[index];
      final modelName = item.modelName.trim();
      if (item.channelId <= 0 || modelName.isEmpty) continue;
      nextItems.add(
        GroupItem(
          id: item.id,
          groupId: item.groupId,
          channelId: item.channelId,
          modelName: modelName,
          priority: index + 1,
          weight: item.weight > 0 ? item.weight : 1,
        ),
      );
    }

    final previousById = <int, GroupItem>{
      for (final item in previousItems)
        if (item.id > 0) item.id: item,
    };

    final keptPreviousIds = <int>{};
    final itemsToDelete = <int>{};
    final itemsToAdd = <GroupItemAddRequest>[];
    final itemsToUpdate = <GroupItemUpdateRequest>[];

    for (final item in nextItems) {
      final previousItem = item.id > 0 ? previousById[item.id] : null;
      final sameIdentity =
          previousItem != null &&
          previousItem.channelId == item.channelId &&
          previousItem.modelName == item.modelName;

      if (sameIdentity) {
        keptPreviousIds.add(item.id);
        if (previousItem.priority != item.priority ||
            previousItem.weight != item.weight) {
          itemsToUpdate.add(
            GroupItemUpdateRequest(
              id: item.id,
              priority: item.priority,
              weight: item.weight,
            ),
          );
        }
        continue;
      }

      itemsToAdd.add(
        GroupItemAddRequest(
          channelId: item.channelId,
          modelName: item.modelName,
          priority: item.priority,
          weight: item.weight,
        ),
      );

      if (previousItem != null) {
        itemsToDelete.add(previousItem.id);
      }
    }

    for (final item in previousItems) {
      if (item.id > 0 && !keptPreviousIds.contains(item.id)) {
        itemsToDelete.add(item.id);
      }
    }

    final nextName = next.name.trim();
    final nextEndpointType = normalizeGroupEndpointType(next.endpointType);
    final nextMatchRegex = next.matchRegex.trim();
    final nextFirstTokenTimeOut = next.firstTokenTimeOut;
    final nextSessionKeepTime = next.sessionKeepTime;

    return GroupUpdateRequest(
      id: previous.id,
      name: nextName != previous.name ? nextName : null,
      endpointType:
          nextEndpointType != normalizeGroupEndpointType(previous.endpointType)
          ? nextEndpointType
          : null,
      mode: next.mode != previous.mode ? next.mode : null,
      matchRegex: nextMatchRegex != previous.matchRegex ? nextMatchRegex : null,
      firstTokenTimeOut: nextFirstTokenTimeOut != previous.firstTokenTimeOut
          ? nextFirstTokenTimeOut
          : null,
      sessionKeepTime: nextSessionKeepTime != previous.sessionKeepTime
          ? nextSessionKeepTime
          : null,
      itemsToAdd: itemsToAdd,
      itemsToUpdate: itemsToUpdate,
      itemsToDelete: itemsToDelete.toList()..sort(),
    );
  }
}

class GroupItemAddRequest {
  final int channelId;
  final String modelName;
  final int priority;
  final int weight;

  const GroupItemAddRequest({
    required this.channelId,
    required this.modelName,
    required this.priority,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'channel_id': channelId,
    'model_name': modelName,
    'priority': priority,
    'weight': weight,
  };
}

class GroupItemUpdateRequest {
  final int id;
  final int priority;
  final int weight;

  const GroupItemUpdateRequest({
    required this.id,
    required this.priority,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'priority': priority,
    'weight': weight,
  };
}

const groupModeLabels = {
  1: 'Round Robin',
  2: 'Random',
  3: 'Failover',
  4: 'Weighted',
  5: 'Auto',
};

String normalizeGroupEndpointType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return '*';
  if (normalized == 'responses' || normalized == 'messages') {
    return 'chat';
  }
  return normalized;
}
