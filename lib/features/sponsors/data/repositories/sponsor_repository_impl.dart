import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/sponsors/domain/entities/sponsor.dart';
import 'package:afric_eg_admin_panel/features/sponsors/domain/repositories/sponsor_repository.dart';
import 'package:dartz/dartz.dart';

class SponsorRepositoryImpl implements SponsorRepository {
  final AdminDataSource _dataSource;

  SponsorRepositoryImpl(this._dataSource);

  @override
  FutureResult<List<Sponsor>> getSponsors() async {
    try {
      return Right(await _dataSource.getSponsors());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> add(Sponsor sponsor) async {
    try {
      await _dataSource.addSponsor(sponsor);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> update(Sponsor sponsor) async {
    try {
      await _dataSource.updateSponsor(sponsor);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> delete(String id) async {
    try {
      await _dataSource.deleteSponsor(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
