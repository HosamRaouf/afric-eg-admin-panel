import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/entities/announcement.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:dartz/dartz.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AdminDataSource _dataSource;

  AnnouncementRepositoryImpl(this._dataSource);

  @override
  FutureResult<List<Announcement>> getAnnouncements() async {
    try {
      return Right(await _dataSource.getAnnouncements());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> add(Announcement announcement) async {
    try {
      await _dataSource.addAnnouncement(announcement);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> update(Announcement announcement) async {
    try {
      await _dataSource.updateAnnouncement(announcement);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> delete(String id) async {
    try {
      await _dataSource.deleteAnnouncement(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
