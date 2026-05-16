import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/services/location_service.dart';

void main() {
  group('LocationPoint', () {
    test('toJson should return correct map', () {
      final point = LocationPoint(
        latitude: 31.2304,
        longitude: 121.4737,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        address: '上海',
      );

      final json = point.toJson();

      expect(json['latitude'], 31.2304);
      expect(json['longitude'], 121.4737);
      expect(json['address'], '上海');
    });

    test('toString should return readable format', () {
      final point = LocationPoint(
        latitude: 31.2304,
        longitude: 121.4737,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final str = point.toString();

      expect(str, contains('lat: 31.2304'));
      expect(str, contains('lng: 121.4737'));
    });
  });

  group('EscortLocationService', () {
    late EscortLocationService service;

    setUp(() {
      service = EscortLocationService();
      service.reset();
    });

    test('singleton pattern should return same instance', () {
      final instance1 = EscortLocationService();
      final instance2 = EscortLocationService();

      expect(identical(instance1, instance2), isTrue);
    });

    test('initial state should be not tracking', () {
      expect(service.isTracking, isFalse);
      expect(service.startPoint, isNull);
      expect(service.lastKnownLocation, isNull);
      expect(service.trackHistory, isEmpty);
    });

    test('reset should clear all data', () async {
      await service.startTracking();
      await service.recordCurrentPosition();

      expect(service.trackHistory.isNotEmpty, isTrue);

      service.reset();

      expect(service.isTracking, isFalse);
      expect(service.startPoint, isNull);
      expect(service.lastKnownLocation, isNull);
      expect(service.trackHistory, isEmpty);
    });

    test('startTracking should set isTracking to true', () async {
      expect(service.isTracking, isFalse);

      await service.startTracking();

      expect(service.isTracking, isTrue);
    });

    test('stopTracking should set isTracking to false', () async {
      await service.startTracking();
      expect(service.isTracking, isTrue);

      service.stopTracking();

      expect(service.isTracking, isFalse);
    });

    test('recordCurrentPosition should return null when not tracking', () async {
      final result = await service.recordCurrentPosition();
      expect(result, isNull);
    });

    test('reportLocationToServer should return true', () async {
      final result = await service.reportLocationToServer(
        escortId: 'test_123',
        lat: 31.2304,
        lng: 121.4737,
      );
      expect(result, isTrue);
    });

    test('reportEscortStart should return true', () async {
      final startPoint = LocationPoint(
        latitude: 31.2304,
        longitude: 121.4737,
        timestamp: DateTime.now(),
      );

      final result = await service.reportEscortStart(
        escortId: 'test_123',
        destination: '外滩',
        estimatedMinutes: 30,
        startPoint: startPoint,
      );

      expect(result, isTrue);
    });

    test('reportEscortEnd should return true', () async {
      final endPoint = LocationPoint(
        latitude: 31.2404,
        longitude: 121.4837,
        timestamp: DateTime.now(),
      );

      final result = await service.reportEscortEnd(
        escortId: 'test_123',
        endType: 'safe_arrival',
        endPoint: endPoint,
      );

      expect(result, isTrue);
    });

    test('reportTimeoutAlert should return true', () async {
      final lastLocation = LocationPoint(
        latitude: 31.2304,
        longitude: 121.4737,
        timestamp: DateTime.now(),
      );

      final result = await service.reportTimeoutAlert(
        escortId: 'test_123',
        lastLocation: lastLocation,
        emergencyContacts: ['张三', '李四'],
      );

      expect(result, isTrue);
    });
  });
}
