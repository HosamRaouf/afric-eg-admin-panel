import 'dart:async';
import 'dart:developer' as dev;

import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';

/// Reads all talks from Firestore once, builds a sorted timeline, and
/// schedules an individual [Timer] for each talk's start and end.
///
/// Timer callbacks fire the Firestore write unconditionally — no
/// cache-dependent verification. A lightweight periodic sweep (every 30s)
/// handles:
///   1. Catching up on any missed timer fires (browsers throttle background
///      tabs, so timers can be delayed or killed).
///   2. Cleaning up stale `live_now` mirror docs.
///
/// The scheduler tracks which talks have already been transitioned so the
/// sweep never re-fires a write for a talk that was already handled. The
/// only Firestore read during the sweep is the small `live_now` collection.
///
/// Call [refreshSchedule] after any edit to cancel all timers and rebuild.
class TalkScheduler {
  TalkScheduler(this._dataSource);

  final AdminDataSource _dataSource;

  static const _sweepInterval = Duration(seconds: 30);

  final List<Timer> _timers = [];
  Timer? _sweepTimer;
  bool _running = false;

  /// Cached schedule so the sweep can transition talks without re-reading
  /// Firestore agenda data.
  final List<_TalkSlot> _slots = [];

  /// TalkIds that have already been transitioned to live. Prevents the sweep
  /// from re-firing `setTalkLive(true)` every 30 seconds.
  final Set<String> _started = {};

  /// TalkIds that have already been transitioned to completed.
  final Set<String> _ended = {};

