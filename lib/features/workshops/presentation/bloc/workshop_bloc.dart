import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop_session.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/repositories/workshop_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_event.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkshopBloc extends Bloc<WorkshopEvent, WorkshopState> {
  final WorkshopAdminRepository _repository;

  /// Workshop id -> its sessions, fetched once so selecting a previously
  /// opened workshop (or re-navigating to the page) serves the cached list
  /// instead of re-reading `workshops/{id}/sessions`.
  final Map<String, List<WorkshopSession>> _sessionsByWorkshop = {};

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
    if (state.workshops.isNotEmpty) return;
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
        final current = state.workshops;
        final workshops = event.isNew
            ? [...current, event.workshop]
            : [
                for (final w in current)
                  if (w.id == event.workshop.id) event.workshop else w,
              ];
        emit(state.copyWith(
          isSaving: false,
          error: null,
          workshops: workshops,
        ));
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
      (_) => emit(state.copyWith(
        isSaving: false,
        error: null,
        workshops: [
          for (final w in state.workshops)
            if (w.id != event.id) w,
        ],
      )),
    );
  }

  Future<void> _onLoadSessions(
    LoadWorkshopSessionsEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    final cached = _sessionsByWorkshop[event.workshopId];
    if (cached != null) {
      emit(state.copyWith(
        selectedWorkshopId: event.workshopId,
        isLoading: false,
        sessions: cached,
        error: null,
      ));
      return;
    }
    emit(state.copyWith(
      selectedWorkshopId: event.workshopId,
      isLoading: true,
    ));
    final result = await _repository.getSessions(event.workshopId);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (list) {
        _sessionsByWorkshop[event.workshopId] = list;
        emit(state.copyWith(isLoading: false, sessions: list, error: null));
      },
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
        final current = _sessionsByWorkshop[event.workshopId] ?? state.sessions;
        final sessions = event.isNew
            ? [...current, event.session]
            : [
                for (final s in current)
                  if (s.id == event.session.id) event.session else s,
              ];
        final sorted = _sortedSessions(sessions);
        _sessionsByWorkshop[event.workshopId] = sorted;
        emit(state.copyWith(
          isSaving: false,
          error: null,
          sessions: sorted,
        ));
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
        final current = _sessionsByWorkshop[event.workshopId] ?? state.sessions;
        final sessions = [
          for (final s in current)
            if (s.id != event.id) s,
        ];
        _sessionsByWorkshop[event.workshopId] = sessions;
        emit(state.copyWith(
          isSaving: false,
          error: null,
          sessions: sessions,
        ));
      },
    );
  }

  /// Mirrors the datasource ordering (`startTime`) so an in-place session
  /// update keeps the same order a fresh read would have returned.
  static List<WorkshopSession> _sortedSessions(List<WorkshopSession> sessions) {
    final list = List<WorkshopSession>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }
}
