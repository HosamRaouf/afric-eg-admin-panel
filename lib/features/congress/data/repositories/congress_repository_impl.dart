import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/repositories/congress_repository.dart';
import 'package:dartz/dartz.dart';

class CongressRepositoryImpl implements CongressRepository {
  final AdminDataSource _dataSource;

  CongressRepositoryImpl(this._dataSource);

  @override
  FutureResult<CongressConfig?> getConfig() async {
    try {
      return Right(await _dataSource.getConfig());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> updateConfig(CongressConfig config) async {
    try {
      await _dataSource.updateConfig(config);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
