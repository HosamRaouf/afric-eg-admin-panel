import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';

/// Aggregated numbers and state shown on the overview dashboard.
class OverviewData {
  final CongressConfig? config;
  final int announcementCount;
  final int workshopCount;
  final int agendaItemCount;
  final int agendaDayCount;
  final int liveQuestionCount;
  final int liveRaisedHands;
  final String? liveSessionTitle;

  const OverviewData({
    this.config,
    this.announcementCount = 0,
    this.workshopCount = 0,
    this.agendaItemCount = 0,
    this.agendaDayCount = 0,
    this.liveQuestionCount = 0,
    this.liveRaisedHands = 0,
    this.liveSessionTitle,
  });
}
