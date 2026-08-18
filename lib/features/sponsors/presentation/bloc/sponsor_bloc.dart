import 'package:afric_eg_admin_panel/features/sponsors/presentation/bloc/sponsor_event.dart';
import 'package:afric_eg_admin_panel/features/sponsors/presentation/bloc/sponsor_state.dart';
import 'package:afric_eg_admin_panel/features/sponsors/domain/repositories/sponsor_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SponsorBloc extends Bloc<SponsorEvent, SponsorState> {
  final SponsorRepository _repository;

  SponsorBloc({required SponsorRepository repository})
      : _repository = repository,
        super(const SponsorState()) {
    on<LoadSponsorsEvent>(_onLoad);
    on<SaveSponsorEvent>(_onSave);
    on<DeleteSponsorEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadSponsorsEvent event, Emitter<SponsorState> emit) async {
    if (state.sponsors.isNotEmpty) return;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final result = await _repository.getSponsors();
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isLoading: false, error: failure.message)),
        (list) => emit(state.copyWith(isLoading: false, sponsors: list)),
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: _describe(e, st)));
    }
  }

  Future<void> _onSave(
      SaveSponsorEvent event, Emitter<SponsorState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final result = event.isNew
          ? await _repository.add(event.sponsor)
          : await _repository.update(event.sponsor);
      if (isClosed) return;
      result.fold(
        (failure) =>
            emit(state.copyWith(isSaving: false, error: failure.message)),
        (_) {
          final current = state.sponsors;
          final sponsors = event.isNew
              ? [...current, event.sponsor]
              : [
                  for (final s in current)
                    if (s.id == event.sponsor.id) event.sponsor else s,
                ];
          emit(state.copyWith(
            isSaving: false,
            error: null,
            sponsors: sponsors,
          ));
        },
      );
    } catch (e, st) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: _describe(e, st)));
    }
  }

  Future<void> _onDelete(
      DeleteSponsorEvent event, Emitter<SponsorState> emit) async {
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
          sponsors: [
            for (final s in state.sponsors)
              if (s.id != event.id) s,
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
