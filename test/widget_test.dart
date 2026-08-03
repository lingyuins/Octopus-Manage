import 'package:flutter_test/flutter_test.dart';
import 'package:octopusmanage/models/api_credential.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/models/group_probe.dart';
import 'package:octopusmanage/models/llm.dart';
import 'package:octopusmanage/models/model_mapping.dart';
import 'package:octopusmanage/models/proxy.dart';
import 'package:octopusmanage/models/setting.dart';
import 'package:octopusmanage/services/api_service.dart';
import 'package:octopusmanage/services/octopus_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiService extends ApiService {
  _FakeApiService({
    this.getResponse = const {},
    this.postResponse = const {'data': {}},
  });

  final Map<String, dynamic> getResponse;
  final dynamic postResponse;
  String? lastMethod;
  String? lastPath;
  Map<String, String>? lastQuery;
  dynamic lastBody;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = query;
    return getResponse;
  }

  @override
  Future<dynamic> post(String path, {dynamic body, String? contentType}) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    return postResponse;
  }

  @override
  Future<Map<String, dynamic>> put(String path, {dynamic body}) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastBody = body;
    return postResponse as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? query,
  }) async {
    lastMethod = 'DELETE';
    lastPath = path;
    lastQuery = query;
    return const {'data': {}};
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('APIKey', () {
    test('toJson includes apiKey when not empty', () {
      final key = APIKey(id: 1, name: 'test', apiKey: 'sk-abc');
      final json = key.toJson();
      expect(json['api_key'], 'sk-abc');
      expect(json['name'], 'test');
      expect(json['id'], 1);
    });

    test('fromJson handles nulls gracefully', () {
      final key = APIKey.fromJson({});
      expect(key.id, 0);
      expect(key.name, '');
      expect(key.enabled, true);
    });

    test('fromJson handles string and numeric primitives', () {
      final key = APIKey.fromJson({
        'id': '7',
        'name': 42,
        'api_key': 'sk-abc',
        'enabled': '0',
        'expire_at': '1735689600',
        'max_cost': '12.5',
        'supported_models': 'gpt-4o,claude-3',
      });

      expect(key.id, 7);
      expect(key.name, '42');
      expect(key.enabled, false);
      expect(key.expireAt, 1735689600);
      expect(key.maxCost, 12.5);
      expect(key.supportedModels, 'gpt-4o,claude-3');
    });
  });

  group('Channel', () {
    test('toJson includes id and keys', () {
      final ch = Channel(
        id: 5,
        name: 'test-ch',
        type: 1,
        enabled: true,
        keys: [ChannelKey(id: 1, channelId: 5, channelKey: 'key1')],
      );
      final json = ch.toJson();
      expect(json['id'], 5);
      expect(json['name'], 'test-ch');
      expect((json['keys'] as List).length, 1);
    });

    test('toJson omits id when 0', () {
      final ch = Channel(id: 0, name: 'new', type: 1, enabled: true);
      final json = ch.toJson();
      expect(json.containsKey('id'), false);
    });

    test('fromJson supports string numbers, booleans, and generic maps', () {
      final channel = Channel.fromJson({
        'id': '5',
        'name': 'primary',
        'type': '2',
        'enabled': 'false',
        'base_urls': [
          {'url': 'https://example.com', 'delay': '120'},
        ],
        'keys': [
          {
            'id': '2',
            'channel_id': '5',
            'enabled': 1,
            'channel_key': 'secret',
            'status_code': '200',
            'last_use_time_stamp': '123',
            'total_cost': '1.25',
            'remark': 'main',
          },
        ],
        'proxy': 1,
        'auto_sync': 'true',
        'auto_group': '1',
        'custom_header': [
          {'header_key': 'X-Test', 'header_value': 100},
        ],
        'stats': {
          'channel_id': '5',
          'input_token': '100',
          'output_token': 25.0,
          'input_cost': '1.5',
          'output_cost': 0.2,
          'wait_time': '9',
          'request_success': '8',
          'request_failed': '1',
        },
      });

      expect(channel.id, 5);
      expect(channel.type, 2);
      expect(channel.enabled, false);
      expect(channel.baseUrls.single.delay, 120);
      expect(channel.keys.single.enabled, true);
      expect(channel.keys.single.totalCost, 1.25);
      expect(channel.proxy, true);
      expect(channel.autoSync, true);
      expect(channel.autoGroup, 1);
      expect(channel.customHeader.single.headerValue, '100');
      expect(channel.stats?.inputToken, 100);
      expect(channel.stats?.outputCost, 0.2);
    });
  });

  group('Group', () {
    test('toJson includes items', () {
      final g = Group(
        id: 1,
        name: 'g1',
        mode: 2,
        items: [
          GroupItem(channelId: 3, modelName: 'gpt-4', priority: 1, weight: 2),
        ],
      );
      final json = g.toJson();
      expect(json['id'], 1);
      expect(json['mode'], 2);
      expect((json['items'] as List).length, 1);
      expect((json['items'][0] as Map)['channel_id'], 3);
    });
  });

  group('Group Probe', () {
    test('fromJson handles string booleans and arrays', () {
      final progress = GroupModelTestProgress.fromJson({
        'id': 88,
        'passed': 'true',
        'completed': '2',
        'total': 3,
        'done': 1,
        'results': [
          {
            'item_id': '1',
            'channel_id': '5',
            'channel_name': 'main',
            'model_name': 'gpt-4.1',
            'passed': 'false',
            'attempts': '2',
            'status_code': '500',
            'response_text': null,
            'message': 'boom',
          },
        ],
      });

      expect(progress.id, '88');
      expect(progress.passed, true);
      expect(progress.done, true);
      expect(progress.results.single.passed, false);
      expect(progress.results.single.statusCode, 500);
      expect(progress.results.single.responseText, '');
    });
  });

  group('LLMInfo', () {
    test('fromJson supports nested price map and string values', () {
      final model = LLMInfo.fromJson({
        'name': 'gpt-4o',
        'LLMPrice': {
          'input': '1.2',
          'output': '3.4',
          'cache_read': '0.1',
          'cache_write': 0.2,
        },
      });

      expect(model.name, 'gpt-4o');
      expect(model.input, 1.2);
      expect(model.output, 3.4);
      expect(model.cacheRead, 0.1);
      expect(model.cacheWrite, 0.2);
    });
  });

  group('Setting', () {
    test('toJson round-trips key and value', () {
      final s = Setting(key: 'proxy_url', value: 'http://proxy');
      final json = s.toJson();
      expect(json['key'], 'proxy_url');
      expect(json['value'], 'http://proxy');
    });
  });

  group('ApiService', () {
    test(
      'setBaseUrl normalizes url and clears token when server changes',
      () async {
        final service = ApiService();

        await service.setBaseUrl('https://first.example.com///');
        await service.setToken('secret-token');

        expect(service.baseUrl, 'https://first.example.com');
        expect(service.token, 'secret-token');

        await service.setBaseUrl(' https://second.example.com/path/ ');

        expect(service.baseUrl, 'https://second.example.com/path');
        expect(service.token, isEmpty);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_token'), isNull);
      },
    );
  });

  group('OctopusApi', () {
    test(
      'getModelChannels supports map payloads keyed by model name',
      () async {
        final api = OctopusApi(
          _FakeApiService(
            getResponse: {
              'data': {
                'gpt-4o': {
                  'enabled': '1',
                  'channel_id': '7',
                  'channel_name': 'Primary',
                },
              },
            },
          ),
        );

        final channels = await api.getModelChannels();

        expect(channels, hasLength(1));
        expect(channels.single.name, 'gpt-4o');
        expect(channels.single.enabled, true);
        expect(channels.single.channelId, 7);
        expect(channels.single.channelName, 'Primary');
      },
    );

    test('uses current backend paths for fixed management APIs', () async {
      final service = _FakeApiService(
        getResponse: {'data': []},
        postResponse: {'data': {}},
      );
      final api = OctopusApi(service);

      await api.getProxies();
      expect(service.lastMethod, 'GET');
      expect(service.lastPath, '/api/v1/proxy-pool/list');

      await api.updateProxy(const ProxyConfiguration(id: 3, name: 'p'));
      expect(service.lastMethod, 'POST');
      expect(service.lastPath, '/api/v1/proxy-pool/update');

      await api.deleteProxy(3);
      expect(service.lastMethod, 'DELETE');
      expect(service.lastPath, '/api/v1/proxy-pool/delete/3');

      await api.getCredentials();
      expect(service.lastMethod, 'GET');
      expect(service.lastPath, '/api/v1/api-credential/list');

      await api.updateCredential(
        const APICredentialProfile(id: 4, name: 'c'),
      );
      expect(service.lastMethod, 'POST');
      expect(service.lastPath, '/api/v1/api-credential/update');

      await api.getModelMappings();
      expect(service.lastMethod, 'GET');
      expect(service.lastPath, '/api/v1/model-mapping');

      await api.createModelMapping(const ModelMapping(name: 'm'));
      expect(service.lastMethod, 'POST');
      expect(service.lastPath, '/api/v1/model-mapping');
    });

    test('uses query delete paths for WebDAV backups', () async {
      final service = _FakeApiService();
      final api = OctopusApi(service);

      await api.deleteWebDAVBackup('backup.json');

      expect(service.lastMethod, 'DELETE');
      expect(service.lastPath, '/api/v1/backup/webdav/delete');
      expect(service.lastQuery, {'filename': 'backup.json'});
    });
  });
}
