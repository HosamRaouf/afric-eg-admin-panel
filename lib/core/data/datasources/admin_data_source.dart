import 'dart:async';

import 'package:afric_eg_admin_panel/core/services/firestore_service.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/entities/announcement.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_category.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_member.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/hand_raise.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:afric_eg_admin_panel/features/sponsors/domain/entities/sponsor.dart';
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
    final previous = await getConfig();
    await _service.setDoc(
      _configPath,
      config.toJson(),
      SetOptions(merge: true),
    );
    await _reconcileAgendaDays(previous, config);
  }

  /// Keeps the `agenda` collection in sync with the congress config, which is
  /// the source of truth for which days exist:
  ///
  ///   * every configured day gets its Hall A and Hall B track docs
  ///     (`day{N}_hall_a` / `day{N}_hall_b`), and
  ///   * days dropped from the config have all their track docs — and the
  ///     sessions beneath them — removed.
  Future<void> _reconcileAgendaDays(
    CongressConfig? previous,
    CongressConfig next,
  ) async {
    final existing = await getAgendaDays();
    final nextDayNumbers = {
      for (var day = 1; day <= next.eventDates.length; day++) day,
    };

    for (final day in nextDayNumbers) {
      for (final hall in ['a', 'b']) {
        final key = 'day${day}_hall_$hall';
        if (existing.any((d) => d.key == key)) continue;
        await _service.setDoc('agenda/$key', {
          'createdAt': Timestamp.now(),
          'title': 'Day $day — Hall ${hall.toUpperCase()}',
        });
      }
    }

    final previousDayNumbers = previous == null
        ? <int>{}
        : {for (var day = 1; day <= previous.eventDates.length; day++) day};
    final removedDays = previousDayNumbers.difference(nextDayNumbers);
    for (final day in removedDays) {
      for (final track in existing.where((d) => d.day == day)) {
        await _deleteAgendaDay(track.key);
      }
    }
  }

  /// Removes a day/track document and every session beneath it.
  Future<void> _deleteAgendaDay(String dayKey) async {
    final sessions = await _service.readCollection('agenda/$dayKey/sessions');
    for (final s in sessions) {
      await _service.deleteDoc('agenda/$dayKey/sessions/${s['__id__']}');
    }
    await _service.deleteDoc('agenda/$dayKey');
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

  /// Real-time equivalent of [listSessionBlocks]: emits a fresh list of
  /// session blocks whenever any agenda day or session document changes, so
  /// screens that consume it (e.g. Live Rooms) follow the data without a
  /// manual refresh. Emits on subscription (once day/session snapshots have
  /// been read).
  Stream<List<(AgendaDay, AgendaItem)>> watchSessionBlocks() async* {
    final controller =
        StreamController<List<(AgendaDay, AgendaItem)>>.broadcast();
    final subscriptions = <StreamSubscription>[];
    final sessionsByDay = <String, List<Map<String, dynamic>>>{};

    void emit() {
      if (controller.isClosed) return;
      final result = <(AgendaDay, AgendaItem)>[];
      for (final entry in sessionsByDay.entries) {
        final day = AgendaDay.fromKey(entry.key);
        for (final doc in entry.value) {
          final item = AgendaItem.fromJson(doc);
          if (item.isSessionBlock) result.add((day, item));
        }
      }
      result.sort((a, b) {
        final dayCmp = a.$1.day.compareTo(b.$1.day);
        if (dayCmp != 0) return dayCmp;
        return a.$2.startTime.compareTo(b.$2.startTime);
      });
      controller.add(result);
    }

    subscriptions.add(
      _service.streamCollection('agenda').listen((days) {
        final keys = days.map((d) => d['__id__'] as String).toSet();
        for (final key in keys) {
          if (sessionsByDay.containsKey(key)) continue;
          sessionsByDay[key] = const <Map<String, dynamic>>[];
          subscriptions.add(
            _service.streamCollection('agenda/$key/sessions').listen((docs) {
              if (!sessionsByDay.containsKey(key)) return;
              sessionsByDay[key] = docs;
              emit();
            }),
          );
        }
        for (final key in sessionsByDay.keys.toList()) {
          if (!keys.contains(key)) sessionsByDay.remove(key);
        }
        emit();
      }),
    );

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    yield* controller.stream;
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

  // ─────────────────────────── Sponsors ───────────────────────────

  Future<List<Sponsor>> getSponsors() async {
    final docs = await _service.readCollection('sponsors');
    return docs
        .map((d) => Sponsor.fromJson(d, id: d['__id__'] as String))
        .toList();
  }

  Future<void> addSponsor(Sponsor s) async {
    await _service.setDoc('sponsors/${s.id}', s.toJson());
  }

  Future<void> updateSponsor(Sponsor s) async {
    await _service.updateDoc('sponsors/${s.id}', s.toJson());
  }

  Future<void> deleteSponsor(String id) async {
    await _service.deleteDoc('sponsors/$id');
  }

  // ─────────────────────────── Committee ───────────────────────────

  Future<List<CommitteeMember>> getCommittee() async {
    final docs = await _service.readCollection('committee');
    return docs
        .map((d) => CommitteeMember.fromJson(d, id: d['__id__'] as String))
        .toList();
  }

  Future<void> addCommitteeMember(CommitteeMember m) async {
    await _service.setDoc('committee/${m.id}', m.toJson());
  }

  Future<void> updateCommitteeMember(CommitteeMember m) async {
    await _service.updateDoc('committee/${m.id}', m.toJson());
  }

  Future<void> deleteCommitteeMember(String id) async {
    await _service.deleteDoc('committee/$id');
  }

  // ─────────────────────── Committee categories ───────────────────────

  Future<List<CommitteeCategory>> getCommitteeCategories() async {
    final docs = await _service.readCollection('committee_categories');
    return docs
        .map((d) => CommitteeCategory.fromJson(d, id: d['__id__'] as String))
        .toList();
  }

  Future<void> addCommitteeCategory(CommitteeCategory c) async {
    await _service.setDoc('committee_categories/${c.id}', c.toJson());
  }

  Future<void> updateCommitteeCategory(CommitteeCategory c) async {
    await _service.updateDoc('committee_categories/${c.id}', c.toJson());
  }

  Future<void> deleteCommitteeCategory(String id) async {
    await _service.deleteDoc('committee_categories/$id');
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

  /// Marks a talk as live for its session — the app's live room is
  /// talk-scoped and resolves it purely from `talks[].status == 'live'`.
  ///
  /// Only the talks array is written: the session's `isLive` flag is
  /// deliberately left untouched so it can never become a second, stale source
  /// of truth. Only the target talk's status is flipped, so the parallel talks
  /// in a session can each go live independently.
  ///
  /// The live status is mirrored into the tiny `live_now/{talkId}` doc (one
  /// per live talk) that the app's home screen and live rooms stream, so they
  /// never have to re-scan the whole agenda. Going live writes the mirror;
  /// taking off air deletes it.
  Future<void> setTalkLive(
    String dayKey,
    String sessionId,
    String talkId,
    bool isLive,
  ) => setTalkStatus(dayKey, sessionId, talkId, isLive ? 'live' : 'completed');

  /// Sets the session-level `isLive` flag. Used by the scheduler when all
  /// talks in a session are completed to clear the session's live state.
  Future<void> setSessionLive(
    String dayKey,
    String sessionId,
    bool isLive,
  ) async {
    final path = 'agenda/$dayKey/sessions/$sessionId';
    await _service.updateDoc(path, {'isLive': isLive});
  }

  /// Sets a talk's state (`upcoming`, `live`, or `completed`) on the session
  /// document so the app's agenda and home highlights pick it up.  Only one talk
  /// per session can be `live` at any time: when [status] is `live`, every other
  /// talk in the same session is automatically set to `completed` and its
  /// `live_now/{talkId}` mirror is deleted so the home screen and live-room
  /// streams go dark immediately for the replaced talk.
  Future<void> setTalkStatus(
    String dayKey,
    String sessionId,
    String talkId,
    String status,
  ) async {
    if (talkId.trim().isEmpty) return;
    final path = 'agenda/$dayKey/sessions/$sessionId';
    final doc = await _service.readDoc(path);
    if (doc == null) return;
    final talks = (doc['talks'] as List?) ?? const [];
    final updated = talks.map((t) {
      final map = Map<String, dynamic>.from(t as Map);
      if (map['id'] == talkId) {
        map['status'] = status;
      } else if (status == 'live') {
        map['status'] = 'completed';
      }
      return map;
    }).toList();
    await _service.updateDoc(path, {'talks': updated});
    await _writeLiveMirror(dayKey, sessionId, talkId, status == 'live', doc);
    if (status == 'live') {
      for (final t in talks) {
        final id = (t as Map)['id'] as String?;
        if (id != null && id.isNotEmpty && id != talkId) {
          await _service.deleteDoc('live_now/$id');
        }
      }
    }
  }

  /// Writes or deletes the `live_now/{talkId}` mirror doc. On-air writes a
  /// minimal doc the app renders as its "Live Now" card; off-air deletes it so
  /// the home and live-room streams go dark immediately.
  Future<void> _writeLiveMirror(
    String dayKey,
    String sessionId,
    String talkId,
    bool isLive,
    Map<String, dynamic> sessionDoc,
  ) async {
    final mirrorPath = 'live_now/$talkId';
    if (!isLive) {
      await _service.deleteDoc(mirrorPath);
      return;
    }
    final item = AgendaItem.fromJson(sessionDoc);
    Talk? talk;
    for (final t in item.talks) {
      if (t.id == talkId) talk = t;
    }
    if (talk == null) return;
    await _service.setDoc(mirrorPath, {
      'talkId': talkId,
      'talkTitle': talk.title,
      'speakers': talk.speakers,
      'sessionId': item.id,
      'sessionTitle': item.title,
      'hall': _hallFromDayKey(dayKey),
      'startTime': Timestamp.fromDate(item.startTime),
      'endTime': Timestamp.fromDate(item.endTime),
      'chair': item.talks.isEmpty ? '' : item.talks.first.speakers.join(', '),
      'durationMinutes': _minutesBetween(item.startTime, item.endTime),
    });
  }

  /// Deletes a single `live_now/{talkId}` mirror doc. Used by the scheduler
  /// sweep to clean up orphaned mirrors.
  Future<void> deleteLiveMirror(String talkId) async {
    await _service.deleteDoc('live_now/$talkId');
  }

  static String _hallFromDayKey(String dayKey) =>
      dayKey.replaceFirst(RegExp(r'^day\d+_hall_'), '').toUpperCase();

  static int _minutesBetween(DateTime start, DateTime end) {
    final a = start.hour * 60 + start.minute;
    final b = end.hour * 60 + end.minute;
    if (a == 0 && b == 0) return 60;
    return (b - a).abs().clamp(0, 24 * 60);
  }

  // ─────────────────────────── Live Room ───────────────────────────

  /// Locates a session's document path by scanning the agenda day keys.
  /// Session paths are stable (sessions never move between days/collections),
  /// so resolutions are memoized — the Overview live-room banner re-resolves
  /// live session ids on every load and would otherwise re-scan the agenda.
  final Map<String, String> _sessionPathCache = {};
  final Set<String> _missingSessionIds = {};

  Future<String?> findSessionPath(String sessionId) async {
    final memo = _sessionPathCache[sessionId];
    if (memo != null) return memo;
    if (_missingSessionIds.contains(sessionId)) return null;

    for (final day in await getAgendaDays()) {
      final sessions = await _service.readCollection(
        'agenda/${day.key}/sessions',
      );
      for (final s in sessions) {
        if (s['id'] == sessionId) {
          final path = 'agenda/${day.key}/sessions/$sessionId';
          _sessionPathCache[sessionId] = path;
          return path;
        }
      }
    }
    _missingSessionIds.add(sessionId);
    return null;
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

  /// Raw `live_now/{talkId}` mirror docs — one per talk currently on air,
  /// written by [setTalkLive]. Lets the Overview surface what is live right
  /// now without re-scanning the agenda.
  Future<List<Map<String, dynamic>>> getLiveTalks() async {
    return _service.readCollection('live_now');
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
