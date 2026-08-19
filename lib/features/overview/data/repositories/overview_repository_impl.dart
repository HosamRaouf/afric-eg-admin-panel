import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/entities/overview_data.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/repositories/overview_repository.dart';
import 'package:afric_eg_admin_panel/features/users/domain/entities/panel_user.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';
import 'package:dartz/dartz.dart';

class OverviewRepositoryImpl implements OverviewRepository {
  final AdminDataSource _dataSource;
  final UsersRepository _usersRepository;

  OverviewRepositoryImpl(this._dataSource, this._usersRepository);

  @override
  FutureResult<OverviewData> getOverview() async {
    try {
      final config = await _dataSource.getConfig();

      final announcements = await _dataSource.getAnnouncements();
      final sponsors = await _dataSource.getSponsors();
      final committee = await _dataSource.getCommittee();
      final categories = await _dataSource.getCommitteeCategories();
      final workshops = await _dataSource.getWorkshops();
      final days = await _dataSource.getAgendaDays();

      var agendaItems = 0;
      var talks = 0;
      final speakerSet = <String>{};
      for (final day in days) {
        final items = await _dataSource.getAgendaItems(day.key);
        agendaItems += items.length;
        for (final item in items) {
          if (!item.isSessionBlock) continue;
          talks += item.talks.length;
          for (final t in item.talks) {
            speakerSet.addAll(t.speakers);
          }
        }
      }

      var workshopSessions = 0;
      for (final w in workshops) {
        workshopSessions += (await _dataSource.getWorkshopSessions(
          w.id,
        )).length;
      }

      var liveQuestions = 0;
      var raisedHands = 0;
      final liveTalkDocs = await _dataSource.getLiveTalks();
      for (final talk in liveTalkDocs) {
        final sessionId = talk['sessionId'] as String?;
        if (sessionId == null) continue;
        final path = await _dataSource.findSessionPath(sessionId);
        if (path == null) continue;
        raisedHands += (await _dataSource.getHandRaises(path)).length;
        liveQuestions += (await _dataSource.getLiveQuestions(path)).length;
      }

      final liveTalks =
          liveTalkDocs.map(LiveTalkSummary.fromJson).toList();

      final users = await _fetchUsers();

      return Right(
        OverviewData(
          config: config,
          announcementCount: announcements.length,
          sponsorCount: sponsors.length,
          committeeCount: committee.length,
          committeeCategoryCount: categories.length,
          workshopCount: workshops.length,
          workshopSessionCount: workshopSessions,
          agendaItemCount: agendaItems,
          agendaTrackCount: days.length,
          talkCount: talks,
          speakerCount: speakerSet.length,
          userCount: users.length,
          attendeeCount: _countRole(users, 'attendee'),
          speakerUserCount: _countRole(users, 'speaker'),
          facultyCount: _countRole(users, 'faculty'),
          sponsorUserCount: _countRole(users, 'sponsor'),
          adminCount: _countRole(users, 'admin'),
          liveQuestionCount: liveQuestions,
          liveRaisedHands: raisedHands,
          liveTalks: liveTalks,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  static int _countRole(List<PanelUser> users, String role) =>
      users.where((u) => u.role == role).length;

  /// User counts are best-effort: they come from the `listUsers` Cloud
  /// Function (server-cached for 30s), so a failure there must not take down
  /// the rest of the overview.
  Future<List<PanelUser>> _fetchUsers() async {
    final result = await _usersRepository.getUsers();
    return result.fold((failure) => const <PanelUser>[], (users) => users);
  }
}
