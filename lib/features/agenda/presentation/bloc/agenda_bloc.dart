import 'package:afric_eg_admin_panel/features/agenda/data/repositories/speaker_talk_sync.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/repositories/agenda_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_event.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  final AgendaAdminRepository _repository;
  final SpeakerTalkSync _speakerTalkSync;

  AgendaBloc({
    required AgendaAdminRepository repository,
    required SpeakerTalkSync speakerTalkSync,
  })  : _repository = repository,
        _speakerTalkSync = speakerTalkSync,
        super(const AgendaState()) {
    on<LoadAgendaEvent>(_onLoad);
    on<SelectDayEvent>(_onSelectDay);
    on<LoadAgendaItemsEvent>(_onLoadItems);
    on<SaveAgendaItemEvent>(_onSaveItem);
    on<DeleteAgendaItemEvent>(_onDeleteItem);
  }

  Future<void> _onLoad(
      LoadAgendaEvent event, Emitter<AgendaState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.getDays();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (days) {
        final firstKey = days.isNotEmpty ? days.first.key : null;
        emit(state.copyWith(
          isLoading: false,
          days: days,
          selectedDayKey: state.selectedDayKey ?? firstKey,
        ));
        if (state.selectedDayKey == null && firstKey != null) {
          add(LoadAgendaItemsEvent(firstKey));
        }
      },
    );
  }

  Future<void> _onSelectDay(
      SelectDayEvent event, Emitter<AgendaState> emit) async {
    emit(state.copyWith(selectedDayKey: event.dayKey));
    add(LoadAgendaItemsEvent(event.dayKey));
  }

  Future<void> _onLoadItems(
      LoadAgendaItemsEvent event, Emitter<AgendaState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.getItems(event.dayKey);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (items) => emit(state.copyWith(isLoading: false, items: items)),
    );
  }

  Future<void> _onSaveItem(
      SaveAgendaItemEvent event, Emitter<AgendaState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final previous =
        event.isNew ? null : _findItem(state.items, event.item.id);
    final result = event.isNew
        ? await _repository.addItem(event.dayKey, event.item)
        : await _repository.updateItem(event.dayKey, event.item);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) async {
        await _syncSpeakerTalks(
            dayKey: event.dayKey, previous: previous, next: event.item);
        add(LoadAgendaItemsEvent(event.dayKey));
      },
    );
  }

  Future<void> _onDeleteItem(
      DeleteAgendaItemEvent event, Emitter<AgendaState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final item = _findItem(state.items, event.id);
    final result = await _repository.deleteItem(event.dayKey, event.id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) async {
        if (item != null) {
          try {
            await _speakerTalkSync.removeTalks(item);
          } catch (e) {
            // Speaker index cleanup must not surface as a failed delete; the
            // session itself is already gone.
            debugPrint('SpeakerTalkSync.removeTalks failed: $e');
          }
        }
        add(LoadAgendaItemsEvent(event.dayKey));
      },
    );
  }

  /// Keeps the per-speaker `talks` subcollection aligned with a saved session.
  /// Failures here are non-fatal: the session save already succeeded, so the
  /// index is retried lazily by the next save instead of blocking the UI.
  Future<void> _syncSpeakerTalks({
    required String dayKey,
    required AgendaItem? previous,
    required AgendaItem next,
  }) async {
    try {
      await _speakerTalkSync.syncTalks(
          dayKey: dayKey, previous: previous, next: next);
    } catch (e) {
      debugPrint('SpeakerTalkSync.syncTalks failed: $e');
    }
  }

  static AgendaItem? _findItem(List<AgendaItem> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
