import 'dart:math';

/// Generates short unique document ids for new Firestore documents.
class Ids {
  static String generate() {
    final millis = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = _rand();
    return '$millis$rand';
  }

  static String _rand() {
    final r = Random().nextInt(0xFFFFFF).toRadixString(16);
    return r.padLeft(6, '0');
  }
}