  /// SessionIds whose completion has already been handled.
  final Set<String> _completedSessions = {};

  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running = true;
    dev.log('TalkScheduler started', name: 'TalkScheduler');
    _buildSchedule();
    _sweepTimer = Timer.periodic(_sweepInterval, (_) => _sweepCatchUp());
  }

  void stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _slots.clear();
    _started.clear();
    _ended.clear();
    _completedSessions.clear();
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _running = false;
    dev.log('TalkScheduler stopped', name: 'TalkScheduler');
  }

  Future<void> refreshSchedule() async {
    if (!_running) return;
    dev.log('Refreshing schedule…', name: 'TalkScheduler');
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _slots.clear();
    _started.clear();
    _ended.clear();
    _completedSessions.clear();
    await _buildSchedule();
  }

  // ───────────────────── Build schedule ─────────────────────

  Future<void> _buildSchedule() async {
    try {
      final config = await _dataSource.getConfig();
      if (config == null || config.eventDates.isEmpty) {
        dev.log('No config — schedule empty', name: 'TalkScheduler');
        return;
      }

      final now = DateTime.now();
      final days = await _dataSource.getAgendaDays();
      var count = 0;

      for (final day in days) {
        final dayNumber = AgendaDay.fromKey(day.key).day;
        final eventDate = _dateOnly(config.eventDate(dayNumber));
        final sessions = await _dataSource.getAgendaItems(day.key);

        for (final session in sessions) {
          if (!session.isSessionBlock) continue;

          for (final talk in session.talks) {
            if (talk.type != 'talk' || talk.id.isEmpty) continue;
            if (!talk.endTime.isAfter(talk.startTime)) continue;

            final startMoment = _toEventMoment(talk.startTime, eventDate);
            final endMoment = _toEventMoment(talk.endTime, eventDate);

            _slots.add(_TalkSlot(
              dayKey: day.key,
              sessionId: session.id,
              talkId: talk.id,
              talkTitle: talk.title,
              start: startMoment,
              end: endMoment,
            ));

            // If the talk should already be live, mark it as started so the
            // sweep won't re-fire the write — but fire it once now.
            if (!startMoment.isAfter(now) && now.isBefore(endMoment)) {
              _started.add(talk.id);
            }
            // If the talk should already be completed, mark it as ended.
            if (!endMoment.isAfter(now)) {
              _ended.add(talk.id);
            }

            _scheduleTimer(
              label: 'START',
              talkTitle: talk.title,
              moment: startMoment,
              now: now,
              callback: () async {
                _started.add(talk.id);
                await _dataSource.setTalkLive(
                    day.key, session.id, talk.id, true);
              },
            );
            _scheduleTimer(
              label: 'END',
              talkTitle: talk.title,
              moment: endMoment,
              now: now,
              callback: () async {
                _ended.add(talk.id);
                await _dataSource.setTalkLive(
                    day.key, session.id, talk.id, false);
                await _completeSessionIfDone(day.key, session.id);
              },
            );
            count++;
          }
        }
      }

      // Run an immediate catch-up pass so talks that should already be live
      // (or completed) get transitioned right away — handles the case where
      // the scheduler started after some talk times had already passed.
      await _sweepCatchUp();

      dev.log(
        'Schedule built: ${_timers.length} timers for $count talks '
        '(${_slots.length} slots cached for sweep)',
        name: 'TalkScheduler',
      );
    } catch (e, st) {
      dev.log(
        'Build failed: $e',
        name: 'TalkScheduler',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ───────────────────── Timer creation ─────────────────────

  void _scheduleTimer({
    required String label,
    required String talkTitle,
    required DateTime moment,
    required DateTime now,
    required Future<void> Function() callback,
  }) {
    if (moment.isAfter(now)) {
      final delay = moment.difference(now);
      _timers.add(Timer(delay, () async {
        dev.log(
          'FIRE $label "$talkTitle" (${delay.inSeconds}s ago)',
          name: 'TalkScheduler',
        );
        try {
          await callback();
        } catch (e) {
          dev.log(
            '$label failed "$talkTitle": $e',
            name: 'TalkScheduler',
            error: e,
          );
        }
      }));
      dev.log(
        'Timer $label  "$talkTitle" in ${delay.inSeconds}s '
        '(${moment.hour}:${_mm(moment.minute)})',
        name: 'TalkScheduler',
      );
    } else {
      dev.log(
        'FIRE $label "$talkTitle" (already past)',
        name: 'TalkScheduler',
      );
      try {
        callback().catchError((e) {
          dev.log(
            '$label failed "$talkTitle": $e',
            name: 'TalkScheduler',
            error: e,
          );
        });
      } catch (e) {
        dev.log(
          '$label failed "$talkTitle": $e',
          name: 'TalkScheduler',
          error: e,
        );
      }
    }
  }

  // ───────────────────── Catch-up sweep ─────────────────────

  /// Lightweight periodic sweep that uses cached slot data — **no** reads of
  /// agenda days or sessions.  The only Firestore read is `getLiveTalks()`
  /// (the small `live_now` collection) for stale mirror cleanup.
  Future<void> _sweepCatchUp() async {
    if (!_running) return;

    try {
      final now = DateTime.now();

      // Phase 1: transition missed talks using cached slot data.
      // Only fires for talks we haven't already transitioned.
      for (final slot in _slots) {
        final shouldStart = !slot.start.isAfter(now) &&
            now.isBefore(slot.end) &&
            !_started.contains(slot.talkId);
        if (shouldStart) {
          dev.log(
            'CATCH-UP: starting "${slot.talkTitle}" '
            '(should have started at ${slot.start})',
            name: 'TalkScheduler',
          );
          _started.add(slot.talkId);
          try {
            await _dataSource.setTalkLive(
                slot.dayKey, slot.sessionId, slot.talkId, true);
          } catch (e) {
            _started.remove(slot.talkId);
            dev.log('CATCH-UP start failed: $e',
                name: 'TalkScheduler', error: e);
          }
        }

        final shouldEnd = !slot.end.isAfter(now) &&
            !_ended.contains(slot.talkId);
        if (shouldEnd) {
          dev.log(
            'CATCH-UP: ending "${slot.talkTitle}" '
            '(should have ended at ${slot.end})',
            name: 'TalkScheduler',
          );
          _ended.add(slot.talkId);
          try {
            await _dataSource.setTalkLive(
                slot.dayKey, slot.sessionId, slot.talkId, false);
            await _completeSessionIfDone(slot.dayKey, slot.sessionId);
          } catch (e) {
            _ended.remove(slot.talkId);
            dev.log('CATCH-UP end failed: $e',
                name: 'TalkScheduler', error: e);
          }
        }
      }

      // Phase 2: delete stale `live_now` mirrors.  Only 1 Firestore read.
      final liveDocs = await _dataSource.getLiveTalks();
      for (final doc in liveDocs) {
        final talkId = doc['talkId'] as String? ?? '';
        if (talkId.isEmpty) continue;
        if (_ended.contains(talkId) || !_started.contains(talkId)) {
          dev.log(
            'SWEEP: deleting stale mirror "$talkId"',
            name: 'TalkScheduler',
          );
          try {
            await _dataSource.deleteLiveMirror(talkId);
          } catch (e) {
            dev.log('SWEEP delete failed: $e',
                name: 'TalkScheduler', error: e);
          }
        }
      }
    } catch (e) {
      dev.log('Sweep failed: $e', name: 'TalkScheduler', error: e);
    }
  }

  // ───────────────────── Session completion ─────────────────────

  /// After a talk completes, checks whether every talk in the session is
  /// done using cached slot data — no Firestore reads.
  Future<void> _completeSessionIfDone(String dayKey, String sessionId) async {
    final key = '$dayKey/$sessionId';
    if (_completedSessions.contains(key)) return;

    // Check if ALL talks in this session have ended using cached slots.
    final sessionSlots = _slots.where((s) => s.sessionId == sessionId);
    if (sessionSlots.isEmpty) return;
    final allDone = sessionSlots.every((s) => _ended.contains(s.talkId));
    if (!allDone) return;

    _completedSessions.add(key);
    try {
      await _dataSource.setSessionLive(dayKey, sessionId, false);
      dev.log(
        'SESSION "$sessionId" completed (all talks done)',
        name: 'TalkScheduler',
      );
    } catch (e) {
      _completedSessions.remove(key);
      dev.log(
        'Session completion failed: $e',
        name: 'TalkScheduler',
        error: e,
      );
    }
  }

  // ───────────────────── Time helpers ─────────────────────

  DateTime _toEventMoment(DateTime clockTime, DateTime eventDate) {
    final local = clockTime.toLocal();
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      local.hour,
      local.minute,
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _mm(int m) => m.toString().padLeft(2, '0');
}

class _TalkSlot {
  final String dayKey;
  final String sessionId;
  final String talkId;
  final String talkTitle;
  final DateTime start;
  final DateTime end;

  const _TalkSlot({
    required this.dayKey,
    required this.sessionId,
    required this.talkId,
    required this.talkTitle,
    required this.start,
    required this.end,
  });
}
