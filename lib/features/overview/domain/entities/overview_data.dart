import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Aggregated numbers and state shown on the overview dashboard.
class OverviewData {
  final CongressConfig? config;

  // Content
  final int announcementCount;
  final int sponsorCount;
  final int committeeCount;
  final int committeeCategoryCount;
  final int workshopCount;
  final int workshopSessionCount;
  final int agendaItemCount;
  final int agendaTrackCount;
  final int talkCount;
  final int speakerCount;

  // People (best-effort, sourced from the `listUsers` Cloud Function)
  final int userCount;
  final int attendeeCount;
  final int speakerUserCount;
  final int facultyCount;
  final int sponsorUserCount;
  final int adminCount;

  // Live
  final int liveQuestionCount;
  final int liveRaisedHands;
  final List<LiveTalkSummary> liveTalks;

  const OverviewData({
    this.config,
    this.announcementCount = 0,
    this.sponsorCount = 0,
    this.committeeCount = 0,
    this.committeeCategoryCount = 0,
    this.workshopCount = 0,
    this.workshopSessionCount = 0,
    this.agendaItemCount = 0,
    this.agendaTrackCount = 0,
    this.talkCount = 0,
    this.speakerCount = 0,
    this.userCount = 0,
    this.attendeeCount = 0,
    this.speakerUserCount = 0,
    this.facultyCount = 0,
    this.sponsorUserCount = 0,
    this.adminCount = 0,
    this.liveQuestionCount = 0,
    this.liveRaisedHands = 0,
    this.liveTalks = const [],
  });

  int get liveTalkCount => liveTalks.length;
}

/// A talk that is on air right now, read from the `live_now/{talkId}` mirror
/// docs written by the admin panel and the speaker room.
class LiveTalkSummary {
  final String talkId;
  final String talkTitle;
  final String sessionTitle;
  final String hall;
  final List<String> speakers;
  final DateTime startTime;
  final DateTime endTime;

  const LiveTalkSummary({
    required this.talkId,
    required this.talkTitle,
    required this.sessionTitle,
    required this.hall,
    this.speakers = const [],
    required this.startTime,
    required this.endTime,
  });

  factory LiveTalkSummary.fromJson(Map<String, dynamic> json) {
    final start = json['startTime'];
    final end = json['endTime'];
    return LiveTalkSummary(
      talkId: json['talkId'] as String? ?? '',
      talkTitle: json['talkTitle'] as String? ?? '',
      sessionTitle: json['sessionTitle'] as String? ?? '',
      hall: json['hall'] as String? ?? '',
      speakers: (json['speakers'] as List?)?.cast<String>() ?? const [],
      startTime: start is Timestamp
          ? start.toDate()
          : (DateTime.tryParse(start as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0)),
      endTime: end is Timestamp
          ? end.toDate()
          : (DateTime.tryParse(end as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0)),
    );
  }
}
