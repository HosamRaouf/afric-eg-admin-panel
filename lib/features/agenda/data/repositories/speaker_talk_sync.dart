import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';

/// Keeps each speaker's `users/{uid}/talks/{talkId}` subcollection in sync
/// with the talks assigned to them in the agenda.
///
/// Session speakers are stored as display-name strings on the agenda document;
/// this resolves those names to the matching user uids (via the admin user
/// list) and mirrors one talk document per assigned speaker. Names that don't
/// match any user are skipped — the agenda arrays remain the source of truth
/// for display, and this index only feeds per-speaker lookups.
class SpeakerTalkSync {
  final AdminDataSource _dataSource;
  final UsersRepository _users;

  SpeakerTalkSync({
    required AdminDataSource dataSource,
    required UsersRepository users,
  }) : _dataSource = dataSource,
       _users = users;

  /// Adds/updates a talk doc under every (re)assigned speaker and removes the
  /// docs of speakers who were unassigned in [previous]. Pass `null` for
  /// [previous] when the session is brand new.
  Future<void> syncTalks({
    required String dayKey,
    AgendaItem? previous,
    required AgendaItem next,
  }) async {
    final nameToUids = await _resolveNames();
    final nextAssign = _assignments(next, nameToUids);
    final prevAssign = previous == null
        ? const <String, List<String>>{}
        : _assignments(previous, nameToUids);

    for (final entry in nextAssign.entries) {
      final talk = _talkOf(next, entry.key);
      if (talk == null) continue;
      for (final uid in entry.value) {
        await _dataSource.setSpeakerTalk(
          uid,
          talk,
          dayKey: dayKey,
          sessionId: next.id,
        );
      }
    }

    for (final entry in prevAssign.entries) {
      final keep = nextAssign[entry.key] ?? const <String>[];
      for (final uid in entry.value) {
        if (!keep.contains(uid)) {
          await _dataSource.deleteSpeakerTalk(uid, entry.key);
        }
      }
    }
  }

  /// Removes the talk docs for every talk of [item] (used when a session is
  /// deleted).
  Future<void> removeTalks(AgendaItem item) async {
    final nameToUids = await _resolveNames();
    for (final entry in _assignments(item, nameToUids).entries) {
      for (final uid in entry.value) {
        await _dataSource.deleteSpeakerTalk(uid, entry.key);
      }
    }
  }

  /// Resolves display names to uids, keyed by lower-cased trimmed name.
  Future<Map<String, List<String>>> _resolveNames() async {
    final result = await _users.getUsers();
    return result.fold((_) => const <String, List<String>>{}, (users) {
      final map = <String, List<String>>{};
      for (final u in users) {
        final name = u.displayName.trim().toLowerCase();
        if (name.isEmpty) continue;
        (map[name] ??= <String>[]).add(u.uid);
      }
      return map;
    });
  }

  /// talkId -> uids of every user matching one of the talk's speaker names.
  static Map<String, List<String>> _assignments(
    AgendaItem item,
    Map<String, List<String>> nameToUids,
  ) {
    final result = <String, List<String>>{};
    for (final talk in item.talks) {
      final uids = <String>[];
      for (final name in talk.speakers) {
        final matches = nameToUids[name.trim().toLowerCase()];
        if (matches != null) uids.addAll(matches);
      }
      if (uids.isNotEmpty) result[talk.id] = uids;
    }
    return result;
  }

  static Talk? _talkOf(AgendaItem item, String talkId) {
    for (final t in item.talks) {
      if (t.id == talkId) return t;
    }
    return null;
  }
}
