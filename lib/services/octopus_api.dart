import 'dart:convert';
import 'package:octopusmanage/models/ai_route.dart';
import 'package:octopusmanage/models/alert.dart';
import 'package:octopusmanage/models/analytics.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/models/audit_log.dart';
import 'package:octopusmanage/models/model_market.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/channel_probe.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/models/group_probe.dart';
import 'package:octopusmanage/models/llm.dart';
import 'package:octopusmanage/models/ops.dart';
import 'package:octopusmanage/models/relay_log.dart';
import 'package:octopusmanage/models/setting.dart';
import 'package:octopusmanage/models/api_credential.dart';
import 'package:octopusmanage/models/model_mapping.dart';
import 'package:octopusmanage/models/proxy.dart';
import 'package:octopusmanage/models/site.dart';
import 'package:octopusmanage/models/site_channel.dart';
import 'package:octopusmanage/models/stats.dart';
import 'package:octopusmanage/models/user.dart';
import 'package:octopusmanage/utils/parse_utils.dart';
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
    return parseJsonMap(res['data']) ?? {};
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
    return parseJsonMap(res['data']) ?? {};
  }

  Future<bool> createAdmin(String username, String password) async {
    final res = await _api.post(
      '/api/v1/bootstrap/create-admin',
      body: {'username': username, 'password': password},
    );
    final data = parseJsonMap(res['data']) ?? {};
    return parseBool(data['initialized']);
  }

  // ====== User ======
  Future<List<User>> getUsers() async {
    final res = await _api.get('/api/v1/user/list');
    return parseJsonMapList(res['data']).map(User.fromJson).toList();
  }

  Future<void> createUser(String username, String password, String role) async {
    await _api.post(
      '/api/v1/user/create',
      body: {'username': username, 'password': password, 'role': role},
    );
  }

  Future<void> updateUserRole(int id, String role) async {
    await _api.post(
      '/api/v1/user/update-role',
      body: {'id': id, 'role': role},
    );
  }

  Future<void> deleteUser(int id) async {
    await _api.delete('/api/v1/user/delete/$id');
  }

  Future<bool> checkUserStatus() async {
    final res = await _api.get('/api/v1/user/status');
    return res['data'] == 'ok';
  }

  // ====== Stats ======
  Future<StatsMetrics> getStatsToday() async {
    final res = await _api.get('/api/v1/stats/today');
    return StatsMetrics.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<StatsMetrics> getStatsTotal() async {
    final res = await _api.get('/api/v1/stats/total');
    return StatsMetrics.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<List<StatsDaily>> getStatsDaily() async {
    final res = await _api.get('/api/v1/stats/daily');
    return parseJsonMapList(res['data']).map(StatsDaily.fromJson).toList();
  }

  Future<List<StatsHourly>> getStatsHourly() async {
    final res = await _api.get('/api/v1/stats/hourly');
    return parseJsonMapList(res['data']).map(StatsHourly.fromJson).toList();
  }

  Future<List<StatsAPIKeyEntry>> getStatsApiKey() async {
    final res = await _api.get('/api/v1/stats/apikey');
    return parseJsonMapList(
      res['data'],
    ).map(StatsAPIKeyEntry.fromJson).toList();
  }

  // ====== Stats ======
  // (existing stats methods above)

  Future<List<StatsChannel>> getStatsChannel() async {
    final res = await _api.get('/api/v1/stats/channel');
    return parseJsonMapList(res['data']).map(StatsChannel.fromJson).toList();
  }

  // ====== Channel ======
  Future<List<Channel>> getChannels() async {
    final res = await _api.get('/api/v1/channel/list');
    return parseJsonMapList(res['data']).map(Channel.fromJson).toList();
  }

  Future<Channel> createChannel(Channel channel) async {
    final res = await _api.post(
      '/api/v1/channel/create',
      body: channel.toJson(),
    );
    return Channel.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<Channel> updateChannel(ChannelUpdateRequest request) async {
    final res = await _api.post(
      '/api/v1/channel/update',
      body: request.toJson(),
    );
    return Channel.fromJson(parseJsonMap(res['data']) ?? {});
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
    return parseStringList(res['data']);
  }

  Future<void> syncChannels() async {
    await _api.post('/api/v1/channel/sync');
  }

  Future<ChannelTestSummary> testChannel(Channel channel) async {
    final res = await _api.post('/api/v1/channel/test', body: channel.toJson());
    return ChannelTestSummary.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<String> getLastSyncTime() async {
    final res = await _api.get('/api/v1/channel/last-sync-time');
    return res['data']?.toString() ?? '';
  }

  // ====== Group ======
  Future<List<Group>> getGroups() async {
    final res = await _api.get('/api/v1/group/list');
    return parseJsonMapList(res['data']).map(Group.fromJson).toList();
  }

  Future<Group> createGroup(Group group) async {
    final res = await _api.post('/api/v1/group/create', body: group.toJson());
    return Group.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<Group> updateGroup(Object payload) async {
    final body = switch (payload) {
      Group group => group.toJson(),
      GroupUpdateRequest request => request.toJson(),
      Map<String, dynamic> map => map,
      _ => throw ArgumentError('Unsupported group update payload: $payload'),
    };
    final res = await _api.post('/api/v1/group/update', body: body);
    return Group.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> deleteGroup(int id) async {
    await _api.delete('/api/v1/group/delete/$id');
  }

  Future<void> deleteAllGroups() async {
    await _api.delete('/api/v1/group/delete-all');
  }

  Future<AutoGroupResult> autoGroupModels() async {
    final res = await _api.post('/api/v1/group/auto-group');
    return AutoGroupResult.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<GroupModelTestProgress> startGroupTest(int groupId) async {
    final res = await _api.post(
      '/api/v1/group/test',
      body: {'group_id': groupId},
    );
    return GroupModelTestProgress.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<GroupModelTestProgress> getGroupTestProgress(String id) async {
    final res = await _api.get('/api/v1/group/test/progress/$id');
    return GroupModelTestProgress.fromJson(parseJsonMap(res['data']) ?? {});
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
    return AIRouteProgress.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<AIRouteProgress> getAIRouteProgress(String id) async {
    final res = await _api.get('/api/v1/route/ai-generate/progress/$id');
    return AIRouteProgress.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<AIRouteProgress> getAIRouteStatus(String id) async {
    final res = await _api.get('/api/v1/route/ai-generate/status/$id');
    return AIRouteProgress.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<AIRouteProgress> getAIRouteResult(String id) async {
    final res = await _api.get('/api/v1/route/ai-generate/result/$id');
    return AIRouteProgress.fromJson(parseJsonMap(res['data']) ?? {});
  }

  // ====== API Key ======
  Future<List<APIKey>> getApiKeys() async {
    final res = await _api.get('/api/v1/apikey/list');
    return parseJsonMapList(res['data']).map(APIKey.fromJson).toList();
  }

  Future<APIKey> createApiKey(APIKey apiKey) async {
    final res = await _api.post('/api/v1/apikey/create', body: apiKey.toJson());
    return APIKey.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<APIKey> updateApiKey(APIKey apiKey) async {
    final res = await _api.post('/api/v1/apikey/update', body: apiKey.toJson());
    return APIKey.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> deleteApiKey(int id) async {
    await _api.delete('/api/v1/apikey/delete/$id');
  }

  // ====== Model / Price ======
  Future<List<LLMInfo>> getModels() async {
    final res = await _api.get('/api/v1/model/list');
    return parseJsonMapList(res['data']).map(LLMInfo.fromJson).toList();
  }

  Future<LLMInfo> createModel(LLMInfo model) async {
    final res = await _api.post('/api/v1/model/create', body: model.toJson());
    return LLMInfo.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<LLMInfo> updateModel(LLMInfo model) async {
    final res = await _api.post('/api/v1/model/update', body: model.toJson());
    return LLMInfo.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> deleteModel(String name) async {
    await _api.post('/api/v1/model/delete', body: {'name': name});
  }

  Future<List<LLMChannel>> getModelChannels() async {
    final res = await _api.get('/api/v1/model/channel');
    // 后端可能返回 Map（以 key 为名称的对象）或 List，两种格式都支持
    final data = res['data'];
    if (data is List) {
      return parseJsonMapList(data).map(LLMChannel.fromJson).toList();
    } else if (data is Map) {
      return data.entries
          .map((entry) {
            final item = parseJsonMap(entry.value);
            if (item == null) return null;
            return LLMChannel.fromJson({'name': entry.key.toString(), ...item});
          })
          .whereType<LLMChannel>()
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

  Future<ModelMarketResponse> getModelMarket() async {
    final res = await _api.get('/api/v1/model/market');
    return ModelMarketResponse.fromJson(parseJsonMap(res['data']) ?? {});
  }

  // ====== Log ======
  Future<List<RelayLog>> getLogs({int page = 1, int pageSize = 20}) async {
    final res = await _api.get(
      '/api/v1/log/list',
      query: {'page': '$page', 'page_size': '$pageSize'},
    );
    return parseJsonMapList(res['data']).map(RelayLog.fromJson).toList();
  }

  Future<RelayLog> getLogDetail(int id) async {
    final res = await _api.get('/api/v1/log/detail', query: {'id': '$id'});
    return RelayLog.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> clearLogs() async {
    await _api.delete('/api/v1/log/clear');
  }

  // ====== Setting ======
  Future<List<Setting>> getSettings() async {
    final res = await _api.get('/api/v1/setting/list');
    return parseJsonMapList(res['data']).map(Setting.fromJson).toList();
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
      final decoded = parseJsonMap(jsonDecode(res)) ?? {};
      return parseJsonMap(decoded['data']) ?? decoded;
    }
    if (res is Map<String, dynamic>) {
      return parseJsonMap(res['data']) ?? res;
    }
    return {};
  }

  // ====== Alert ======
  Future<List<AlertRule>> getAlertRules() async {
    final res = await _api.get('/api/v1/alert/rule/list');
    return parseJsonMapList(res['data']).map(AlertRule.fromJson).toList();
  }

  Future<AlertRule> createAlertRule(AlertRule rule) async {
    final res = await _api.post(
      '/api/v1/alert/rule/create',
      body: rule.toJson(),
    );
    return AlertRule.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> updateAlertRule(AlertRule rule) async {
    await _api.post('/api/v1/alert/rule/update', body: rule.toJson());
  }

  Future<void> deleteAlertRule(int id) async {
    await _api.delete('/api/v1/alert/rule/delete/$id');
  }

  Future<List<AlertNotifChannel>> getNotifChannels() async {
    final res = await _api.get('/api/v1/alert/notif/list');
    return parseJsonMapList(res['data'])
        .map(AlertNotifChannel.fromJson)
        .toList();
  }

  Future<AlertNotifChannel> createNotifChannel(AlertNotifChannel ch) async {
    final res = await _api.post('/api/v1/alert/notif/create', body: ch.toJson());
    return AlertNotifChannel.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> updateNotifChannel(AlertNotifChannel ch) async {
    await _api.post('/api/v1/alert/notif/update', body: ch.toJson());
  }

  Future<void> deleteNotifChannel(int id) async {
    await _api.delete('/api/v1/alert/notif/delete/$id');
  }

  Future<List<AlertHistory>> getAlertHistory({int limit = 100}) async {
    final res = await _api.get(
      '/api/v1/alert/history',
      query: {'limit': '$limit'},
    );
    return parseJsonMapList(res['data']).map(AlertHistory.fromJson).toList();
  }

  // ====== Ops ======
  Future<OpsCacheStatus> getOpsCache() async {
    final res = await _api.get('/api/v1/ops/cache');
    return OpsCacheStatus.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<OpsQuotaSummary> getOpsQuota() async {
    final res = await _api.get('/api/v1/ops/quota');
    return OpsQuotaSummary.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<OpsHealthStatus> getOpsHealth() async {
    final res = await _api.get('/api/v1/ops/health');
    return OpsHealthStatus.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<OpsSystemSummary> getOpsSystem() async {
    final res = await _api.get('/api/v1/ops/system');
    return OpsSystemSummary.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<OpsTelemetrySummary> getOpsTelemetry() async {
    final res = await _api.get('/api/v1/ops/telemetry');
    return OpsTelemetrySummary.fromJson(parseJsonMap(res['data']) ?? {});
  }

  // ====== Analytics ======
  Future<AnalyticsOverview> getAnalyticsOverview({String range = '7d'}) async {
    final res = await _api.get(
      '/api/v1/analytics/overview',
      query: {'range': range},
    );
    return AnalyticsOverview.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<List<AnalyticsBreakdownItem>> getAnalyticsProviderBreakdown({
    String range = '7d',
  }) async {
    final res = await _api.get(
      '/api/v1/analytics/provider-breakdown',
      query: {'range': range},
    );
    return parseJsonMapList(res['data'])
        .map(AnalyticsBreakdownItem.fromProviderJson)
        .toList();
  }

  Future<List<AnalyticsBreakdownItem>> getAnalyticsModelBreakdown({
    String range = '7d',
  }) async {
    final res = await _api.get(
      '/api/v1/analytics/model-breakdown',
      query: {'range': range},
    );
    return parseJsonMapList(res['data'])
        .map(AnalyticsBreakdownItem.fromModelJson)
        .toList();
  }

  Future<List<AnalyticsBreakdownItem>> getAnalyticsApiKeyBreakdown({
    String range = '7d',
  }) async {
    final res = await _api.get(
      '/api/v1/analytics/apikey-breakdown',
      query: {'range': range},
    );
    return parseJsonMapList(res['data'])
        .map(AnalyticsBreakdownItem.fromApiKeyJson)
        .toList();
  }

  Future<List<AnalyticsGroupHealthItem>> getAnalyticsGroupHealth() async {
    final res = await _api.get('/api/v1/analytics/group-health');
    return parseJsonMapList(res['data'])
        .map(AnalyticsGroupHealthItem.fromJson)
        .toList();
  }

  Future<AnalyticsUtilization> getAnalyticsUtilization({
    String range = '7d',
  }) async {
    final res = await _api.get(
      '/api/v1/analytics/utilization',
      query: {'range': range},
    );
    return AnalyticsUtilization.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<AnalyticsEvaluationSummary> getAnalyticsEvaluation() async {
    final res = await _api.get('/api/v1/analytics/evaluation');
    final data = parseJsonMap(res['data']) ?? {};
    return AnalyticsEvaluationSummary.fromJson(
      parseJsonMap(data['semantic_cache']) ?? {},
    );
  }

  Future<List<AnalyticsChannelModelItem>> getAnalyticsChannelModel({
    String range = '7d',
  }) async {
    final res = await _api.get(
      '/api/v1/analytics/channel-model',
      query: {'range': range},
    );
    return parseJsonMapList(res['data'])
        .map(AnalyticsChannelModelItem.fromJson)
        .toList();
  }

  Future<AnalyticsLatencyDistribution> getAnalyticsLatencyDistribution({
    String range = '7d',
  }) async {
    final res = await _api.get(
      '/api/v1/analytics/latency-distribution',
      query: {'range': range},
    );
    return AnalyticsLatencyDistribution.fromJson(
      parseJsonMap(res['data']) ?? {},
    );
  }

  Future<List<AutoStrategySnapshotItem>> getAnalyticsAutoStrategy() async {
    final res = await _api.get('/api/v1/analytics/auto-strategy');
    return parseJsonMapList(res['data'])
        .map(AutoStrategySnapshotItem.fromJson)
        .toList();
  }

  // ====== Audit ======
  Future<List<AuditLog>> getAuditLogs({int page = 1, int pageSize = 50}) async {
    final res = await _api.get(
      '/api/v1/audit/list',
      query: {'page': '$page', 'page_size': '$pageSize'},
    );
    return parseJsonMapList(res['data']).map(AuditLog.fromJson).toList();
  }

  Future<AuditLog> getAuditLogDetail(int id) async {
    final res = await _api.get('/api/v1/audit/detail', query: {'id': '$id'});
    return AuditLog.fromJson(parseJsonMap(res['data']) ?? {});
  }

  // ====== Site ======
  Future<List<Site>> getSites() async {
    final res = await _api.get('/api/v1/site/list');
    return parseJsonMapList(res['data']).map(Site.fromJson).toList();
  }

  Future<Site> getSite(int id) async {
    final sites = await getSites();
    return sites.firstWhere(
      (site) => site.id == id,
      orElse: () => Site(id: id),
    );
  }

  Future<Site> createSite(Site site) async {
    final res = await _api.post('/api/v1/site/create', body: site.toJson());
    return Site.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<Site> updateSite(Site site) async {
    final res = await _api.post('/api/v1/site/update', body: site.toJson());
    return Site.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> deleteSite(int id) async {
    await _api.delete('/api/v1/site/delete/$id');
  }

  Future<void> enableSite(int id, bool enabled) async {
    await _api.post(
      '/api/v1/site/enable',
      body: {'id': id, 'enabled': enabled},
    );
  }

  Future<Site> detectSite(String baseUrl) async {
    final res = await _api.post(
      '/api/v1/site/detect',
      body: {'url': baseUrl},
    );
    return Site.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> batchUpdateSites(
    List<int> ids,
    Map<String, dynamic> updates,
  ) async {
    final action = updates['action']?.toString() ??
        (updates['enabled'] == true
            ? 'enable'
            : updates['enabled'] == false
                ? 'disable'
                : 'delete');
    await _api.post(
      '/api/v1/site/batch',
      body: {'ids': ids, 'action': action},
    );
  }

  Future<void> archiveSite(int id) async {
    await _api.post('/api/v1/site/archive/$id');
  }

  Future<void> restoreSite(int id) async {
    await _api.post('/api/v1/site/restore/$id');
  }

  Future<List<SiteAccount>> getSiteAccounts(int siteId) async {
    final res = await _api.get(
      '/api/v1/site/accounts',
      query: {'site_id': '$siteId'},
    );
    return parseJsonMapList(res['data']).map(SiteAccount.fromJson).toList();
  }

  Future<List<SiteToken>> getSiteTokens(int siteId) async {
    final res = await _api.get('/api/v1/remote-site-token/list/$siteId');
    return parseJsonMapList(res['data']).map(SiteToken.fromJson).toList();
  }

  Future<List<SiteModel>> getSiteModels(int siteId) async {
    final res = await _api.get(
      '/api/v1/site/models',
      query: {'site_id': '$siteId'},
    );
    return parseJsonMapList(res['data']).map(SiteModel.fromJson).toList();
  }

  // ====== Site Sync ======
  Future<void> syncSite(int siteId) async {
    await _api.post('/api/v1/site/account/sync/$siteId');
  }

  Future<void> syncAllSites() async {
    await _api.post('/api/v1/site/sync-all');
  }

  // ====== Site Check-in ======
  Future<CheckInRecord> checkInSite(int siteId, int accountId) async {
    final res = await _api.post('/api/v1/site/account/checkin/$accountId');
    return CheckInRecord.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<List<CheckInRecord>> checkInAllSites() async {
    final res = await _api.post('/api/v1/site/checkin-all');
    return parseJsonMapList(res['data']).map(CheckInRecord.fromJson).toList();
  }

  Future<List<CheckInRecord>> getCheckInHistory(
    int siteId, {
    int limit = 30,
  }) async {
    final res = await _api.get(
      '/api/v1/site/checkin/history',
      query: {'site_id': '$siteId', 'limit': '$limit'},
    );
    return parseJsonMapList(res['data']).map(CheckInRecord.fromJson).toList();
  }

  // ====== Site Redemption ======
  Future<RedemptionRecord> redeemCode(
    int siteId,
    int accountId,
    String code,
  ) async {
    final res = await _api.post(
      '/api/v1/site/redeem',
      body: {
        'site_id': siteId,
        'account_id': accountId,
        'code': code,
      },
    );
    return RedemptionRecord.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<List<RedemptionRecord>> batchRedeem(
    List<int> siteIds,
    String code,
  ) async {
    final res = await _api.post(
      '/api/v1/site/redeem-batch',
      body: {'site_ids': siteIds, 'code': code},
    );
    return parseJsonMapList(res['data'])
        .map(RedemptionRecord.fromJson)
        .toList();
  }

  Future<List<RedemptionRecord>> getRedemptionHistory(
    int siteId, {
    int limit = 30,
  }) async {
    final res = await _api.get(
      '/api/v1/site/redeem/history',
      query: {'site_id': '$siteId', 'limit': '$limit'},
    );
    return parseJsonMapList(res['data'])
        .map(RedemptionRecord.fromJson)
        .toList();
  }

  // ====== Site Balance ======
  Future<BalanceSnapshot> getBalance(int siteId, int accountId) async {
    final res = await _api.get(
      '/api/v1/site/balance',
      query: {'site_id': '$siteId', 'account_id': '$accountId'},
    );
    return BalanceSnapshot.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<List<BalanceSnapshot>> getBalanceHistory(
    int siteId,
    int accountId, {
    int days = 30,
  }) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final res = await _api.get(
      '/api/v1/balance-history/list/$siteId',
      query: {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      },
    );
    return parseJsonMapList(res['data'])
        .map(BalanceSnapshot.fromJson)
        .toList();
  }

  Future<BalancePrediction> getBalancePrediction(
    int siteId,
    int accountId,
  ) async {
    final res = await _api.get('/api/v1/balance-history/prediction/$siteId');
    return BalancePrediction.fromJson(parseJsonMap(res['data']) ?? {});
  }

  // ====== Proxy Pool ======
  Future<List<ProxyConfiguration>> getProxies() async {
    final res = await _api.get('/api/v1/proxy-pool/list');
    return parseJsonMapList(res['data'])
        .map(ProxyConfiguration.fromJson)
        .toList();
  }

  Future<ProxyConfiguration> createProxy(ProxyConfiguration proxy) async {
    final res = await _api.post(
      '/api/v1/proxy-pool/create',
      body: proxy.toJson(),
    );
    return ProxyConfiguration.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<ProxyConfiguration> updateProxy(ProxyConfiguration proxy) async {
    final res = await _api.post(
      '/api/v1/proxy-pool/update',
      body: proxy.toJson(),
    );
    return ProxyConfiguration.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> deleteProxy(int id) async {
    await _api.delete('/api/v1/proxy-pool/delete/$id');
  }

  Future<Map<String, dynamic>> testProxy(String url, String type,
      {String? username, String? password}) async {
    final body = <String, dynamic>{
      'url': url,
      'proxy_url': url,
    };
    final res = await _api.post('/api/v1/proxy-pool/test', body: body);
    return parseJsonMap(res['data']) ?? {};
  }

  // ====== Model Mapping ======
  Future<List<ModelMapping>> getModelMappings() async {
    final res = await _api.get('/api/v1/model-mapping');
    return parseJsonMapList(res['data'])
        .map(ModelMapping.fromJson)
        .toList();
  }

  Future<ModelMapping> createModelMapping(ModelMapping mapping) async {
    final res = await _api.post(
      '/api/v1/model-mapping',
      body: mapping.toJson(),
    );
    return ModelMapping.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<ModelMapping> updateModelMapping(ModelMapping mapping) async {
    final res = await _api.put(
      '/api/v1/model-mapping/${mapping.id}',
      body: mapping.toJson(),
    );
    return ModelMapping.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> deleteModelMapping(int id) async {
    await _api.delete('/api/v1/model-mapping/$id');
  }

  // ====== API Credential Profiles ======
  Future<List<APICredentialProfile>> getCredentials() async {
    final res = await _api.get('/api/v1/api-credential/list');
    return parseJsonMapList(res['data'])
        .map(APICredentialProfile.fromJson)
        .toList();
  }

  Future<APICredentialProfile> createCredential(
      APICredentialProfile credential) async {
    final res = await _api.post(
      '/api/v1/api-credential/create',
      body: credential.toJson(),
    );
    return APICredentialProfile.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<APICredentialProfile> updateCredential(
      APICredentialProfile credential) async {
    final res = await _api.post(
      '/api/v1/api-credential/update',
      body: credential.toJson(),
    );
    return APICredentialProfile.fromJson(parseJsonMap(res['data']) ?? {});
  }

  Future<void> deleteCredential(int id) async {
    await _api.delete('/api/v1/api-credential/delete/$id');
  }

  Future<List<String>> getCredentialApiTypes() async {
    final res = await _api.get('/api/v1/api-credential/api-types');
    return parseStringList(res['data']);
  }

  Future<List<String>> getCredentialCliTools() async {
    final res = await _api.get('/api/v1/api-credential/cli-tools');
    return parseStringList(res['data']);
  }

  Future<List<VerificationProbe>> getVerificationProbes() async {
    final res = await _api.get('/api/v1/verification/probes');
    return parseJsonMapList(res['data'])
        .map(VerificationProbe.fromJson)
        .toList();
  }

  Future<List<VerificationResult>> runVerification(
      int credentialId, List<String> probes) async {
    final res = await _api.post(
      '/api/v1/verification/run-for/$credentialId',
      body: {'probes': probes},
    );
    return parseJsonMapList(res['data'])
        .map(VerificationResult.fromJson)
        .toList();
  }

  Future<String> exportCliConfig(int credentialId, String tool) async {
    final credentials = await getCredentials();
    final credential = credentials.firstWhere(
      (item) => item.id == credentialId,
      orElse: () => APICredentialProfile(id: credentialId),
    );
    final res = await _api.post(
      '/api/v1/cli-export/generate',
      body: {
        'base_url': credential.baseUrl,
        'api_key': credential.apiKey,
        'api_type': credential.apiType,
        'tool': tool.replaceAll('-', '_'),
      },
    );
    return res['data']?.toString() ?? '';
  }

  // ====== Site Channel Projection ======
  Future<List<SiteChannelCard>> getSiteChannels(int siteId) async {
    final res = await _api.get('/api/v1/site-channel/$siteId');
    return _parseSiteChannelCards(res['data'], siteId: siteId);
  }

  Future<SiteChannelCard> getSiteChannel(
      int siteId, int channelId) async {
    final res = await _api.get('/api/v1/site-channel/$siteId/account/$channelId');
    final cards = _parseSiteChannelCards(res['data'], siteId: siteId);
    return cards.isEmpty ? SiteChannelCard(siteId: siteId, accountId: channelId) : cards.first;
  }

  Future<List<APIKey>> getSiteChannelKeys(
      int siteId, int channelId) async {
    final res = await _api.get('/api/v1/site-channel/$siteId/account/$channelId');
    final data = parseJsonMap(res['data']) ?? {};
    return parseJsonMapList(data['keys']).map(APIKey.fromJson).toList();
  }

  Future<List<APIKey>> getSiteChannelSourceKeys(int siteId) async {
    final res = await _api.get('/api/v1/site-channel/$siteId');
    final keys = <APIKey>[];
    for (final account in parseJsonMapList(res['data'])) {
      keys.addAll(parseJsonMapList(account['source_keys']).map(APIKey.fromJson));
    }
    return keys;
  }

  Future<List<SiteChannelGroup>> getSiteChannelGroupProjection(
      int siteId) async {
    final res = await _api.get('/api/v1/site-channel/$siteId');
    final groups = <SiteChannelGroup>[];
    for (final account in parseJsonMapList(res['data'])) {
      groups.addAll(
        parseJsonMapList(account['groups']).map(SiteChannelGroup.fromJson),
      );
    }
    return groups;
  }

  Future<List<SiteChannelModel>> getSiteChannelModelRoutes(
      int siteId, int channelId) async {
    final res = await _api.get(
      '/api/v1/site-channel/$siteId/account/$channelId/model-history',
    );
    return _parseSiteChannelModels(res['data'], channelId: channelId);
  }

  Future<List<SiteChannelModel>> getSiteChannelManualModels(
      int siteId, int channelId) async {
    final res = await _api.get('/api/v1/site-channel/$siteId/account/$channelId');
    final data = parseJsonMap(res['data']) ?? {};
    return _parseSiteChannelModels(data['manual_models'], channelId: channelId);
  }

  Future<void> addSiteChannelManualModel(
      int siteId, int channelId, String modelName) async {
    await _api.post(
      '/api/v1/site-channel/$siteId/account/$channelId/manual-models',
      body: {
        'group_key': '',
        'models': [
          {'model_name': modelName, 'route_type': 'openai_chat'},
        ],
      },
    );
  }

  Future<void> deleteSiteChannelManualModel(
      int siteId, int channelId, String modelName) async {
    await _api.post(
      '/api/v1/site-channel/$siteId/account/$channelId/manual-models/delete',
      body: {'group_key': '', 'model_name': modelName},
    );
  }

  List<SiteChannelCard> _parseSiteChannelCards(dynamic value, {int siteId = 0}) {
    final list = parseJsonMapList(value);
    final cards = <SiteChannelCard>[];
    for (final item in list) {
      final groups = parseJsonMapList(item['groups']);
      if (groups.isEmpty) {
        cards.add(SiteChannelCard.fromJson({...item, if (siteId > 0) 'site_id': siteId}));
        continue;
      }
      for (final group in groups) {
        final models = parseJsonMapList(group['models']);
        if (models.isEmpty) {
          cards.add(SiteChannelCard.fromJson({
            ...item,
            ...group,
            if (siteId > 0) 'site_id': siteId,
            'account_id': item['account_id'] ?? item['id'],
            'channel_id': item['account_id'] ?? item['id'],
            'channel_name': item['channel_name'] ?? item['name'],
            'group_name': group['group_name'] ?? group['name'] ?? group['group_key'],
          }));
        } else {
          for (final model in models) {
            cards.add(SiteChannelCard.fromJson({
              ...item,
              ...group,
              ...model,
              if (siteId > 0) 'site_id': siteId,
              'account_id': item['account_id'] ?? item['id'],
              'channel_id': item['account_id'] ?? item['id'],
              'channel_name': item['channel_name'] ?? item['name'],
              'group_name': group['group_name'] ?? group['name'] ?? group['group_key'],
            }));
          }
        }
      }
    }
    return cards;
  }

  List<SiteChannelModel> _parseSiteChannelModels(dynamic value, {int channelId = 0}) {
    final list = parseJsonMapList(value);
    final models = <SiteChannelModel>[];
    for (final item in list) {
      final nested = parseJsonMapList(item['models']);
      if (nested.isEmpty) {
        models.add(SiteChannelModel.fromJson({
          ...item,
          if (channelId > 0) 'channel_id': item['channel_id'] ?? channelId,
        }));
      } else {
        for (final model in nested) {
          models.add(SiteChannelModel.fromJson({
            ...model,
            if (channelId > 0) 'channel_id': model['channel_id'] ?? channelId,
          }));
        }
      }
    }
    return models;
  }

  // ====== Announcement ======
  Future<List<Map<String, dynamic>>> getAnnouncements({int? siteId}) async {
    final res = await _api.get(
      siteId == null
          ? '/api/v1/announcement/list'
          : '/api/v1/announcement/list/$siteId',
    );
    return parseJsonMapList(res['data']);
  }

  Future<void> refreshAnnouncements(int siteId) async {
    await _api.post('/api/v1/announcement/refresh/$siteId');
  }

  Future<void> refreshAllAnnouncements() async {
    await _api.post('/api/v1/announcement/refresh-all');
  }

  // ====== Notification ======
  Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int pageSize = 50,
    bool? unread,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (unread != null) 'unread': '$unread',
    };
    final res = await _api.get('/api/v1/notification/list', query: query);
    return parseJsonMapList(res['data']);
  }

  Future<int> getUnreadNotificationCount() async {
    final res = await _api.get('/api/v1/notification/unread-count');
    final data = parseJsonMap(res['data']);
    return parseInt(data?['count'] ?? res['data']);
  }

  Future<void> markNotificationRead(int id, {bool read = true}) async {
    await _api.post(
      read
          ? '/api/v1/notification/read/$id'
          : '/api/v1/notification/unread/$id',
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _api.post('/api/v1/notification/read-all');
  }

  // ====== Usage History ======
  Future<List<Map<String, dynamic>>> getUsageHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _api.get(
      '/api/v1/usage-history',
      query: {'page': '$page', 'page_size': '$pageSize'},
    );
    return parseJsonMapList(res['data']);
  }

  Future<Map<String, dynamic>> getUsageHistorySummary() async {
    final res = await _api.get('/api/v1/usage-history/summary');
    return parseJsonMap(res['data']) ?? {};
  }

  Future<List<Map<String, dynamic>>> getHourlyUsageHistory() async {
    final res = await _api.get('/api/v1/usage-history/hourly');
    return parseJsonMapList(res['data']);
  }

  Future<List<Map<String, dynamic>>> getUsageHistoryModels(int siteId) async {
    final res = await _api.get('/api/v1/usage-history/models/$siteId');
    return parseJsonMapList(res['data']);
  }

  Future<void> syncUsageHistory(int siteId) async {
    await _api.post('/api/v1/usage-history/sync/$siteId');
  }

  Future<void> syncAllUsageHistory() async {
    await _api.post('/api/v1/usage-history/sync-all');
  }

  // ====== Report ======
  Future<List<Map<String, dynamic>>> getReportSchedules() async {
    final res = await _api.get('/api/v1/report/schedule/list');
    return parseJsonMapList(res['data']);
  }

  Future<Map<String, dynamic>> createReportSchedule(
    Map<String, dynamic> schedule,
  ) async {
    final res = await _api.post('/api/v1/report/schedule/create', body: schedule);
    return parseJsonMap(res['data']) ?? {};
  }

  Future<Map<String, dynamic>> updateReportSchedule(
    Map<String, dynamic> schedule,
  ) async {
    final res = await _api.post('/api/v1/report/schedule/update', body: schedule);
    return parseJsonMap(res['data']) ?? {};
  }

  Future<void> deleteReportSchedule(int id) async {
    await _api.delete('/api/v1/report/schedule/delete/$id');
  }

  Future<Map<String, dynamic>> testReportSchedule(
    Map<String, dynamic> schedule,
  ) async {
    final res = await _api.post('/api/v1/report/schedule/test', body: schedule);
    return parseJsonMap(res['data']) ?? {};
  }

  Future<List<Map<String, dynamic>>> getReportHistory() async {
    final res = await _api.get('/api/v1/report/history/list');
    return parseJsonMapList(res['data']);
  }

  Future<Map<String, dynamic>> getReportMetrics() async {
    final res = await _api.get('/api/v1/report/metrics');
    return parseJsonMap(res['data']) ?? {};
  }

  // ====== WebDAV Backup ======
  Future<Map<String, dynamic>> getWebDAVConfig() async {
    final res = await _api.get('/api/v1/backup/webdav/config');
    return parseJsonMap(res['data']) ?? {};
  }

  Future<void> setWebDAVConfig(Map<String, dynamic> config) async {
    await _api.post('/api/v1/backup/webdav/config', body: config);
  }

  Future<bool> testWebDAV() async {
    final res = await _api.post('/api/v1/backup/webdav/test');
    final data = parseJsonMap(res['data']) ?? {};
    return parseBool(data['success'] ?? data['ok']);
  }

  Future<void> triggerWebDAVBackup() async {
    await _api.post('/api/v1/backup/webdav/backup');
  }

  Future<List<Map<String, dynamic>>> listWebDAVBackups() async {
    final res = await _api.get('/api/v1/backup/webdav/list');
    return parseJsonMapList(res['data'])
        .map((e) => parseJsonMap(e) ?? <String, dynamic>{})
        .toList();
  }

  Future<void> restoreWebDAVBackup(String filename) async {
    await _api.post('/api/v1/backup/webdav/restore', body: {'filename': filename});
  }

  Future<void> deleteWebDAVBackup(String filename) async {
    await _api.delete('/api/v1/backup/webdav/delete', query: {'filename': filename});
  }

  // ====== WebAuthn ======
  Future<List<Map<String, dynamic>>> listWebAuthnCredentials() async {
    final res = await _api.get('/api/v1/webauthn/credentials');
    return parseJsonMapList(res['data'])
        .map((e) => parseJsonMap(e) ?? <String, dynamic>{})
        .toList();
  }

  Future<void> deleteWebAuthnCredential(String id) async {
    await _api.delete('/api/v1/webauthn/credentials/$id');
  }

  // ====== Update ======
  Future<String> getCurrentVersion() async {
    final res = await _api.get('/api/v1/update/now-version');
    return res['data']?.toString() ?? 'unknown';
  }

  Future<Map<String, dynamic>> checkUpdate() async {
    final res = await _api.get('/api/v1/update');
    return parseJsonMap(res['data']) ?? {};
  }

  Future<void> updateCore() async {
    await _api.post('/api/v1/update');
  }
}
