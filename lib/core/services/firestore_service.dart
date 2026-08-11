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

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _db.collection(path);

  DocumentReference<Map<String, dynamic>> doc(String path) => _db.doc(path);

  Future<void> setDoc(String path, Map<String, dynamic> data,
      [SetOptions? options]) {
    return _withRetry(() => _db.doc(path).set(data, options));
  }

  Future<void> updateDoc(String path, Map<String, dynamic> data) {
    return _withRetry(() => _db.doc(path).update(data));
  }

  Future<void> deleteDoc(String path) {
    return _withRetry(() => _db.doc(path).delete());
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

  /// Reads a single document, returning null when it does not exist.
  Future<Map<String, dynamic>?> readDoc(String path) {
    return _withRetry(() async {
      final snapshot = await _db.doc(path).get();
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  /// Reads a whole collection as maps keyed by document id.
  Future<List<Map<String, dynamic>>> readCollection(String path) {
    return _withRetry(() async {
      final snapshot = await _db.collection(path).get();
      return snapshot.docs.map((d) {
        final data = d.data();
        return {'__id__': d.id, ...data};
      }).toList();
    });
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
