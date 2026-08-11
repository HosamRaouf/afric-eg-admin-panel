import 'package:cloud_firestore/cloud_firestore.dart';

/// A raised hand in a session's mic queue.
///
/// Stored as a document in `agenda/{dayKey}/sessions/{sid}/hand_raises/{uid}`
/// with fields `userId`, `userName`, `raisedAt`. The document id is the user id.
class HandRaise {
  final String uid;
  final String userName;
  final DateTime raisedAt;

  const HandRaise({
    required this.uid,
    required this.userName,
    required this.raisedAt,
  });

  factory HandRaise.fromJson(Map<String, dynamic> json, {String? id}) {
    final raised = json['raisedAt'];
    return HandRaise(
      uid: id ?? json['userId'] as String? ?? json['__id__'] as String,
      userName: json['userName'] as String? ?? 'Attendee',
      raisedAt: raised is Timestamp
          ? raised.toDate()
          : (DateTime.tryParse(raised as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0)),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': uid,
        'userName': userName,
        'raisedAt': Timestamp.fromDate(raisedAt),
      };
}
