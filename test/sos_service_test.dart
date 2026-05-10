import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/services/sos_service.dart';
import 'package:solotrip/mock/mock_sos_logs.dart';
import 'package:solotrip/mock/mock_contacts.dart';

void main() {
  group('SosService Unit Tests', () {
    late SosService sosService;

    setUp(() {
      sosService = SosService();
    });

    test('SosService should be a singleton', () {
      final instance1 = SosService();
      final instance2 = SosService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('generateLocationShareUrl should generate correct URL', () {
      final url = sosService.generateLocationShareUrl(
        22.5431,
        114.0579,
        '深圳世界之窗',
      );
      expect(url, contains('https://uri.amap.com/marker'));
      expect(url, contains('position=114.0579,22.5431'));
      expect(url, contains('name='));
    });

    test('generateLocationShareUrl with null description should use default', () {
      final url = sosService.generateLocationShareUrl(22.5431, 114.0579, null);
      expect(url, contains('name='));
      expect(url, contains('%E6%88%91%E7%9A%84%E4%BD%8D%E7%BD%AE'));
    });

    test('reportSosEvent should return true', () async {
      final result = await sosService.reportSosEvent(
        type: 'sos',
        locationDescription: 'Test Location',
        latitude: 22.5431,
        longitude: 114.0579,
      );
      expect(result, isTrue);
    });

    test('reportSosEvent should return true even without location', () async {
      final result = await sosService.reportSosEvent(
        type: 'sos',
        locationDescription: null,
        latitude: null,
        longitude: null,
      );
      expect(result, isTrue);
    });

    test('getSosHistory should return mock data', () async {
      final history = await sosService.getSosHistory();
      expect(history, isNotNull);
      expect(history, equals(mockSosLogs));
      expect(history.length, equals(3));
    });

    test('getEmergencyContacts should return mock contacts', () {
      final contacts = sosService.getEmergencyContacts();
      expect(contacts, isNotNull);
      expect(contacts, equals(mockContacts));
      expect(contacts.length, equals(3));
    });

    test('getEmergencyContacts should have correct contact data', () {
      final contacts = sosService.getEmergencyContacts();
      expect(contacts[0]['name'], equals('妈妈'));
      expect(contacts[0]['phone'], equals('13900000001'));
      expect(contacts[1]['name'], equals('爸爸'));
      expect(contacts[2]['name'], equals('室友'));
    });

    test('getSosHistory should have correct data structure', () async {
      final history = await sosService.getSosHistory();

      for (final item in history) {
        expect(item.containsKey('id'), isTrue);
        expect(item.containsKey('user_id'), isTrue);
        expect(item.containsKey('type'), isTrue);
        expect(item.containsKey('triggered_at'), isTrue);
        expect(item.containsKey('location_description'), isTrue);
      }

      expect(history[0]['type'], equals('call'));
      expect(history[1]['type'], equals('sms'));
      expect(history[2]['type'], equals('video'));
    });
  });
}
