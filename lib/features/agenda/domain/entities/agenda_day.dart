
/// Mirror of `agenda/{dayKey}` metadata (`day`, `hall`).
class AgendaDay {
  final String key; // e.g. day1_hall_a
  final int day;
  final String hall; // uppercase letter, e.g. A

  const AgendaDay({required this.key, required this.day, required this.hall});

  factory AgendaDay.fromKey(String key) {
    final match = RegExp(r'^day(\d+)_hall_([a-z])$').firstMatch(key);
    return AgendaDay(
      key: key,
      day: int.tryParse(match?.group(1) ?? '') ?? 1,
      hall: (match?.group(2) ?? 'a').toUpperCase(),
    );
  }
}
