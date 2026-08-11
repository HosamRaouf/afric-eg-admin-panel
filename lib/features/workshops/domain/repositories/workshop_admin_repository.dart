import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop_session.dart';

abstract class WorkshopAdminRepository {
  FutureResult<List<Workshop>> getWorkshops();
  FutureResult<void> add(Workshop workshop);
  FutureResult<void> update(Workshop workshop);
  FutureResult<void> delete(String id);
  FutureResult<List<WorkshopSession>> getSessions(String workshopId);
  FutureResult<void> addSession(String workshopId, WorkshopSession session);
  FutureResult<void> updateSession(String workshopId, WorkshopSession session);
  FutureResult<void> deleteSession(String workshopId, String id);
}
