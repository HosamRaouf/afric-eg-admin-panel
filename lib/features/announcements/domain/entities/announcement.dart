import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of `announcements/{id}` — the home feed announcements.
class Announcement {
  final String id;
  final String icon;
  final String title;
  final String preview;
  final String body;
  final DateTime createdAt;
  final bool unread;

  const Announcement({
    required this.id,
    required this.icon,
    required this.title,
    required this.preview,
    this.body = '',
    required this.createdAt,
    this.unread = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json, {String? id}) {
    final created = json['createdAt'];
    return Announcement(
      id: id ?? json['id'] as String? ?? json['__id__'] as String,
      icon: json['icon'] as String? ?? 'bullhorn',
      title: json['title'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: created is Timestamp
          ? created.toDate()
          : (DateTime.tryParse(created as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0)),
      unread: json['unread'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'icon': icon,
        'title': title,
        'preview': preview,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'unread': unread,
      };
}
