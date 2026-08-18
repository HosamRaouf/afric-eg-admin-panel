import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_member.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_category.dart';
import 'package:equatable/equatable.dart';

abstract class CommitteeEvent extends Equatable {
  const CommitteeEvent();

  @override
  List<Object?> get props => [];
}

class LoadCommitteeEvent extends CommitteeEvent {
  const LoadCommitteeEvent();
}

class SaveCommitteeMemberEvent extends CommitteeEvent {
  final CommitteeMember member;
  final bool isNew;
  const SaveCommitteeMemberEvent(this.member, {this.isNew = false});

  @override
  List<Object?> get props => [member, isNew];
}

class DeleteCommitteeMemberEvent extends CommitteeEvent {
  final String id;
  const DeleteCommitteeMemberEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadCommitteeCategoriesEvent extends CommitteeEvent {
  const LoadCommitteeCategoriesEvent();
}

class SaveCommitteeCategoryEvent extends CommitteeEvent {
  final CommitteeCategory category;
  final bool isNew;
  const SaveCommitteeCategoryEvent(this.category, {this.isNew = false});

  @override
  List<Object?> get props => [category, isNew];
}

class DeleteCommitteeCategoryEvent extends CommitteeEvent {
  final String id;
  const DeleteCommitteeCategoryEvent(this.id);

  @override
  List<Object?> get props => [id];
}
