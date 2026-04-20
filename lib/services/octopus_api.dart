import 'dart:convert';
import 'package:octopusmanage/models/ai_route.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/channel_probe.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/models/group_probe.dart';
import 'package:octopusmanage/models/llm.dart';
import 'package:octopusmanage/models/relay_log.dart';
import 'package:octopusmanage/models/setting.dart';
import 'package:octopusmanage/models/stats.dart';
import 'api_service.dart';

class OctopusApi {
  final ApiService _api;
  OctopusApi(this._api);

  // ====== Auth ======
  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    int expire = -1,
  }) async {
    final res = await _api.post(
      '/api/v1/user/login',
      body: {'username': username, 'password': password, 'expire': expire},
    );
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> changeUsername(String newUsername) async {
    await _api.post(
      '/api/v1/user/change-username',
      body: {'new_username': newUsername},
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.post(
      '/api/v1/user/change-password',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  Future<Map<String, dynamic>> checkBootstrap() async {
    final res = await _api.get('/api/v1/bootstrap/status');
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<bool> createAdmin(String username, String password) async {
    final res = await _api.post(
      '/api/v1/bootstrap/create-admin',
      body: {'username': username, 'password': password},
    );
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return data['initialized'] == true;
  }

  // ====== Stats ======
  Future<StatsMetrics> getStatsToday() async {
    final res = await _api.get('/api/v1/stats/today');
    return StatsMetrics.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<StatsMetrics> getStatsTotal() async {
    final res = await _api.get('/api/v1/stats/total');
    return StatsMetrics.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<StatsDaily>> getStatsDaily() async {
    final res = await _api.get('/api/v1/stats/daily');
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => StatsDaily.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StatsHourly>> getStatsHourly() async {
    final res = await _api.get('/api/v1/stats/hourly');
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => StatsHourly.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StatsAPIKeyEntry>> getStatsApiKey() async {
    final res = await _api.get('/api/v1/stats/apikey');
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => StatsAPIKeyEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ====== Channel ======
  Future<List<Channel>> getChannels() async {
    final res = await _api.get('/api/v1/channel/list');
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Channel> createChannel(Channel channel) async {
    final res = await _api.post(
      '/api/v1/channel/create',
      body: channel.toJson(),
    );
    return Channel.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<Channel> updateChannel(Channel channel) async {
    final res = await _api.post(
      '/api/v1/channel/update',
      body: channel.toJson(),
    );
    return Channel.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> enableChannel(int id, bool enabled) async {
    await _api.post(
      '/api/v1/channel/enable',
      body: {'id': id, 'enabled': enabled},
    );
  }

  Future<void> deleteChannel(int id) async {
    await _api.delete('/api/v1/channel/delete/$id');
  }

  Future<List<String>> fetchModels(Channel channel) async {
    final res = await _api.post(
      '/api/v1/channel/fetch-model',
      body: channel.toJson(),
    );
    return (res['data'] as List? ?? []).map((e) => e.toString()).toList();
  }

  Future<void> syncChannels() async {
    await _api.post('/api/v1/channel/sync');
  }

  Future<ChannelTestSummary> testChannel(Channel channel) async {
    final res = await _api.post('/api/v1/channel/test', body: channel.toJson());
    return ChannelTestSummary.fromJson(
      res['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<String> getLastSyncTime() async {
    final res = await _api.get('/api/v1/channel/last-sync-time');
    return res['data']?.toString() ?? '';
  }

  // ====== Group ======
  Future<List<Group>> getGroups() async {
    final res = await _api.get('/api/v1/group/list');
    final list = res['data'] as List? ?? [];
    return list.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Group> createGroup(Group group) async {
    final res = await _api.post('/api/v1/group/create', body: group.toJson());
    return Group.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<Group> updateGroup(Object payload) async {
    final body = switch (payload) {
      Group group => group.toJson(),
      GroupUpdateRequest request => request.toJson(),
      Map<String, dynamic> map => map,
      _ => throw ArgumentError('Unsupported group update payload: $payload'),
    };
    final res = await _api.post('/api/v1/group/update', body: body);
    return Group.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> deleteGroup(int id) async {
    await _api.delete('/api/v1/group/delete/$id');
  }

  Future<void> deleteAllGroups() async {
    await _api.delete('/api/v1/group/delete-all');
  }

  Future<AutoGroupResult> autoGroupModels() async {
    final res = await _api.post('/api/v1/group/auto-group');
    return AutoGroupResult.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<GroupModelTestProgress> startGroupTest(int groupId) async {
    final res = await _api.post(
      '/api/v1/group/test',
      body: {'group_id': groupId},
    );
    return GroupModelTestProgress.fromJson(
      res['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<GroupModelTestProgress> getGroupTestProgress(String id) async {
    final res = await _api.get('/api/v1/group/test/progress/$id');
    return GroupModelTestProgress.fromJson(
      res['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<AIRouteProgress> generateAIRoute({
    required AIRouteScope scope,
    int? groupId,
  }) async {
    final res = await _api.post(
      '/api/v1/route/ai-generate',
      body: {
        'scope': scope.value,
        if (scope == AIRouteScope.group && groupId != null) 'group_id': groupId,
      },
    );
    return AIRouteProgress.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<AIRouteProgress> getAIRouteProgress(String id) async {
    final res = await _api.get('/api/v1/route/ai-generate/progress/$id');
    return AIRouteProgress.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  // ====== API Key ======
  Future<List<APIKey>> getApiKeys() async {
    final res = await _api.get('/api/v1/apikey/list');
    final list = res['data'] as List? ?? [];
    return list.map((e) => APIKey.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<APIKey> createApiKey(APIKey apiKey) async {
    final res = await _api.post('/api/v1/apikey/create', body: apiKey.toJson());
    return APIKey.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<APIKey> updateApiKey(APIKey apiKey) async {
    final res = await _api.post('/api/v1/apikey/update', body: apiKey.toJson());
    return APIKey.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> deleteApiKey(int id) async {
    await _api.delete('/api/v1/apikey/delete/$id');
  }

  // ====== Model / Price ======
  Future<List<LLMInfo>> getModels() async {
    final res = await _api.get('/api/v1/model/list');
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => LLMInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LLMInfo> createModel(LLMInfo model) async {
    final res = await _api.post('/api/v1/model/create', body: model.toJson());
    return LLMInfo.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<LLMInfo> updateModel(LLMInfo model) async {
    final res = await _api.post('/api/v1/model/update', body: model.toJson());
    return LLMInfo.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> deleteModel(String name) async {
    await _api.post('/api/v1/model/delete', body: {'name': name});
  }

  Future<List<LLMChannel>> getModelChannels() async {
    final res = await _api.get('/api/v1/model/channel');
    // 后端可能返回 Map（以 key 为名称的对象）或 List，两种格式都支持
    final data = res['data'];
    if (data is List) {
      return data
          .map((e) => LLMChannel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (data is Map<String, dynamic>) {
      return data.values
          .map((e) => LLMChannel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> updateModelPrice() async {
    await _api.post('/api/v1/model/update-price');
  }

  Future<String> getLastModelUpdateTime() async {
    final res = await _api.get('/api/v1/model/last-update-time');
    return res['data']?.toString() ?? '';
  }

  // ====== Log ======
  Future<List<RelayLog>> getLogs({int page = 1, int pageSize = 20}) async {
    final query = Uri(
      queryParameters: {'page': '$page', 'page_size': '$pageSize'},
    ).query;
    final res = await _api.get('/api/v1/log/list?$query');
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => RelayLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearLogs() async {
    await _api.delete('/api/v1/log/clear');
  }

  // ====== Setting ======
  Future<List<Setting>> getSettings() async {
    final res = await _api.get('/api/v1/setting/list');
    final list = res['data'] as List? ?? [];
    return list
        .map((e) => Setting.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setSetting(String key, String value) async {
    await _api.post('/api/v1/setting/set', body: {'key': key, 'value': value});
  }

  Future<String> exportSettings({
    bool includeLogs = false,
    bool includeStats = false,
  }) async {
    final res = await _api.get(
      '/api/v1/setting/export',
      query: {
        'include_logs': includeLogs.toString(),
        'include_stats': includeStats.toString(),
      },
    );
    // export returns JSON as a string
    return jsonEncode(res);
  }

  Future<Map<String, dynamic>> importSettings(String jsonData) async {
    final res = await _api.post(
      '/api/v1/setting/import',
      body: jsonData,
      contentType: 'application/json',
    );
    if (res is String) {
      final decoded = jsonDecode(res) as Map<String, dynamic>;
      return decoded['data'] as Map<String, dynamic>? ?? decoded;
    }
    if (res is Map<String, dynamic>) {
      return res['data'] as Map<String, dynamic>? ?? res;
    }
    return {};
  }

  // ====== Update ======
  Future<String> getCurrentVersion() async {
    final res = await _api.get('/api/v1/update/now-version');
    return res['data']?.toString() ?? 'unknown';
  }

  Future<Map<String, dynamic>> checkUpdate() async {
    final res = await _api.get('/api/v1/update');
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> updateCore() async {
    await _api.post('/api/v1/update');
  }
}
