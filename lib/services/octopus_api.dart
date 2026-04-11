import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/group.dart';
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
    return Channel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Channel> updateChannel(Channel channel) async {
    final res = await _api.post(
      '/api/v1/channel/update',
      body: channel.toJson(),
    );
    return Channel.fromJson(res['data'] as Map<String, dynamic>);
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

  // ====== Group ======
  Future<List<Group>> getGroups() async {
    final res = await _api.get('/api/v1/group/list');
    final list = res['data'] as List? ?? [];
    return list.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Group> createGroup(Group group) async {
    final res = await _api.post('/api/v1/group/create', body: group.toJson());
    return Group.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Group> updateGroup(Group group) async {
    final res = await _api.post('/api/v1/group/update', body: group.toJson());
    return Group.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> deleteGroup(int id) async {
    await _api.delete('/api/v1/group/delete/$id');
  }

  // ====== API Key ======
  Future<List<APIKey>> getApiKeys() async {
    final res = await _api.get('/api/v1/apikey/list');
    final list = res['data'] as List? ?? [];
    return list.map((e) => APIKey.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<APIKey> createApiKey(APIKey apiKey) async {
    final res = await _api.post('/api/v1/apikey/create', body: apiKey.toJson());
    return APIKey.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<APIKey> updateApiKey(APIKey apiKey) async {
    final res = await _api.post('/api/v1/apikey/update', body: apiKey.toJson());
    return APIKey.fromJson(res['data'] as Map<String, dynamic>);
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

  Future<List<LLMChannel>> getModelChannels() async {
    final res = await _api.get('/api/v1/model/channel');
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return data.entries
        .map((e) => LLMChannel.fromJson(e.value as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateModelPrice() async {
    await _api.post('/api/v1/model/update-price');
  }

  // ====== Log ======
  Future<List<RelayLog>> getLogs({int page = 1, int pageSize = 20}) async {
    final res = await _api.get(
      '/api/v1/log/list?page=$page&page_size=$pageSize',
    );
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

  // ====== Update ======
  Future<String> getCurrentVersion() async {
    final res = await _api.get('/api/v1/update/now-version');
    return res['data']?.toString() ?? 'unknown';
  }

  Future<Map<String, dynamic>> checkUpdate() async {
    final res = await _api.get('/api/v1/update');
    return res['data'] as Map<String, dynamic>? ?? {};
  }
}
