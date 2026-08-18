import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_member.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_category.dart';
import 'package:equatable/equatable.dart';

class CommitteeState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<CommitteeMember> members;
  final List<CommitteeCategory> categories;
  final String? error;

  const CommitteeState({
    this.isLoading = false,
    this.isSaving = false,
    this.members = const [],
    this.categories = const [],
    this.error,
  });

  CommitteeState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<CommitteeMember>? members,
    List<CommitteeCategory>? categories,
    String? error,
  }) =>
      CommitteeState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        members: members ?? this.members,
        categories: categories ?? this.categories,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [isLoading, isSaving, members, categories, error];
}
