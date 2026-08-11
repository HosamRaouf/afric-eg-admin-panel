import 'package:afric_eg_admin_panel/features/workshops/domain/repositories/workshop_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_event.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkshopBloc extends Bloc<WorkshopEvent, WorkshopState> {
  final WorkshopAdminRepository _repository;

  WorkshopBloc({required WorkshopAdminRepository repository})
    : _repository = repository,
      super(const WorkshopState()) {
    on<LoadWorkshopsEvent>(_onLoad);
    on<SaveWorkshopEvent>(_onSave);
    on<DeleteWorkshopEvent>(_onDelete);
    on<LoadWorkshopSessionsEvent>(_onLoadSessions);
    on<SaveWorkshopSessionEvent>(_onSaveSession);
    on<DeleteWorkshopSessionEvent>(_onDeleteSession);
  }

  Future<void> _onLoad(
    LoadWorkshopsEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.getWorkshops();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (list) =>
          emit(state.copyWith(isLoading: false, workshops: list, error: null)),
    );
  }

  Future<void> _onSave(
    SaveWorkshopEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = event.isNew
        ? await _repository.add(event.workshop)
        : await _repository.update(event.workshop);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) {
        emit(state.copyWith(isSaving: false, error: null));
        add(const LoadWorkshopsEvent());
      },
    );
  }

  Future<void> _onDelete(
    DeleteWorkshopEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = await _repository.delete(event.id);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) {
        emit(state.copyWith(isSaving: false, error: null));
        add(const LoadWorkshopsEvent());
      },
    );
  }

  Future<void> _onLoadSessions(
    LoadWorkshopSessionsEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(state.copyWith(selectedWorkshopId: event.workshopId, isLoading: true));
    final result = await _repository.getSessions(event.workshopId);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (list) =>
          emit(state.copyWith(isLoading: false, sessions: list, error: null)),
    );
  }

  Future<void> _onSaveSession(
    SaveWorkshopSessionEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = event.isNew
        ? await _repository.addSession(event.workshopId, event.session)
        : await _repository.updateSession(event.workshopId, event.session);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) {
        emit(state.copyWith(isSaving: false, error: null));
        add(LoadWorkshopSessionsEvent(event.workshopId));
      },
    );
  }

  Future<void> _onDeleteSession(
    DeleteWorkshopSessionEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = await _repository.deleteSession(event.workshopId, event.id);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) {
        emit(state.copyWith(isSaving: false, error: null));
        add(LoadWorkshopSessionsEvent(event.workshopId));
      },
    );
  }
}
