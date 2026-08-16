import 'package:afric_eg_admin_panel/features/congress/domain/repositories/congress_repository.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_event.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CongressBloc extends Bloc<CongressEvent, CongressState> {
  final CongressRepository _repository;

  CongressBloc({required CongressRepository repository})
    : _repository = repository,
      super(const CongressState()) {
    on<LoadCongressEvent>(_onLoad);
    on<SaveCongressEvent>(_onSave);
  }

  Future<void> _onLoad(
    LoadCongressEvent event,
    Emitter<CongressState> emit,
  ) async {
    if (state.config != null) return;
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.getConfig();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (config) => emit(state.copyWith(isLoading: false, config: config)),
    );
  }

  Future<void> _onSave(
    SaveCongressEvent event,
    Emitter<CongressState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = await _repository.updateConfig(event.config);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) => emit(state.copyWith(isSaving: false, config: event.config)),
    );
  }
}
