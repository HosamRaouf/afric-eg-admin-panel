import 'package:afric_eg_admin_panel/features/overview/domain/repositories/overview_repository.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/bloc/overview_event.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/bloc/overview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OverviewBloc extends Bloc<OverviewEvent, OverviewState> {
  final OverviewRepository _repository;

  OverviewBloc({required OverviewRepository repository})
    : _repository = repository,
      super(const OverviewState()) {
    on<LoadOverviewEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadOverviewEvent event,
    Emitter<OverviewState> emit,
  ) async {
    if (state.data != null && !event.force) return;
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.getOverview();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) => emit(state.copyWith(isLoading: false, data: data)),
    );
  }
}
