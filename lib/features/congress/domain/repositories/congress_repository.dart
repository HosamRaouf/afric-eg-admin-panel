import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';

abstract class CongressRepository {
  FutureResult<CongressConfig?> getConfig();
  FutureResult<List<(AgendaDay, AgendaItem)>> getSessionBlocks();
  FutureResult<void> updateConfig(CongressConfig config);
}
