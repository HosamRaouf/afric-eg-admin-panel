import 'package:cloud_firestore/cloud_firestore.dart';

/// Low-level Cloud Firestore access used by the Firestore data source.
///
/// Document/collection paths follow the AFRIC 2026 schema:
///
///   config/congress                 — congress-level config
///   announcements                   — home feed
///   agenda/{dayKey}                 — one doc per day/track (e.g. day1_hall_a)
///   agenda/{dayKey}/sessions/{sid}  — agenda items (type: sessionBlock | breakBand | ceremony)
///   agenda/{dayKey}/sessions/{sid}/live_room/{qid} — Q&A per session
///   workshops/{id}                  — workshop details
///   workshops/{id}/sessions/{sid}   — workshop sessions (isBreak, dayLabel)
///   users/{uid}                     — attendee profile + journey state
///   users/{uid}/talks/{talkId}      — talks a user is assigned as a speaker
///   sponsors                        — sponsors list
///   admins/{uid}                    — admin panel membership registry
class FirestoreService {
  final FirebaseFirestore _db;

  /// Short-TTL read cache so repeated screen loads (Overview, session scans)
  /// don't re-read the same documents from Firestore on every navigation.
  /// Live data paths (live_now, agenda, live_room) ALWAYS bypass this cache
  /// so admin live moderation streams directly without delay.
  static const Duration _cacheTtl = Duration(seconds: 15);
  final Map<String, ({DateTime at, Object? value})> _cache = {};

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _db.collection(path);

  DocumentReference<Map<String, dynamic>> doc(String path) => _db.doc(path);

  bool _shouldBypassCache(String path) =>
      path.startsWith('live_now') || path.startsWith('agenda');

  void _cachePut(String path, Object? value) {
    _cache[path] = (at: DateTime.now(), value: value);
  }

  bool _cacheValid(String path) {
    final entry = _cache[path];
    if (entry == null) return false;
    return DateTime.now().difference(entry.at) <= _cacheTtl;
  }

  /// Drops the cache entry for [path], any of its children, and every
  /// ancestor collection key.
  void _invalidate(String path) {
    _cache.remove(path);
    _cache.removeWhere((key, _) => key.startsWith('$path/'));
    var slash = path.lastIndexOf('/');
    while (slash != -1) {
      _cache.remove(path.substring(0, slash));
      slash = path.lastIndexOf('/', slash - 1);
    }
  }

  Future<void> setDoc(String path, Map<String, dynamic> data,
      [SetOptions? options]) async {
    await _withRetry(() => _db.doc(path).set(data, options));
    _invalidate(path);
  }

  Future<void> updateDoc(String path, Map<String, dynamic> data) async {
    await _withRetry(() => _db.doc(path).update(data));
    _invalidate(path);
  }

  Future<void> deleteDoc(String path) async {
    await _withRetry(() => _db.doc(path).delete());
    _invalidate(path);
  }

  /// Runs [op], retrying a bounded number of times with backoff.
  Future<T> _withRetry<T>(Future<T> Function() op, {int attempts = 3}) async {
    Object? last;
    for (var i = 0; i < attempts; i++) {
      try {
        return await op();
      } catch (e) {
        last = e;
        await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
      }
    }
    throw last!;
  }

  /// Reads a single document, returning null when it does not exist.
  /// Bypasses cache for live streams/paths (live_now, agenda).
  Future<Map<String, dynamic>?> readDoc(String path) async {
    if (!_shouldBypassCache(path) && _cacheValid(path)) {
      final cached = _cache[path]!.value;
      if (cached == null) return null;
      return Map<String, dynamic>.from(cached as Map<String, dynamic>);
    }
    final doc = await _withRetry<Map<String, dynamic>?>(() async {
      final snapshot = await _db.doc(path).get();
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
    if (!_shouldBypassCache(path)) {
      _cachePut(path, doc);
    }
    return doc;
  }

  /// Reads a whole collection as maps keyed by document id.
  /// Bypasses cache for live streams/paths (live_now, agenda).
  Future<List<Map<String, dynamic>>> readCollection(String path) async {
    if (!_shouldBypassCache(path) && _cacheValid(path)) {
      return (_cache[path]!.value as List<Map<String, dynamic>>)
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    }
    final docs = await _withRetry(() async {
      final snapshot = await _db.collection(path).get();
      return snapshot.docs.map((d) {
        final data = d.data();
        return {'__id__': d.id, ...data};
      }).toList();
    });
    if (!_shouldBypassCache(path)) {
      _cachePut(path, docs);
    }
    return docs;
  }

  /// Streams a collection as maps keyed by document id, emitting on every
  /// snapshot (real-time listener).
  Stream<List<Map<String, dynamic>>> streamCollection(String path) {
    return _db.collection(path).snapshots().map((snapshot) {
      return snapshot.docs.map((d) {
        final data = d.data();
        return {'__id__': d.id, ...data};
      }).toList();
    });
  }

  // ────────────────────── Scheduler distributed lock ──────────────────────

  static const schedulerLockPath = '_scheduler_lock/current';

  /// Attempts to acquire the scheduler leader lock using a Firestore
  /// transaction.  Returns `true` if this instance became the leader.
  ///
  /// A lock is acquirable when:
  ///   * the document does not exist, OR
  ///   * the document exists but its `expiresAt` is in the past (stale lock).
  Future<bool> acquireSchedulerLock({
    required String leaderId,
    Duration ttl = const Duration(seconds: 45),
  }) async {
    final ref = _db.doc(schedulerLockPath);
    try {
      return await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final now = DateTime.now();

        if (snap.exists) {
          final data = snap.data()!;
          final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
          if (expiresAt != null && expiresAt.isAfter(now)) {
            // Lock is still held by another instance.
            return false;
          }
        }

        // Acquire or reclaim the lock.
        tx.set(ref, {
          'leaderId': leaderId,
          'heartbeat': Timestamp.now(),
          'expiresAt': Timestamp.fromDate(now.add(ttl)),
        });
        return true;
      });
    } catch (e) {
      // Transaction failure → another instance likely won.  Treat as not leader.
      return false;
    }
  }

  /// Refreshes the heartbeat on an existing lock.  Returns `false` if this
  /// instance no longer holds the lock (another instance stole it).
  Future<bool> refreshSchedulerLock({
    required String leaderId,
    Duration ttl = const Duration(seconds: 45),
  }) async {
    final ref = _db.doc(schedulerLockPath);
    try {
      return await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data()!;
        if (data['leaderId'] != leaderId) return false;

        tx.update(ref, {
          'heartbeat': Timestamp.now(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(ttl)),
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// Releases the scheduler lock if this instance is the current leader.
  Future<void> releaseSchedulerLock({required String leaderId}) async {
    try {
      final ref = _db.doc(schedulerLockPath);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        if ((snap.data()!['leaderId'] as String?) != leaderId) return;
        tx.delete(ref);
      });
    } catch (_) {
      // Best-effort cleanup; lock will expire on its own anyway.
    }
  }

  /// Forcefully deletes the scheduler lock regardless of who holds it.
  /// Used by the manual "Be Leader" toggle.
  Future<void> forceReleaseSchedulerLock() async {
    try {
      await _db.doc(schedulerLockPath).delete();
    } catch (_) {}
  }

  /// Returns `true` if the lock document exists AND is still valid (not
  /// expired).  Used by non-leaders to detect whether leadership is available
  /// without attempting a transaction.
  Future<bool> isSchedulerLockHeld() async {
    try {
      final doc = await _db.doc(schedulerLockPath).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      return expiresAt != null && expiresAt.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
