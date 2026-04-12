class Group {
  final int id;
  final String name;
  final int mode;
  final String matchRegex;
  final int firstTokenTimeOut;
  final int sessionKeepTime;
  final String createdTime;
  final List<GroupItem> items;

  Group({
    required this.id,
    required this.name,
    this.mode = 1,
    this.matchRegex = '',
    this.firstTokenTimeOut = 0,
    this.sessionKeepTime = 0,
    this.createdTime = '',
    this.items = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      mode: json['mode'] as int? ?? 1,
      matchRegex: json['match_regex'] as String? ?? '',
      firstTokenTimeOut: json['first_token_time_out'] as int? ?? 0,
      sessionKeepTime: json['session_keep_time'] as int? ?? 0,
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
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int? ?? 0,
      channelId: json['channel_id'] as int? ?? 0,
      modelName: json['model_name'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id > 0) 'id': id,
    'channel_id': channelId,
    'model_name': modelName,
    'priority': priority,
    'weight': weight,
  };
}

const groupModeLabels = {
  1: 'Round Robin',
  2: 'Random',
  3: 'Failover',
  4: 'Weighted',
};
