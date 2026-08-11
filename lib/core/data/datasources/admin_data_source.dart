import 'package:afric_eg_admin_panel/core/services/firestore_service.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/entities/announcement.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/hand_raise.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore read/write layer for the admin panel.
///
/// Mirrors the AFRIC 2026 schema documented in
/// lib/core/services/firestore_service.dart:
///
///   config/congress
///   announcements
///   agenda/{dayKey}
///   agenda/{dayKey}/sessions/{sid}
///   agenda/{dayKey}/sessions/{sid}/live_room/{qid}
///   workshops/{id}
///   workshops/{id}/sessions/{sid}
///   admins/{uid}                     — admin panel membership registry
class AdminDataSource {
  AdminDataSource({FirestoreService? firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService? _firestoreService;

  static const _configPath = 'config/congress';

  FirestoreService get _service => _firestoreService ?? FirestoreService();

  // ─────────────────────────── Config ───────────────────────────

  Future<CongressConfig?> getConfig() async {
    final doc = await _service.readDoc(_configPath);
    if (doc == null) return null;
    return CongressConfig.fromJson(doc, id: _configPath);
  }

  Future<void> updateConfig(CongressConfig config) async {
    await _service.setDoc(
      _configPath,
      config.toJson(),
      SetOptions(merge: true),
    );
  }

  /// All session blocks across every agenda day/hall, used to pick the live
  /// session. Returns `(dayKey, item)` pairs.
  Future<List<(AgendaDay, AgendaItem)>> listSessionBlocks() async {
    final result = <(AgendaDay, AgendaItem)>[];
    for (final day in await getAgendaDays()) {
      for (final item in await getAgendaItems(day.key)) {
        if (item.isSessionBlock) result.add((day, item));
      }
    }
    result.sort((a, b) {
      final dayCmp = a.$1.day.compareTo(b.$1.day);
      if (dayCmp != 0) return dayCmp;
      return a.$2.startTime.compareTo(b.$2.startTime);
    });
    return result;
  }

  // ─────────────────────────── Announcements ───────────────────────────

  Future<List<Announcement>> getAnnouncements() async {
    final docs = await _service.readCollection('announcements');
    return docs
        .map((d) => Announcement.fromJson(d, id: d['__id__'] as String))
        .toList();
  }

  Future<void> addAnnouncement(Announcement a) async {
    await _service.setDoc('announcements/${a.id}', a.toJson());
  }

  Future<void> updateAnnouncement(Announcement a) async {
    await _service.updateDoc('announcements/${a.id}', a.toJson());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _service.deleteDoc('announcements/$id');
  }

  // ─────────────────────────── Agenda ───────────────────────────

  Future<List<AgendaDay>> getAgendaDays() async {
    final docs = await _service.readCollection('agenda');
    return docs.map((d) => AgendaDay.fromKey(d['__id__'] as String)).toList();
  }

  Future<List<AgendaItem>> getAgendaItems(String dayKey) async {
    final docs = await _service.readCollection('agenda/$dayKey/sessions');
    final items = docs.map(AgendaItem.fromJson).toList();
    items.sort((a, b) => _startMinutes(a).compareTo(_startMinutes(b)));
    return items;
  }

  static int _startMinutes(AgendaItem item) =>
      item.startTime.hour * 60 + item.startTime.minute;

  Future<void> addAgendaItem(String dayKey, AgendaItem item) async {
    await _service.setDoc('agenda/$dayKey/sessions/${item.id}', item.toJson());
  }

  Future<void> updateAgendaItem(String dayKey, AgendaItem item) async {
    await _service.updateDoc(
      'agenda/$dayKey/sessions/${item.id}',
      item.toJson(),
    );
  }

  Future<void> deleteAgendaItem(String dayKey, String id) async {
    await _service.deleteDoc('agenda/$dayKey/sessions/$id');
  }

  // ─────────────────────────── Speaker talk index ───────────────────────────

  /// Writes (or replaces) the mirror of [talk] under one speaker's
  /// `users/{uid}/talks/{talkId}` subcollection. The document id is the talk
  /// id, so editing a talk updates the same doc in place. [sessionId]/[dayKey]
  /// let the app link back to the originating session.
  Future<void> setSpeakerTalk(
    String uid,
    Talk talk, {
    String dayKey = '',
    String sessionId = '',
  }) async {
    final doc = talk.toJson()
      ..['dayKey'] = dayKey
      ..['sessionId'] = sessionId;
    await _service.setDoc('users/$uid/talks/${talk.id}', doc);
  }

  Future<void> deleteSpeakerTalk(String uid, String talkId) async {
    await _service.deleteDoc('users/$uid/talks/$talkId');
  }

  /// Marks a talk as the live talk for its session — the app's live room is
  /// talk-scoped and resolves it purely from `talks[].status == 'live'`.
  ///
  /// Only the talks array is written: the session's `isLive` flag and
  /// `config/congress.liveSessionId` are deliberately left untouched so they
  /// can never become a second, stale source of truth. Marking a talk live
  /// clears the live flag from every other talk in the session.
  Future<void> setTalkLive(
    String dayKey,
    String sessionId,
    String talkId,
    bool isLive,
  ) async {
    final path = 'agenda/$dayKey/sessions/$sessionId';
    final doc = await _service.readDoc(path);
    if (doc == null) return;
    final talks = (doc['talks'] as List?) ?? const [];
    final updated = talks.map((t) {
      final map = Map<String, dynamic>.from(t as Map);
      if (map['id'] == talkId) {
        map['status'] = isLive ? 'live' : 'upcoming';
      } else if (isLive && map['status'] == 'live') {
        map['status'] = 'upcoming';
      }
      return map;
    }).toList();
    await _service.updateDoc(path, {'talks': updated});
  }

  // ─────────────────────────── Live Room ───────────────────────────

  /// Locates a session's document path by scanning the agenda day keys.
  Future<String?> findSessionPath(String sessionId) async {
    for (final day in await getAgendaDays()) {
      final sessions = await _service.readCollection(
        'agenda/${day.key}/sessions',
      );
      for (final s in sessions) {
        if (s['id'] == sessionId) {
          return 'agenda/${day.key}/sessions/$sessionId';
        }
      }
    }
    return null;
  }

  /// Locates the configured live session path via `config/congress.liveSessionId`.
  Future<String?> _liveSessionPath() async {
    final config = await getConfig();
    if (config == null || config.liveSessionId.isEmpty) return null;
    return findSessionPath(config.liveSessionId);
  }

  /// Details of the current live session (or null when none configured).
  /// Returns `{'path': path, ...doc}` so callers can resolve subcollections.
  Future<Map<String, dynamic>?> getLiveSessionDetails() async {
    final path = await _liveSessionPath();
    if (path == null) return null;
    final doc = await _service.readDoc(path);
    if (doc == null) return null;
    return {'path': path, ...doc};
  }

  /// Details of a specific session room. Returns `{'path': path, ...doc}`.
  Future<Map<String, dynamic>?> getSessionDetails(String path) async {
    final doc = await _service.readDoc(path);
    if (doc == null) return null;
    return {'path': path, ...doc};
  }

  /// Streams the Q&A questions of a room in real time.
  Stream<List<Question>> watchLiveQuestions(String path) {
    return _service
        .streamCollection('$path/live_room')
        .map(
          (docs) => docs
              .map((d) => Question.fromJson(d, id: d['__id__'] as String))
              .toList(),
        );
  }

  /// Streams the raised-hands queue of a room in real time, oldest first.
  Stream<List<HandRaise>> watchHandRaises(String path) {
    return _service.streamCollection('$path/hand_raises').map((docs) {
      final hands = docs
          .map((d) => HandRaise.fromJson(d, id: d['__id__'] as String))
          .toList();
      hands.sort((a, b) => a.raisedAt.compareTo(b.raisedAt));
      return hands;
    });
  }

  Future<List<Question>> getLiveQuestions(String path) async {
    final docs = await _service.readCollection('$path/live_room');
    return docs
        .map((d) => Question.fromJson(d, id: d['__id__'] as String))
        .toList();
  }

  Future<List<HandRaise>> getHandRaises(String path) async {
    final docs = await _service.readCollection('$path/hand_raises');
    final hands = docs
        .map((d) => HandRaise.fromJson(d, id: d['__id__'] as String))
        .toList();
    hands.sort((a, b) => a.raisedAt.compareTo(b.raisedAt));
    return hands;
  }

  Future<void> updateLiveQuestion(String path, Question q) async {
    final doc = Map<String, dynamic>.from(q.toJson())..remove('createdAt');
    if (q.answer == null) {
      doc['answer'] = FieldValue.delete();
      doc['answeredBy'] = FieldValue.delete();
    }
    await _service.updateDoc('$path/live_room/${q.id}', doc);
  }

  Future<void> deleteLiveQuestion(String path, String id) async {
    await _service.deleteDoc('$path/live_room/$id');
  }

  /// Puts down a single attendee from the mic queue.
  Future<void> lowerHand(String path, String uid) async {
    await _service.deleteDoc('$path/hand_raises/$uid');
  }

  /// Clears every raised hand in the room's queue.
  Future<void> clearRaisedHands(String path) async {
    final docs = await _service.readCollection('$path/hand_raises');
    for (final d in docs) {
      await _service.deleteDoc('$path/hand_raises/${d['__id__']}');
    }
  }

  // ─────────────────────────── Workshops ───────────────────────────

  Future<List<Workshop>> getWorkshops() async {
    final docs = await _service.readCollection('workshops');
    return docs
        .map((d) => Workshop.fromJson(d, id: d['__id__'] as String))
        .toList();
  }

  Future<void> addWorkshop(Workshop w) async {
    await _service.setDoc('workshops/${w.id}', w.toJson());
  }

  Future<void> updateWorkshop(Workshop w) async {
    await _service.updateDoc('workshops/${w.id}', w.toJson());
  }

  Future<void> deleteWorkshop(String id) async {
    await _service.deleteDoc('workshops/$id');
  }

  Future<List<WorkshopSession>> getWorkshopSessions(String workshopId) async {
    final docs = await _service.readCollection(
      'workshops/$workshopId/sessions',
    );
    final sessions = docs
        .map((d) => WorkshopSession.fromJson(d, id: d['__id__'] as String))
        .toList();
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  Future<void> addWorkshopSession(String workshopId, WorkshopSession s) async {
    await _service.setDoc('workshops/$workshopId/sessions/${s.id}', s.toJson());
  }

  Future<void> updateWorkshopSession(
    String workshopId,
    WorkshopSession s,
  ) async {
    await _service.updateDoc(
      'workshops/$workshopId/sessions/${s.id}',
      s.toJson(),
    );
  }

  Future<void> deleteWorkshopSession(String workshopId, String id) async {
    await _service.deleteDoc('workshops/$workshopId/sessions/$id');
  }
}
