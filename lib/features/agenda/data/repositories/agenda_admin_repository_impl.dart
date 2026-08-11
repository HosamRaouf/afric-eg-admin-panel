import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/repositories/agenda_admin_repository.dart';
import 'package:dartz/dartz.dart';

class AgendaAdminRepositoryImpl implements AgendaAdminRepository {
  final AdminDataSource _dataSource;

  AgendaAdminRepositoryImpl(this._dataSource);

  @override
  FutureResult<List<AgendaDay>> getDays() async {
    try {
      return Right(await _dataSource.getAgendaDays());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<List<AgendaItem>> getItems(String dayKey) async {
    try {
      return Right(await _dataSource.getAgendaItems(dayKey));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> addItem(String dayKey, AgendaItem item) async {
    try {
      await _dataSource.addAgendaItem(dayKey, item);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> updateItem(String dayKey, AgendaItem item) async {
    try {
      await _dataSource.updateAgendaItem(dayKey, item);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> deleteItem(String dayKey, String id) async {
    try {
      await _dataSource.deleteAgendaItem(dayKey, id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
