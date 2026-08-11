import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/entities/overview_data.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/repositories/overview_repository.dart';
import 'package:dartz/dartz.dart';

class OverviewRepositoryImpl implements OverviewRepository {
  final AdminDataSource _dataSource;

  OverviewRepositoryImpl(this._dataSource);

  @override
  FutureResult<OverviewData> getOverview() async {
    try {
      final config = await _dataSource.getConfig();
      final announcements = await _dataSource.getAnnouncements();
      final workshops = await _dataSource.getWorkshops();
      final days = await _dataSource.getAgendaDays();

      var agendaItems = 0;
      for (final day in days) {
        agendaItems += (await _dataSource.getAgendaItems(day.key)).length;
      }

      final live = await _dataSource.getLiveSessionDetails();
      var liveQuestions = 0;
      var raisedHands = 0;
      String? liveTitle;
      if (live != null) {
        liveTitle = live['title'] as String?;
        final path = live['path'] as String?;
        if (path != null) {
          raisedHands = (await _dataSource.getHandRaises(path)).length;
          liveQuestions = (await _dataSource.getLiveQuestions(path)).length;
        }
      }

      return Right(OverviewData(
        config: config,
        announcementCount: announcements.length,
        workshopCount: workshops.length,
        agendaItemCount: agendaItems,
        agendaDayCount: days.length,
        liveQuestionCount: liveQuestions,
        liveRaisedHands: raisedHands,
        liveSessionTitle: liveTitle,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
