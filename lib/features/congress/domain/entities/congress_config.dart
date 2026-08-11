import 'package:afric_eg_admin_panel/features/congress/domain/entities/venue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of `config/congress` — congress-level configuration.
class CongressConfig {
  final String? id;
  final DateTime congressStart;
  final int currentDay;
  final String liveSessionId;
  final Venue venue;

  const CongressConfig({
    this.id,
    required this.congressStart,
    required this.currentDay,
    required this.liveSessionId,
    this.venue = const Venue(name: '', address: '', mapsUrl: ''),
  });

  factory CongressConfig.fromJson(Map<String, dynamic> json, {String? id}) {
    final start = json['congressStart'];
    return CongressConfig(
      id: id ?? json['__id__'] as String?,
      congressStart: start is Timestamp
          ? start.toDate()
          : (DateTime.tryParse(start as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0)),
      currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
      liveSessionId: json['liveSessionId'] as String? ?? '',
      venue: json['venue'] is Map
          ? Venue.fromJson(Map<String, dynamic>.from(json['venue']))
          : const Venue(name: '', address: '', mapsUrl: ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'congressStart': Timestamp.fromDate(congressStart),
        'currentDay': currentDay,
        'liveSessionId': liveSessionId,
        'venue': venue.toJson(),
      };
}
