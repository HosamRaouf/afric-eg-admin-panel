import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';

/// Stream-driven TalkScheduler with distributed leader election.
///
/// Only one admin panel instance (the "leader") actively manages talk live
/// transitions and timer callbacks.  Other instances subscribe to the same
/// Firestore stream for UI purposes but skip all writes.  Leadership is
/// determined via a `_scheduler_lock/current` document in Firestore with a
/// heartbeat-based TTL so the lock automatically expires if the leader
/// disconnects, allowing another instance to take over.
class TalkScheduler {
  TalkScheduler(this._dataSource);

  final AdminDataSource _dataSource;

  // ── Leader election ────────────────────────────────────────────────

  /// Unique id for this scheduler instance.  Generated once on construction
  /// so that the Firestore lock document can attribute ownership.
  late final String _leaderId = _generateId();

  /// Whether this instance currently holds the scheduler lock and is
  /// responsible for timer management and Firestore writes.
  bool _isLeader = false;

  /// Observable leadership state — the UI listens to this to show the
  /// leader indicator and toggle switch.
  final ValueNotifier<bool> isLeaderNotifier = ValueNotifier(false);

  bool get isLeader => _isLeader;

  void _setLeader(bool value) {
    _isLeader = value;
    isLeaderNotifier.value = value;
  }

  /// How often the leader refreshes its lock heartbeat.
  static const _heartbeatInterval = Duration(seconds: 15);

  /// Lock TTL — the lock document expires after this duration without a
  /// heartbeat, allowing failover to another instance.
  static const _lockTtl = Duration(seconds: 45);

  /// How often a non-leader instance retries acquiring the lock (failover).
  static const _retryInterval = Duration(seconds: 30);

  Timer? _heartbeatTimer;
  Timer? _retryTimer;

  // ── Scheduler state ────────────────────────────────────────────────

  final List<Timer> _timers = [];
  StreamSubscription? _sessionSub;
  CongressConfig? _config;
  bool _running = false;

  /// Re-entry guard: true while a processing cycle is in progress.
  bool _processing = false;

  /// Set by the stream callback when a new emission arrives during processing.
  /// The `finally` block re-runs one additional cycle with the latest blocks.
  bool _dirty = false;

  /// Most recent blocks emitted by the stream. Updated on every emission;
  /// used by `_processLatestBlocks` so the processing cycle always sees the
  /// freshest state even if several emissions arrived while the previous
  /// cycle was still awaiting Firestore writes.
  List<(AgendaDay, AgendaItem)> _latestBlocks = const [];

  bool get isRunning => _running;

  // ──────────────────────────── Congress hours guard ────────────────

  /// Returns `true` when the current wall-clock time falls within the congress
  /// event date range (first event date → end of last event date). Outside
  /// these windows no talks can be live, so the scheduler skips all Firestore
  /// writes (heartbeat, lock acquisition, auto-start/end) to save billing.
  bool _isCongressActive() {
    final config = _config;
    if (config == null || config.eventDates.isEmpty) return false;
    final now = DateTime.now();
    final first = config.eventDates.first;
    final last = config.eventDates.last;
    final dayStart = DateTime(first.year, first.month, first.day);
    final dayEnd = DateTime(last.year, last.month, last.day, 23, 59, 59);
    return !now.isBefore(dayStart) && !now.isAfter(dayEnd);
  }

  // ──────────────────────────── Lifecycle ────────────────────────────

  void start() {
    if (_running) return;
    _running = true;
    dev.log(
      'TalkScheduler started (id=$_leaderId)',
      name: 'TalkScheduler',
    );
    _initStream();
    // Defer lock acquisition: the stream callback fetches config first,
    // and _tryAcquireLock is called from _processLatestBlocks when
    // congress is confirmed active.
    _checkCongressActivity();
  }

