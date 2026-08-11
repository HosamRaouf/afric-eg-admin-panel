import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of a live-room Q&A question stored under
/// `agenda/{dayKey}/sessions/{sid}/live_room/{qid}`.
class Question {
  final String id;
  final String text;
  final String author;
  final bool isAnonymous;
  final int votes;
  final bool votedByUser;
  final bool isPinned;
  final bool isAnswered;
  final String? answer;
  final String? answeredBy;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.text,
    required this.author,
    this.isAnonymous = false,
    this.votes = 0,
    this.votedByUser = false,
    this.isPinned = false,
    this.isAnswered = false,
    this.answer,
    this.answeredBy,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json, {String? id}) {
    final created = json['createdAt'];
    return Question(
      id: id ?? json['id'] as String? ?? json['__id__'] as String,
      text: json['text'] as String? ?? '',
      author: json['author'] as String? ?? '',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      votedByUser: json['votedByUser'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isAnswered: json['isAnswered'] as bool? ?? false,
      answer: json['answer'] as String?,
      answeredBy: json['answeredBy'] as String?,
      createdAt: created is Timestamp
          ? created.toDate()
          : (DateTime.tryParse(created as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0)),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'author': author,
        'isAnonymous': isAnonymous,
        'votes': votes,
        'isPinned': isPinned,
        'isAnswered': isAnswered,
        if (answer != null) 'answer': answer,
        if (answeredBy != null) 'answeredBy': answeredBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Question copyWith({
    bool? isPinned,
    bool? isAnswered,
    String? answer,
    String? answeredBy,
  }) =>
      Question(
        id: id,
        text: text,
        author: author,
        isAnonymous: isAnonymous,
        votes: votes,
        votedByUser: votedByUser,
        isPinned: isPinned ?? this.isPinned,
        isAnswered: isAnswered ?? this.isAnswered,
        answer: answer ?? this.answer,
        answeredBy: answeredBy ?? this.answeredBy,
        createdAt: createdAt,
      );
}
