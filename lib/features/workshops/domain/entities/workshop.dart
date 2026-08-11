import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of `workshops/{id}`.
class Workshop {
  final String id;
  final String title;
  final String? price;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String? day;
  final String? description;
  final String? imageURL;
  final String? program;

  const Workshop({
    required this.id,
    required this.title,
    this.price,
    this.location = '',
    required this.startDate,
    required this.endDate,
    this.day,
    this.description,
    this.imageURL,
    this.program,
  });

  factory Workshop.fromJson(Map<String, dynamic> json, {String? id}) {
    final docId = id ?? json['id'] as String? ?? json['__id__'] as String;
    final location =
        json['location'] as String? ?? json['venue'] as String? ?? '';

    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return fallback;
    }

    return Workshop(
      id: docId,
      title: json['title'] as String? ?? '',
      price: json['price'] as String?,
      location: location,
      startDate: parseDate(json['startDate'], DateTime(2026, 9, 1)),
      endDate: parseDate(json['endDate'], DateTime(2026, 9, 2)),
      day: json['day'] as String?,
      description: json['description'] as String?,
      imageURL: json['imageURL'] as String?,
      program: json['program'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        if (price != null) 'price': price,
        if (day != null) 'day': day,
        if (description != null) 'description': description,
        if (imageURL != null) 'imageURL': imageURL,
        if (program != null) 'program': program,
      };
}
