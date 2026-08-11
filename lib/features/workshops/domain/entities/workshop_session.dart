import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of `workshops/{id}/sessions/{sid}`.
class WorkshopSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String topic;
  final String speaker;
  final bool isBreak;
  final String? dayLabel;

  const WorkshopSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.topic,
    required this.speaker,
    this.isBreak = false,
    this.dayLabel,
  });

  factory WorkshopSession.fromJson(Map<String, dynamic> json, {String? id}) {
    final docId = id ?? json['id'] as String? ?? json['__id__'] as String;

    DateTime parseTime(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) {
        // Handle "HH:mm" or "HH:mm - HH:mm" legacy formats
        final parts = value.split('-');
        final timePart = parts[0].trim();
        try {
          final timeParts = timePart.split(':');
          if (timeParts.length == 2) {
            final now = DateTime.now();
            return DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        } catch (_) {}
      }
      return fallback;
    }

    // For end time in legacy string "HH:mm - HH:mm"
    DateTime parseEndTime(dynamic value, DateTime startFallback) {
      if (value is Timestamp) return value.toDate();
      if (value is String && value.contains('-')) {
        final parts = value.split('-');
        if (parts.length > 1) {
          final timePart = parts[1].trim();
          try {
            final timeParts = timePart.split(':');
            if (timeParts.length == 2) {
              final now = DateTime.now();
              return DateTime(
                now.year,
                now.month,
                now.day,
                int.parse(timeParts[0]),
                int.parse(timeParts[1]),
              );
            }
          } catch (_) {}
        }
      }
      return startFallback.add(const Duration(hours: 1));
    }

    final start = parseTime(json['startTime'] ?? json['time'], DateTime.now());
    final end = parseEndTime(json['endTime'] ?? json['time'], start);

    return WorkshopSession(
      id: docId,
      startTime: start,
      endTime: end,
      topic: json['topic'] as String? ?? '',
      speaker: json['speaker'] as String? ?? '',
      isBreak: json['isBreak'] as bool? ?? false,
      dayLabel: json['dayLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'topic': topic,
        'speaker': speaker,
        'isBreak': isBreak,
        if (dayLabel != null) 'dayLabel': dayLabel,
      };
}
