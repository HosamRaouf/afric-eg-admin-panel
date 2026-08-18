import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_member.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_category.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/repositories/committee_repository.dart';
import 'package:dartz/dartz.dart';

class CommitteeRepositoryImpl implements CommitteeRepository {
  final AdminDataSource _dataSource;

  CommitteeRepositoryImpl(this._dataSource);

  @override
  FutureResult<List<CommitteeMember>> getCommittee() async {
    try {
      return Right(await _dataSource.getCommittee());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> add(CommitteeMember member) async {
    try {
      await _dataSource.addCommitteeMember(member);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> update(CommitteeMember member) async {
    try {
      await _dataSource.updateCommitteeMember(member);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> delete(String id) async {
    try {
      await _dataSource.deleteCommitteeMember(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<List<CommitteeCategory>> getCommitteeCategories() async {
    try {
      return Right(await _dataSource.getCommitteeCategories());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> addCategory(CommitteeCategory category) async {
    try {
      await _dataSource.addCommitteeCategory(category);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> updateCategory(CommitteeCategory category) async {
    try {
      await _dataSource.updateCommitteeCategory(category);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> deleteCategory(String id) async {
    try {
      await _dataSource.deleteCommitteeCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
