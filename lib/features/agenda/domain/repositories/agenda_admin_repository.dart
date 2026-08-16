import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';

abstract class AgendaAdminRepository {
  FutureResult<List<AgendaDay>> getDays();
  FutureResult<List<DateTime>> getEventDates();
  FutureResult<List<AgendaItem>> getItems(String dayKey);
  FutureResult<void> addItem(String dayKey, AgendaItem item);
  FutureResult<void> updateItem(String dayKey, AgendaItem item);
  FutureResult<void> deleteItem(String dayKey, String id);
}
