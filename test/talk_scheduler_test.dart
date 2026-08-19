import 'dart:async';
import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/services/talk_scheduler.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAdminDataSource implements AdminDataSource {
  CongressConfig? config;
  List<AgendaDay> days = [];
  Map<String, List<AgendaItem>> itemsByDay = {};
  List<Map<String, dynamic>> liveTalks = [];
  final StreamController<List<(AgendaDay, AgendaItem)>> sessionController =
      StreamController.broadcast();

  final List<String> statusLogs = [];
  final List<String> deletedMirrors = [];
  final Set<String> manualTalkIds = {};

  /// When true, [acquireSchedulerLock] always returns `true`.
  bool lockAcquirable = true;

  /// Simulates the lock already being held by another instance.
  bool lockHeldExternally = false;

  @override
  Future<CongressConfig?> getConfig() async => config;

  @override
  Future<List<AgendaDay>> getAgendaDays() async => days;

  @override
  Future<List<AgendaItem>> getAgendaItems(String dayKey) async =>
      itemsByDay[dayKey] ?? [];

  @override
  Future<List<(AgendaDay, AgendaItem)>> listSessionBlocks() async {
    final result = <(AgendaDay, AgendaItem)>[];
    for (final day in days) {
      for (final item in itemsByDay[day.key] ?? const []) {
        if (item.isSessionBlock) result.add((day, item));
      }
    }
    return result;
  }

  @override
  Stream<List<(AgendaDay, AgendaItem)>> watchSessionBlocks() =>
      sessionController.stream;

  @override
  Future<List<Map<String, dynamic>>> getLiveTalks() async => liveTalks;

  @override
  Future<void> setTalkLive(
    String dayKey,
    String sessionId,
    String talkId,
    bool isLive, {
    bool isManual = false,
  }) async {
    statusLogs.add('$dayKey:$sessionId:$talkId:${isLive ? "live" : "completed"}');
    if (isManual) manualTalkIds.add(talkId);
  }

  @override
  Future<void> setTalkStatus(
    String dayKey,
    String sessionId,
    String talkId,
    String status, {
    bool isManual = false,
  }) async {
    statusLogs.add('$dayKey:$sessionId:$talkId:$status');
  }

  @override
  Future<void> setSessionLive(
    String dayKey,
    String sessionId,
    bool isLive,
  ) async {
    statusLogs.add('$dayKey:$sessionId:sessionIsLive:$isLive');
  }

  @override
  Future<void> deleteLiveMirror(String talkId) async {
    deletedMirrors.add(talkId);
  }

  @override
  Future<bool> isTalkManual(String talkId) async =>
      manualTalkIds.contains(talkId);

  // ── Lock mocks ──────────────────────────────────────────────────────

  @override
  Future<bool> acquireSchedulerLock({
    required String leaderId,
    Duration ttl = const Duration(seconds: 45),
  }) async {
    if (!lockAcquirable || lockHeldExternally) return false;
    return true;
  }

  @override
  Future<bool> refreshSchedulerLock({
    required String leaderId,
    Duration ttl = const Duration(seconds: 45),
  }) async {
    return !lockHeldExternally;
  }

  @override
  Future<void> releaseSchedulerLock({required String leaderId}) async {}

  @override
  Future<void> forceReleaseSchedulerLock() async {}

  @override
  Future<bool> isSchedulerLockHeld() async => lockHeldExternally;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAdminDataSource dataSource;
  late TalkScheduler scheduler;

  setUp(() {
    dataSource = MockAdminDataSource();
    scheduler = TalkScheduler(dataSource);
  });

  test('TalkScheduler starts and stops cleanly', () {
    expect(scheduler.isRunning, false);
    scheduler.start();
    expect(scheduler.isRunning, true);
    scheduler.stop();
    expect(scheduler.isRunning, false);
  });

  test('TalkScheduler acquires lock and becomes leader on start', () async {
    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [DateTime.now()],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];

    scheduler.start();
    await Future.delayed(const Duration(milliseconds: 100));

    expect(scheduler.isLeader, true);
    scheduler.stop();
  });

  test('TalkScheduler stays passive when lock is held externally', () async {
    dataSource.lockHeldExternally = true;

    scheduler.start();
    await Future.delayed(const Duration(milliseconds: 100));

    expect(scheduler.isLeader, false);
    scheduler.stop();
  });

  test('TalkScheduler does not execute callbacks for past talk start/end times during stream update', () async {
    final now = DateTime.now();
    final pastStart = now.subtract(const Duration(hours: 2));
    final pastEnd = now.subtract(const Duration(hours: 1));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Past Session',
      startTime: pastStart,
      endTime: pastEnd,
      talks: [
        Talk(
          id: 't1',
          title: 'Past Talk 1',
          role: 'Speaker',
          hall: 'A',
          startTime: pastStart,
          endTime: pastEnd,
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    scheduler.start();
    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(dataSource.statusLogs, isEmpty);
    scheduler.stop();
  });

  test('TalkScheduler writes are skipped when not leader', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 5));
    final end = now.add(const Duration(hours: 1));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Live Session',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'Live Talk',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    // Lock is held externally — this instance will be passive.
    dataSource.lockHeldExternally = true;
    scheduler.start();
    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    // No writes should have been made.
    expect(dataSource.statusLogs, isEmpty);
    expect(scheduler.isLeader, false);
    scheduler.stop();
  });

  test('TalkScheduler leader auto-starts a talk in its live window', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 5));
    final end = now.add(const Duration(hours: 1));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Live Session',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'Live Talk',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    scheduler.start();
    // Wait for leadership + initial reprocess microtask chain to settle.
    for (var i = 0; i < 50 && !scheduler.isLeader; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(scheduler.isLeader, true);

    // Trigger processing explicitly via the stream (mirrors how Firestore
    // blocks arrive in production).  This avoids relying on the internal
    // fire-and-forget microtask chain from _reprocessCurrentState.
    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(
      dataSource.statusLogs,
      contains('day1_hall_a:s1:t1:live'),
    );
    scheduler.stop();
  });

  test('TalkScheduler sweep auto-completes expired live_now mirrors', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 2));
    final end = now.subtract(const Duration(minutes: 30));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Expired Session',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'Expired Talk',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'live',
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    // Simulate a live_now mirror doc whose endTime has passed.
    dataSource.liveTalks = [
      {
        '__id__': 't1',
        'talkId': 't1',
        'sessionId': 's1',
        'dayKey': 'day1_hall_a',
        'endTime': end,
      },
    ];

    scheduler.start();
    for (var i = 0; i < 50 && !scheduler.isLeader; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(scheduler.isLeader, true);

    // Trigger a processing cycle.
    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    // The sweep should have auto-ended the expired live_now talk.
    expect(
      dataSource.statusLogs,
      contains('day1_hall_a:s1:t1:completed'),
    );
    scheduler.stop();
  });

  test('TalkScheduler sweep does not complete talks still within endTime', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 10));
    final end = now.add(const Duration(minutes: 50));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Active Session',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'Active Talk',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'live',
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    // Simulate a live_now mirror doc whose endTime is still in the future.
    dataSource.liveTalks = [
      {
        '__id__': 't1',
        'talkId': 't1',
        'sessionId': 's1',
        'dayKey': 'day1_hall_a',
        'endTime': end,
      },
    ];

    scheduler.start();
    for (var i = 0; i < 50 && !scheduler.isLeader; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(scheduler.isLeader, true);

    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    // The sweep should NOT have ended the talk — it's still within its window.
    expect(
      dataSource.statusLogs.contains('day1_hall_a:s1:t1:completed'),
      false,
    );
    scheduler.stop();
  });

  test('TalkScheduler skips auto-start when another talk in session is live', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 10));
    final end = now.add(const Duration(hours: 1));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Session With Two Talks',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'Talk Already Live',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'live', // manually started before scheduler
        ),
        Talk(
          id: 't2',
          title: 'Talk In Window',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'upcoming',
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    scheduler.start();
    for (var i = 0; i < 50 && !scheduler.isLeader; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(scheduler.isLeader, true);

    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    // t2 should NOT have been started — t1 is already live in the same session.
    expect(
      dataSource.statusLogs.contains('day1_hall_a:s1:t2:live'),
      false,
    );
    // t1 should NOT have been completed either.
    expect(
      dataSource.statusLogs.contains('day1_hall_a:s1:t1:completed'),
      false,
    );
    scheduler.stop();
  });

  test('TalkScheduler auto-starts talk when no other talk in session is live', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 10));
    final end = now.add(const Duration(hours: 1));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Session With Two Talks',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'First Talk',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'upcoming',
        ),
        Talk(
          id: 't2',
          title: 'Second Talk',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'upcoming',
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    scheduler.start();
    for (var i = 0; i < 50 && !scheduler.isLeader; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(scheduler.isLeader, true);

    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    // Both talks are in their live window and neither is live — the scheduler
    // should auto-start the first one it encounters (t1).
    expect(
      dataSource.statusLogs,
      contains('day1_hall_a:s1:t1:live'),
    );
    // t2 should NOT have been started — after t1 went live, the guard
    // prevents starting another talk in the same session.
    expect(
      dataSource.statusLogs.contains('day1_hall_a:s1:t2:live'),
      false,
    );
    scheduler.stop();
  });

  test('TalkScheduler sweep skips manually-started live talks', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 2));
    final end = now.subtract(const Duration(minutes: 30));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Expired Session',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'Manual Talk',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'live',
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    // Mark this talk as manually started.
    dataSource.manualTalkIds.add('t1');

    // Simulate a live_now mirror doc whose endTime has passed.
    dataSource.liveTalks = [
      {
        '__id__': 't1',
        'talkId': 't1',
        'sessionId': 's1',
        'dayKey': 'day1_hall_a',
        'endTime': end,
        'isManual': true,
      },
    ];

    scheduler.start();
    for (var i = 0; i < 50 && !scheduler.isLeader; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(scheduler.isLeader, true);

    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    // The sweep should NOT have auto-ended the manual talk.
    expect(
      dataSource.statusLogs.contains('day1_hall_a:s1:t1:completed'),
      false,
    );
    scheduler.stop();
  });

  test('TalkScheduler catch-up skips manually-started live talks', () async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 2));
    final end = now.subtract(const Duration(minutes: 30));

    dataSource.config = CongressConfig(
      currentDay: 1,
      eventDates: [now],
    );
    dataSource.days = [AgendaDay.fromKey('day1_hall_a')];
    final item = AgendaItem(
      id: 's1',
      title: 'Session With Manual Talk',
      startTime: start,
      endTime: end,
      talks: [
        Talk(
          id: 't1',
          title: 'Manual Talk Past End',
          role: 'Speaker',
          hall: 'A',
          startTime: start,
          endTime: end,
          status: 'live', // already live from manual start
        ),
      ],
    );
    dataSource.itemsByDay['day1_hall_a'] = [item];

    // Mark as manually started — catch-up must not end it.
    dataSource.manualTalkIds.add('t1');

    scheduler.start();
    for (var i = 0; i < 50 && !scheduler.isLeader; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(scheduler.isLeader, true);

    dataSource.sessionController.add([(dataSource.days.first, item)]);
    await Future.delayed(const Duration(milliseconds: 100));

    // The catch-up logic should have skipped this talk because isManual is true.
    expect(
      dataSource.statusLogs.contains('day1_hall_a:s1:t1:completed'),
      false,
    );
    scheduler.stop();
  });
}
