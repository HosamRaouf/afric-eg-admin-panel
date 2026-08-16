import 'package:afric_eg_admin_panel/features/congress/domain/entities/venue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of `config/congress` — congress-level configuration.
class CongressConfig {
  final String? id;

  /// One real calendar date per congress day (index 0 = day 1). This is the
  /// source of truth for [totalDays], [congressStart] and [eventDate], so the
  /// app shows actual event dates instead of hard-coded "Day 1"/"Day 2".
  final List<DateTime> eventDates;

  /// The day number (1-based) the admin marks as currently under way.
  final int currentDay;

  final Venue venue;

  /// Download URL of the "Program at a Glance" PDF uploaded from the panel;
  /// empty when none is set. Shown as a widget on the app home screen.
  final String programGlanceUrl;

  const CongressConfig({
    this.id,
    required this.currentDay,
    this.eventDates = const [],
    this.venue = const Venue(name: '', address: '', mapsUrl: ''),
    this.programGlanceUrl = '',
  });

  /// First event date — the congress start used for countdowns.
  DateTime get congressStart => eventDates.isNotEmpty
      ? eventDates.first
      : DateTime.fromMillisecondsSinceEpoch(0);

  /// Total congress days, derived from the event date list.
  int get totalDays => eventDates.length;

  /// The calendar date of [day] (1-based); clamps to the last known date when
  /// [day] exceeds [totalDays].
  DateTime eventDate(int day) {
    if (eventDates.isEmpty) return congressStart;
    final index = (day - 1).clamp(0, eventDates.length - 1);
    return eventDates[index];
  }

  factory CongressConfig.fromJson(Map<String, dynamic> json, {String? id}) {
    var dates = <DateTime>[];
    final rawDates = json['eventDates'];
    if (rawDates is List) {
      dates = rawDates.map(_parseDate).toList();
    }
    if (dates.isEmpty) {
      // Legacy docs carry a single congressStart plus totalDays.
      final start = _parseDate(json['congressStart']);
      final total = (json['totalDays'] as num?)?.toInt() ?? 1;
      dates = List.generate(total, (i) => start.add(Duration(days: i)));
    }
    return CongressConfig(
      id: id ?? json['__id__'] as String?,
      eventDates: dates,
      currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
      venue: json['venue'] is Map
          ? Venue.fromJson(Map<String, dynamic>.from(json['venue']))
          : const Venue(name: '', address: '', mapsUrl: ''),
      programGlanceUrl: json['programGlanceUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'eventDates': eventDates.map(Timestamp.fromDate).toList(),
    'currentDay': currentDay,
    'venue': venue.toJson(),
    'programGlanceUrl': programGlanceUrl,
    if (eventDates.isNotEmpty)
      'congressStart': Timestamp.fromDate(eventDates.first),
  };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    final parsed = DateTime.tryParse(value as String? ?? '');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
