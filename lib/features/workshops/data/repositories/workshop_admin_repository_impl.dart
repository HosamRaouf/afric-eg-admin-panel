import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop_session.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/repositories/workshop_admin_repository.dart';
import 'package:dartz/dartz.dart';

class WorkshopAdminRepositoryImpl implements WorkshopAdminRepository {
  final AdminDataSource _dataSource;

  WorkshopAdminRepositoryImpl(this._dataSource);

  @override
  FutureResult<List<Workshop>> getWorkshops() async {
    try {
      return Right(await _dataSource.getWorkshops());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> add(Workshop workshop) async {
    try {
      await _dataSource.addWorkshop(workshop);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> update(Workshop workshop) async {
    try {
      await _dataSource.updateWorkshop(workshop);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> delete(String id) async {
    try {
      await _dataSource.deleteWorkshop(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<List<WorkshopSession>> getSessions(String workshopId) async {
    try {
      return Right(await _dataSource.getWorkshopSessions(workshopId));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> addSession(String workshopId, WorkshopSession session) async {
    try {
      await _dataSource.addWorkshopSession(workshopId, session);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> updateSession(String workshopId, WorkshopSession session) async {
    try {
      await _dataSource.updateWorkshopSession(workshopId, session);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> deleteSession(String workshopId, String id) async {
    try {
      await _dataSource.deleteWorkshopSession(workshopId, id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
