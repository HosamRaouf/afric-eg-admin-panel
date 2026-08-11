import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';

/// A live chat room — one agenda session block that can be moderated.
///
/// The room lives at `agenda/{dayKey}/sessions/{id}`; each talk carries its
/// own live-room Q&A (`.../talks/{talkId}/live_room`) and mic queue
/// (`.../talks/{talkId}/hand_raises`). A room is live when at least one of
/// its talks has `status == 'live'`.
class Room {
  final String id;
  final String dayKey;
  final int day;
  final String hall;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final List<Talk> talks;

  Room({
    required this.id,
    required this.dayKey,
    required this.day,
    required this.hall,
    required this.title,
    DateTime? startTime,
    DateTime? endTime,
    this.talks = const [],
  })  : startTime = startTime ?? DateTime(2026, 1, 1),
        endTime = endTime ?? DateTime(2026, 1, 1);

  /// A room is live while any of its talks is flagged live.
  bool get isLive => talks.any((t) => t.status == 'live');

  String get path => 'agenda/$dayKey/sessions/$id';
}
