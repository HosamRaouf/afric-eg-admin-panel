import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_member.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_category.dart';

abstract class CommitteeRepository {
  FutureResult<List<CommitteeMember>> getCommittee();
  FutureResult<void> add(CommitteeMember member);
  FutureResult<void> update(CommitteeMember member);
  FutureResult<void> delete(String id);

  FutureResult<List<CommitteeCategory>> getCommitteeCategories();
  FutureResult<void> addCategory(CommitteeCategory category);
  FutureResult<void> updateCategory(CommitteeCategory category);
  FutureResult<void> deleteCategory(String id);
}
