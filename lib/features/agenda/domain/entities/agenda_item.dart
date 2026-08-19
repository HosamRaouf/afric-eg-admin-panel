import 'package:cloud_firestore/cloud_firestore.dart';

import 'talk.dart';

/// Mirror of `agenda/{dayKey}/sessions/{sid}`.
///
/// The app's Freezed model uses a `type` discriminator
/// (`sessionBlock | breakBand | ceremony`); the admin panel keeps the same
/// documents but models them as one class with optional fields.
class AgendaItem {
  final String type; // sessionBlock | breakBand | ceremony
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final DateTime startTime;
  final DateTime endTime;
  final List<Talk> talks;
  final List<String> raisedHands;
  final bool isLive;

  AgendaItem({
    this.type = 'sessionBlock',
    required this.id,
    required this.title,
    this.subtitle = '',
    this.icon = '',
    DateTime? startTime,
    DateTime? endTime,
    this.talks = const [],
    this.raisedHands = const [],
    this.isLive = false,
  }) : startTime = startTime ?? DateTime(2026, 1, 1),
       endTime = endTime ?? DateTime(2026, 1, 1);

  bool get isSessionBlock => type == 'sessionBlock';

  factory AgendaItem.fromJson(Map<String, dynamic> json) => AgendaItem(
    type: json['type'] as String? ?? 'sessionBlock',
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    icon: json['icon'] as String? ?? '',
    startTime: _parseTime(json['startTime']),
    endTime: _parseTime(json['endTime']),
    talks:
        (json['talks'] as List?)
            ?.map((e) => Talk.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [],
    raisedHands: (json['raisedHands'] as List?)?.cast<String>() ?? const [],
    isLive: json['isLive'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'title': title,
    if (subtitle.isNotEmpty) 'subtitle': subtitle,
    if (icon.isNotEmpty) 'icon': icon,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'talks': talks.map((t) => t.toJson()).toList(),
    if (raisedHands.isNotEmpty) 'raisedHands': raisedHands,
    if (isLive) 'isLive': isLive,
  };

  /// Parses a stored `startTime`/`endTime`: Firestore `Timestamp` (current),
  /// a full date-time string, or a legacy clock string like `'9:30'`. Falls
  /// back to midnight so legacy documents remain editable and sortable.
  static DateTime _parseTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt;
      final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
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
}
