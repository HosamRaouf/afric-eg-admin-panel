import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of a single `talk` inside an agenda `SessionBlock`.
class Talk {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> speakers;
  final String title;
  final String role;
  final String hall;
  final String status; // live | upcoming | completed
  final String? sponsoredBy;

  Talk({
    required this.id,
    required this.title,
    this.speakers = const [],
    required this.role,
    required this.hall,
    DateTime? startTime,
    DateTime? endTime,
    this.status = 'upcoming',
    this.sponsoredBy,
  })  : startTime = startTime ?? DateTime(2026, 1, 1),
        endTime = endTime ?? DateTime(2026, 1, 1);

  factory Talk.fromJson(Map<String, dynamic> json) => Talk(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        speakers: _parseSpeakers(json['speakers'], json['speaker']),
        role: json['role'] as String? ?? '',
        hall: json['hall'] as String? ?? '',
        startTime: _parseTime(json['startTime'] ?? json['time']),
        endTime: _parseTime(json['endTime'] ?? json['time']),
        status: json['status'] as String? ?? 'upcoming',
        sponsoredBy: json['sponsoredBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'speakers': speakers,
        'title': title,
        'role': role,
        'hall': hall,
        'status': status,
        if (sponsoredBy != null && sponsoredBy!.isNotEmpty)
          'sponsoredBy': sponsoredBy,
      };

  /// Parses the stored `speakers`: a `speakers` list (current), or a legacy
  /// single `speaker` string which may itself hold comma-separated names.
  static List<String> _parseSpeakers(dynamic speakers, dynamic legacy) {
    if (speakers is List) {
      return speakers
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (legacy is String && legacy.trim().isNotEmpty) {
      return legacy
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Parses a stored `startTime`/`endTime`: Firestore `Timestamp` (current),
  /// a full date-time string, or a legacy clock string like `'9:30'`. When
  /// given a legacy combined range like `'9:30 – 10:00'`, the first value is
  /// used for both fields so the talk remains editable.
  static DateTime _parseTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      final first = value.split(RegExp(r'[\u2013\u2014\-–]')).first.trim();
      final dt = DateTime.tryParse(first);
      if (dt != null) return dt;
      final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(first);
      if (match != null) {
        return DateTime(
          2026,
          1,
          1,
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
        );
      }
    }
    return DateTime(2026, 1, 1);
  }

  Talk copyWith({
    DateTime? startTime,
    DateTime? endTime,
    List<String>? speakers,
    String? title,
    String? role,
    String? hall,
    String? status,
    String? sponsoredBy,
  }) =>
      Talk(
        id: id,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        speakers: speakers ?? this.speakers,
        title: title ?? this.title,
        role: role ?? this.role,
        hall: hall ?? this.hall,
        status: status ?? this.status,
        sponsoredBy: sponsoredBy ?? this.sponsoredBy,
      );
}
