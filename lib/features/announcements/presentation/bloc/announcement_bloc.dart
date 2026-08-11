import 'package:afric_eg_admin_panel/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/bloc/announcement_event.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/bloc/announcement_state.dart';
import 'package:afric_eg_admin_panel/features/push/domain/repositories/push_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  final AnnouncementRepository _repository;
  final PushRepository _pushRepository;

  AnnouncementBloc({
    required AnnouncementRepository repository,
    required PushRepository pushRepository,
  })  : _repository = repository,
        _pushRepository = pushRepository,
        super(const AnnouncementState()) {
    on<LoadAnnouncementsEvent>(_onLoad);
    on<SaveAnnouncementEvent>(_onSave);
    on<DeleteAnnouncementEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadAnnouncementsEvent event, Emitter<AnnouncementState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final result = await _repository.getAnnouncements();
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isLoading: false, error: failure.message)),
        (list) => emit(state.copyWith(isLoading: false, announcements: list)),
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: _describe(e, st)));
    }
  }

  Future<void> _onSave(
      SaveAnnouncementEvent event, Emitter<AnnouncementState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final result = event.isNew
          ? await _repository.add(event.announcement)
          : await _repository.update(event.announcement);
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isSaving: false, error: failure.message)),
        (_) {
          if (event.isNew) {
            _pushRepository.sendToAll(
              title: event.announcement.title,
              message: event.announcement.preview,
            );
          }
          emit(state.copyWith(isSaving: false, error: null));
          add(const LoadAnnouncementsEvent());
        },
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: _describe(e, st)));
    }
  }

  Future<void> _onDelete(
      DeleteAnnouncementEvent event, Emitter<AnnouncementState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final result = await _repository.delete(event.id);
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isSaving: false, error: failure.message)),
        (_) {
          emit(state.copyWith(isSaving: false, error: null));
          add(const LoadAnnouncementsEvent());
        },
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
