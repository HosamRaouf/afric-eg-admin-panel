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
  /// The TTL keeps edits visible quickly — unlike the main app's lifetime
  /// cache, a stale value here would break the admin's edit-then-see flow.
  static const Duration _cacheTtl = Duration(seconds: 15);
  final Map<String, ({DateTime at, Object? value})> _cache = {};

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _db.collection(path);

  DocumentReference<Map<String, dynamic>> doc(String path) => _db.doc(path);

  void _cachePut(String path, Object? value) {
    _cache[path] = (at: DateTime.now(), value: value);
  }

  bool _cacheValid(String path) {
    final entry = _cache[path];
    if (entry == null) return false;
    return DateTime.now().difference(entry.at) <= _cacheTtl;
  }

  /// Drops the cache entry for [path], any of its children, and every
  /// ancestor collection key. Writing `agenda/day1_hall_a/sessions/x`
  /// invalidates `agenda/day1_hall_a/sessions`, `agenda/day1_hall_a` and
  /// `agenda` reads — otherwise a cached parent collection still lists stale
  /// children (e.g. a just-created `day2_hall_a` never appears in `agenda`).
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
  ///
  /// The Firestore web SDK keeps one-shot reads on a long-lived gRPC-web
  /// channel that can go stale (HTTP 400) after a while; a retry opens a
  /// fresh channel and succeeds.
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

  /// Reads a single document, returning null when it does not exist. Results
  /// are cached for [_cacheTtl] so re-mounts of the same screen don't re-read;
  /// writes invalidate the affected path.
  Future<Map<String, dynamic>?> readDoc(String path) async {
    if (_cacheValid(path)) {
      final cached = _cache[path]!.value;
      if (cached == null) return null;
      return Map<String, dynamic>.from(cached as Map<String, dynamic>);
    }
    final doc = await _withRetry<Map<String, dynamic>?>(() async {
      final snapshot = await _db.doc(path).get();
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
    _cachePut(path, doc);
    return doc;
  }

  /// Reads a whole collection as maps keyed by document id. Cached like
  /// [readDoc]; writes invalidate the affected paths.
  Future<List<Map<String, dynamic>>> readCollection(String path) async {
    if (_cacheValid(path)) {
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
    _cachePut(path, docs);
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
}
