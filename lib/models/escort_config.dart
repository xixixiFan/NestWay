import '../services/location_service.dart';

class EscortConfig {
  final String escortId;
  final String destination;
  final int estimatedMinutes;
  final LocationPoint startPoint;
  final List<Map<String, dynamic>> contacts;

  const EscortConfig({
    required this.escortId,
    required this.destination,
    required this.estimatedMinutes,
    required this.startPoint,
    required this.contacts,
  });
}