  void stop() {
    _cancelTimers();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _activityCheckTimer?.cancel();
    _activityCheckTimer = null;
    _sessionSub?.cancel();
    _sessionSub = null;
    _config = null;
    _running = false;
    _processing = false;
    _dirty = false;
    if (_isLeader) {
      _setLeader(false);
      _releaseLock();
    }
    isLeaderNotifier.dispose();
    dev.log('TalkScheduler stopped', name: 'TalkScheduler');
  }

  Future<void> refreshSchedule() async {
    if (!_running) return;
    dev.log('Refreshing schedule…', name: 'TalkScheduler');
    _cancelTimers();
    await _reprocessCurrentState();
  }

  /// Periodic check (runs every 5 minutes) that starts or stops the scheduler
  /// based on whether the current time is within the congress date range.
  Timer? _activityCheckTimer;

  void _checkCongressActivity() {
    _activityCheckTimer?.cancel();
    // Run immediately, then every 5 minutes.
    _evaluateActivity();
    _activityCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _evaluateActivity(),
    );
  }

  void _evaluateActivity() {
    if (!_running) return;
    if (_isCongressActive()) {
      // Congress is live — ensure we're trying to acquire the lock.
      if (!_isLeader && _retryTimer == null) {
        dev.log(
          'Congress active — resuming lock acquisition',
          name: 'TalkScheduler',
        );
        _tryAcquireLock();
      }
    } else {
      // Congress is not active — step down if leader, stop retries.
      if (_isLeader) {
        dev.log(
          'Congress inactive — stepping down from leadership',
          name: 'TalkScheduler',
        );
        _setLeader(false);
        _cancelTimers();
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
        _releaseLock();
      }
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  // ────────────── Manual leadership toggle (UI switch) ───────────────

  /// Attempts to forcefully acquire the scheduler lock, even if another
  /// instance currently holds it.  This is triggered by the admin panel's
  /// manual "Be Leader" toggle.  The previous leader will lose leadership
  /// on its next heartbeat (when it discovers the lock owner changed).
  Future<bool> forceLeadership() async {
    if (!_running) return false;
    dev.log('Force-acquiring scheduler lock…', name: 'TalkScheduler');
    _cancelTimers();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    try {
      // Force-delete any existing lock, then acquire.
      await _dataSource.forceReleaseSchedulerLock();
    } catch (_) {}

    try {
      final acquired = await _dataSource.acquireSchedulerLock(
        leaderId: _leaderId,
        ttl: _lockTtl,
      );
      if (acquired) {
        _setLeader(true);
        dev.log(
          'Force-acquired scheduler lock',
          name: 'TalkScheduler',
        );
        _startHeartbeat();
        await _reprocessCurrentState();
        return true;
      }
    } catch (e) {
      dev.log(
          'Force-acquire failed: $e',
          name: 'TalkScheduler',
          error: e,
        );
    }
    return false;
  }

  /// Manually releases leadership so another instance can take over.
  Future<void> releaseLeadership() async {
    if (!_running || !_isLeader) return;
    dev.log('Manually releasing leadership…', name: 'TalkScheduler');
    _cancelTimers();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _setLeader(false);
    await _releaseLock();
    _startRetryTimer();
  }

  // ──────────────────────────── Internal ────────────────────────────

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  // ──────────────────────────── Lock management ─────────────────────

  static String _generateId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _tryAcquireLock() async {
    if (!_running) return;
    if (!_isCongressActive()) {
      dev.log(
        'Lock acquisition skipped — congress not active',
        name: 'TalkScheduler',
      );
      return;
    }
    try {
      final acquired = await _dataSource.acquireSchedulerLock(
        leaderId: _leaderId,
        ttl: _lockTtl,
      );
      if (acquired && !_isLeader) {
        _setLeader(true);
        dev.log(
          'Acquired scheduler lock — this instance is now the leader',
          name: 'TalkScheduler',
        );
        _startHeartbeat();
        _retryTimer?.cancel();
        _retryTimer = null;
        // Process current state immediately with leadership.
        await _reprocessCurrentState();
      } else if (!acquired && _isLeader) {
        // Lost leadership unexpectedly.
        _setLeader(false);
        _cancelTimers();
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
        dev.log(
          'Lost scheduler lock — stepping down to passive',
          name: 'TalkScheduler',
        );
        _startRetryTimer();
      } else if (!acquired && !_isLeader) {
        _startRetryTimer();
      }
    } catch (e) {
      dev.log(
        'Lock acquisition error: $e',
        name: 'TalkScheduler',
        error: e,
      );
      _startRetryTimer();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (!_running || !_isLeader) {
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
        return;
      }
      // Skip the Firestore write if congress is not active — no talks
      // can be live, so the lock is unnecessary.
      if (!_isCongressActive()) {
        dev.log(
          'Heartbeat skipped — congress not active, stepping down',
          name: 'TalkScheduler',
        );
        _setLeader(false);
        _cancelTimers();
        _heartbeatTimer?.cancel();
        _heartbeatTimer = null;
        _releaseLock();
        _startRetryTimer();
        return;
      }
      try {
        final stillLeader = await _dataSource.refreshSchedulerLock(
          leaderId: _leaderId,
          ttl: _lockTtl,
        );
        if (!stillLeader) {
          _setLeader(false);
          _cancelTimers();
          dev.log(
            'Heartbeat lost leadership — stepping down',
            name: 'TalkScheduler',
          );
          _startRetryTimer();
        }
      } catch (e) {
        dev.log(
          'Heartbeat refresh error: $e',
          name: 'TalkScheduler',
          error: e,
        );
      }
    });
  }

  void _startRetryTimer() {
    if (_retryTimer != null) return;
    _retryTimer = Timer.periodic(_retryInterval, (_) async {
      if (!_running || _isLeader) {
        _retryTimer?.cancel();
        _retryTimer = null;
        return;
      }
      // Don't attempt lock acquisition when congress is not active.
      if (!_isCongressActive()) return;
      await _tryAcquireLock();
    });
  }

  Future<void> _releaseLock() async {
    try {
      await _dataSource.releaseSchedulerLock(leaderId: _leaderId);
      dev.log('Released scheduler lock', name: 'TalkScheduler');
    } catch (_) {
      // Best-effort; lock expires on its own.
    }
  }

  // ──────────────────────────── Stream init ──────────────────────────

  void _initStream() async {
    try {
      _config = await _dataSource.getConfig();
    } catch (e) {
      dev.log('Failed to fetch config: $e', name: 'TalkScheduler');
    }

    // Config is now available — evaluate congress activity immediately
    // so we don't wait for the first 5-minute timer tick.
    _evaluateActivity();

    _sessionSub = _dataSource.watchSessionBlocks().listen(
      _onSessionBlocksUpdated,
      onError: (error) {
        dev.log(
          'Session stream error: $error',
          name: 'TalkScheduler',
          error: error,
        );
      },
    );
  }

  Future<void> _reprocessCurrentState() async {
    try {
      _config = await _dataSource.getConfig();
      // Config may have changed — re-evaluate whether congress is active.
      _evaluateActivity();
      final blocks = await _dataSource.listSessionBlocks();
      _latestBlocks = blocks;
      _onSessionBlocksUpdated(blocks);
    } catch (e) {
      dev.log(
        'Reprocess schedule error: $e',
        name: 'TalkScheduler',
        error: e,
      );
    }
  }

  // ──────────────────── Stream callback (non-async) ─────────────────

  /// Called by the stream on every Firestore session/doc change.
  ///
  /// If a processing cycle is already running, stash the blocks and set
  /// [_dirty] so the `finally` block re-runs once with the latest data.
  void _onSessionBlocksUpdated(List<(AgendaDay, AgendaItem)> blocks) {
    if (!_running) return;
    _latestBlocks = blocks;
    if (_processing) {
      _dirty = true;
      return;
    }
    _processLatestBlocks();
  }

  // ──────────────────── Core processing (async) ─────────────────────

  /// Single processing cycle.  Guarded by [_processing] so at most one
  /// execution runs at a time.  After it finishes, if [_dirty] was set
  /// while it was running, one more cycle is kicked off automatically.
  ///
  /// Non-leader instances still run this to keep [_latestBlocks] current
  /// and schedule timers for UI purposes, but all Firestore writes are
  /// gated on [_isLeader].
  Future<void> _processLatestBlocks() async {
    _processing = true;
    _cancelTimers();

    try {
      final config = _config;
      if (config == null || config.eventDates.isEmpty) return;
      // No writes when congress is outside its date range.
      if (!_isCongressActive()) return;

      final now = DateTime.now();
      final blocks = _latestBlocks;

      // Track talk IDs we've set to live in this cycle so we don't
      // auto-start a second talk in the same session.
      final liveSessionTalks = <String>{};

      for (final (day, session) in blocks) {
        try {
          final dayNumber = day.day;
          final eventDate = _dateOnly(config.eventDate(dayNumber));

          for (final talk in session.talks) {
            if (talk.id.isEmpty) continue;
            if (!talk.endTime.isAfter(talk.startTime)) continue;

            final startMoment = _toEventMoment(talk.startTime, eventDate);
            final endMoment = _toEventMoment(talk.endTime, eventDate);

            try {
              // ── Talk is within its scheduled live window ──
              if (!startMoment.isAfter(now) && now.isBefore(endMoment)) {
                if (talk.status == 'upcoming' && _isLeader) {
                  // Don't start this talk if another talk in the same
                  // session is already live — either in Firestore or
                  // already started earlier in this processing cycle.
                  final anotherLive =
                      session.talks.any(
                        (t) => t.id != talk.id && t.status == 'live',
                      ) ||
                      liveSessionTalks.contains(session.id);
                  if (anotherLive) {
                    dev.log(
                      'Skipping auto-start of "${talk.title}" — '
                      'another talk in session "${session.title}" is live',
                      name: 'TalkScheduler',
                    );
                    continue;
                  }
                  dev.log(
                    'Auto-starting talk "${talk.title}"',
                    name: 'TalkScheduler',
                  );
                  await _dataSource.setTalkLive(
                    day.key,
                    session.id,
                    talk.id,
                    true,
                  );
                  liveSessionTalks.add(session.id);
                  // Stream will fire with updated blocks; the dirty-flag
                  // reprocess at the end picks up the new state.
                  continue;
                }
              }

              // ── Schedule future timer for start (leader only) ──
              if (startMoment.isAfter(now) && _isLeader) {
                _scheduleTimer(
                  label: 'START',
                  talkTitle: talk.title,
                  moment: startMoment,
                  now: now,
                  callback: () async {
                    if (!_isLeader) {
                      dev.log(
                        'START timer fired but not leader — skipping "${talk.title}"',
                        name: 'TalkScheduler',
                      );
                      return;
                    }
                    dev.log(
                      'Timer START fired for "${talk.title}"',
                      name: 'TalkScheduler',
                    );
                    await _dataSource.setTalkLive(
                      day.key,
                      session.id,
                      talk.id,
                      true,
                    );
                  },
                );
              }

              // ── Schedule future timer for end (leader only) ──
              if (endMoment.isAfter(now) && _isLeader) {
                _scheduleTimer(
                  label: 'END',
                  talkTitle: talk.title,
                  moment: endMoment,
                  now: now,
                  callback: () async {
                    if (!_isLeader) {
                      dev.log(
                        'END timer fired but not leader — skipping "${talk.title}"',
                        name: 'TalkScheduler',
                      );
                      return;
                    }
                    dev.log(
                      'Timer END fired for "${talk.title}"',
                      name: 'TalkScheduler',
                    );
                    await _dataSource.setTalkLive(
                      day.key,
                      session.id,
                      talk.id,
                      false,
                    );
                  },
                );
              }

              // ── Catch-up: auto-end talks that are live AND past their
              //    scheduled end time.  A short grace window (10 s)
              //    avoids race conditions with manual "Go Live" actions
              //    (where the stream fires before the write settles).
              //    Manual talks (isManual mirror) are never auto-ended. ──
              if (talk.status == 'live' &&
                  _isLeader &&
                  now.difference(endMoment).inSeconds > 10) {
                final isManual = await _dataSource.isTalkManual(talk.id);
                if (isManual) {
                  dev.log(
                    'Catch-up skipping manual talk "${talk.title}"',
                    name: 'TalkScheduler',
                  );
                } else {
                  dev.log(
                    'Catch-up auto-ending talk "${talk.title}" '
                    '(end was $endMoment)',
                    name: 'TalkScheduler',
                  );
                  await _dataSource.setTalkLive(
                    day.key,
                    session.id,
                    talk.id,
                    false,
                  );
                }
              }
            } catch (e) {
              dev.log(
                'Talk processing error for "${talk.title}": $e',
                name: 'TalkScheduler',
                error: e,
              );
            }
          }
        } catch (e) {
          dev.log(
            'Session processing error for "${session.title}": $e',
            name: 'TalkScheduler',
            error: e,
          );
        }
      }
      // ── Sweep: auto-complete any live_now mirror docs whose endTime has
      //    passed.  This catches talks that were started by a previous leader
      //    instance, or talks whose END timer failed to fire. ──
      if (_isLeader) {
        await _sweepExpiredLiveTalks();
      }
    } finally {
      _processing = false;
      if (_dirty && _running) {
        _dirty = false;
        _processLatestBlocks();
      }
    }
  }

  /// Scans all `live_now/{talkId}` mirror docs and auto-completes any whose
  /// `endTime` is in the past.  This is a safety net that runs at the end of
  /// every processing cycle so no live talk gets stuck on-air forever.
  Future<void> _sweepExpiredLiveTalks() async {
    try {
      final liveTalks = await _dataSource.getLiveTalks();
      final now = DateTime.now();
      for (final mirror in liveTalks) {
        try {
          final talkId = mirror['talkId'] as String?;
          final sessionId = mirror['sessionId'] as String?;
          final dayKey = mirror['dayKey'] as String?;
          final endTimeRaw = mirror['endTime'];
          if (talkId == null ||
              sessionId == null ||
              dayKey == null ||
              endTimeRaw == null) {
            continue;
          }

          final endTime = endTimeRaw is DateTime
              ? endTimeRaw
              : (endTimeRaw as dynamic).toDate();
          if (now.isBefore(endTime)) continue;

          final isManual = mirror['isManual'] == true;
          if (isManual) {
            dev.log(
              'Sweep skipping manual talk "$talkId"',
              name: 'TalkScheduler',
            );
            continue;
          }

          dev.log(
            'Sweep auto-ending live_now "$talkId" (endTime was $endTime)',
            name: 'TalkScheduler',
          );
          await _dataSource.setTalkLive(dayKey, sessionId, talkId, false);
        } catch (e) {
          dev.log(
            'Sweep error for live_now doc: $e',
            name: 'TalkScheduler',
            error: e,
          );
        }
      }
    } catch (e) {
      dev.log(
        'SweepExpiredLiveTalks failed: $e',
        name: 'TalkScheduler',
        error: e,
      );
    }
  }

  void _scheduleTimer({
    required String label,
    required String talkTitle,
    required DateTime moment,
    required DateTime now,
    required Future<void> Function() callback,
  }) {
    final delay = moment.difference(now);
    _timers.add(Timer(delay, () async {
      try {
        await callback();
      } catch (e) {
        dev.log(
          '$label failed for "$talkTitle": $e',
          name: 'TalkScheduler',
          error: e,
        );
      }
    }));
  }

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
}
