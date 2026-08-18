import 'package:afric_eg_admin_panel/features/committee/domain/repositories/committee_repository.dart';
import 'package:afric_eg_admin_panel/features/committee/presentation/bloc/committee_event.dart';
import 'package:afric_eg_admin_panel/features/committee/presentation/bloc/committee_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommitteeBloc extends Bloc<CommitteeEvent, CommitteeState> {
  final CommitteeRepository _repository;

  CommitteeBloc({required CommitteeRepository repository})
      : _repository = repository,
        super(const CommitteeState()) {
    on<LoadCommitteeEvent>(_onLoad);
    on<SaveCommitteeMemberEvent>(_onSaveMember);
    on<DeleteCommitteeMemberEvent>(_onDeleteMember);
    on<LoadCommitteeCategoriesEvent>(_onLoadCategories);
    on<SaveCommitteeCategoryEvent>(_onSaveCategory);
    on<DeleteCommitteeCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onLoad(
      LoadCommitteeEvent event, Emitter<CommitteeState> emit) async {
    if (state.members.isNotEmpty) return;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final result = await _repository.getCommittee();
      final catResult = await _repository.getCommitteeCategories();
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isLoading: false, error: failure.message)),
        (list) {
          catResult.fold(
            (failure) =>
                emit(state.copyWith(isLoading: false, error: failure.message)),
            (cats) => emit(
                state.copyWith(isLoading: false, members: list, categories: cats)),
          );
        },
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: _describe(e, st)));
    }
  }

  Future<void> _onLoadCategories(
      LoadCommitteeCategoriesEvent event,
      Emitter<CommitteeState> emit) async {
    if (state.categories.isNotEmpty) return;
    try {
      final result = await _repository.getCommitteeCategories();
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isLoading: false, error: failure.message)),
        (cats) => emit(state.copyWith(categories: cats)),
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: _describe(e, st)));
    }
  }

  Future<void> _onSaveMember(
      SaveCommitteeMemberEvent event,
      Emitter<CommitteeState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final result = event.isNew
          ? await _repository.add(event.member)
          : await _repository.update(event.member);
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isSaving: false, error: failure.message)),
        (_) {
          final current = state.members;
          final members = event.isNew
              ? [...current, event.member]
              : [
                  for (final m in current)
                    if (m.id == event.member.id) event.member else m,
                ];
          emit(state.copyWith(
            isSaving: false,
            error: null,
            members: members,
          ));
        },
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: _describe(e, st)));
    }
  }

  Future<void> _onDeleteMember(
      DeleteCommitteeMemberEvent event,
      Emitter<CommitteeState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final result = await _repository.delete(event.id);
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isSaving: false, error: failure.message)),
        (_) => emit(state.copyWith(
          isSaving: false,
          error: null,
          members: [
            for (final m in state.members)
              if (m.id != event.id) m,
          ],
        )),
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: _describe(e, st)));
    }
  }

  Future<void> _onSaveCategory(
      SaveCommitteeCategoryEvent event,
      Emitter<CommitteeState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final result = event.isNew
          ? await _repository.addCategory(event.category)
          : await _repository.updateCategory(event.category);
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isSaving: false, error: failure.message)),
        (_) {
          final current = state.categories;
          final categories = event.isNew
              ? [...current, event.category]
              : [
                  for (final c in current)
                    if (c.id == event.category.id) event.category else c,
                ];
          emit(state.copyWith(
            isSaving: false,
            error: null,
            categories: categories,
          ));
        },
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: _describe(e, st)));
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCommitteeCategoryEvent event,
      Emitter<CommitteeState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final result = await _repository.deleteCategory(event.id);
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isSaving: false, error: failure.message)),
        (_) => emit(state.copyWith(
          isSaving: false,
          error: null,
          categories: [
            for (final c in state.categories)
              if (c.id != event.id) c,
          ],
        )),
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: _describe(e, st)));
    }
  }

  static String _describe(Object error, StackTrace stackTrace) {
    if (error is Exception || error is Error) return error.toString();
    return '${error.runtimeType}:\n$stackTrace';
  }
}
