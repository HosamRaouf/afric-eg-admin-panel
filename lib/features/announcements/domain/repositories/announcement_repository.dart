import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/entities/announcement.dart';

abstract class AnnouncementRepository {
  FutureResult<List<Announcement>> getAnnouncements();
  FutureResult<void> add(Announcement announcement);
  FutureResult<void> update(Announcement announcement);
  FutureResult<void> delete(String id);
}
