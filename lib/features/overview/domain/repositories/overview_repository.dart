import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/entities/overview_data.dart';

abstract class OverviewRepository {
  FutureResult<OverviewData> getOverview();
}
