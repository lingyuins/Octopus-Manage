import 'package:flutter_test/flutter_test.dart';
import 'package:octopusmanage/models/api_key.dart';
import 'package:octopusmanage/models/group.dart';
import 'package:octopusmanage/models/channel.dart';
import 'package:octopusmanage/models/setting.dart';

void main() {
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

  group('Setting', () {
    test('toJson round-trips key and value', () {
      final s = Setting(key: 'proxy_url', value: 'http://proxy');
      final json = s.toJson();
      expect(json['key'], 'proxy_url');
      expect(json['value'], 'http://proxy');
    });
  });
}
