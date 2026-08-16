import 'package:afric_eg_admin_panel/features/agenda/data/repositories/speaker_talk_sync.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/repositories/agenda_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_event.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  final AgendaAdminRepository _repository;
  final SpeakerTalkSync _speakerTalkSync;

  /// Day key -> its sessions, fetched once so selecting a previously viewed
  /// day (or re-navigating to the page) serves the cached list instead of
  /// re-reading `agenda/{dayKey}/sessions`.
  final Map<String, List<AgendaItem>> _itemsByDay = {};

  AgendaBloc({
    required AgendaAdminRepository repository,
    required SpeakerTalkSync speakerTalkSync,
  }) : _repository = repository,
       _speakerTalkSync = speakerTalkSync,
       super(const AgendaState()) {
    on<LoadAgendaEvent>(_onLoad);
    on<SelectDayEvent>(_onSelectDay);
    on<LoadAgendaItemsEvent>(_onLoadItems);
    on<SaveAgendaItemEvent>(_onSaveItem);
    on<DeleteAgendaItemEvent>(_onDeleteItem);
  }

  Future<void> _onLoad(LoadAgendaEvent event, Emitter<AgendaState> emit) async {
    if (state.days.isNotEmpty && !event.force) return;
    emit(state.copyWith(isLoading: true, error: null));
    final daysResult = await _repository.getDays();
    if (isClosed) return;
    final daysFailure = daysResult.fold<String?>((f) => f.message, (_) => null);
    final datesResult = await _repository.getEventDates();
    if (isClosed) return;
    final datesFailure = datesResult.fold<String?>(
      (f) => f.message,
      (_) => null,
    );
    final failure = daysFailure ?? datesFailure;
    if (failure != null) {
      emit(state.copyWith(isLoading: false, error: failure));
      return;
    }
    final days = daysResult.fold<List<AgendaDay>>((_) => const [], (d) => d);
    final eventDates = datesResult.fold<List<DateTime>>(
      (_) => const [],
      (d) => d,
    );
    final firstKey = days.isNotEmpty ? days.first.key : null;
    final selected = state.selectedDayKey;
    final nextKey = selected != null && days.any((d) => d.key == selected)
        ? selected
        : firstKey;
    emit(
      state.copyWith(
        isLoading: false,
        days: days,
        eventDates: eventDates,
        selectedDayKey: nextKey,
      ),
    );
    if (nextKey != null && (state.items.isEmpty || nextKey != selected)) {
      add(LoadAgendaItemsEvent(nextKey));
    }
  }

  Future<void> _onSelectDay(
    SelectDayEvent event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(selectedDayKey: event.dayKey));
    add(LoadAgendaItemsEvent(event.dayKey));
  }

  Future<void> _onLoadItems(
    LoadAgendaItemsEvent event,
    Emitter<AgendaState> emit,
  ) async {
    final cached = _itemsByDay[event.dayKey];
    if (cached != null) {
      emit(state.copyWith(isLoading: false, items: cached, error: null));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.getItems(event.dayKey);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (items) {
        _itemsByDay[event.dayKey] = items;
        emit(state.copyWith(isLoading: false, items: items));
      },
    );
  }

  Future<void> _onSaveItem(
    SaveAgendaItemEvent event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null));
    final previous = event.isNew ? null : _findItem(state.items, event.item.id);
    final result = event.isNew
        ? await _repository.addItem(event.dayKey, event.item)
        : await _repository.updateItem(event.dayKey, event.item);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) async {
        final current = _itemsByDay[event.dayKey] ?? state.items;
        final items = event.isNew
            ? [...current, event.item]
            : [
                for (final i in current)
                  if (i.id == event.item.id) event.item else i,
              ];
        final sorted = _sortedItems(items);
        _itemsByDay[event.dayKey] = sorted;
        emit(state.copyWith(isSaving: false, error: null, items: sorted));
        await _syncSpeakerTalks(
          dayKey: event.dayKey,
          previous: previous,
          next: event.item,
        );
      },
    );
  }

  Future<void> _onDeleteItem(
    DeleteAgendaItemEvent event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, error: null));
    final item = _findItem(state.items, event.id);
    final result = await _repository.deleteItem(event.dayKey, event.id);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) async {
        final current = _itemsByDay[event.dayKey] ?? state.items;
        final items = [
          for (final i in current)
            if (i.id != event.id) i,
        ];
        _itemsByDay[event.dayKey] = items;
        emit(state.copyWith(isSaving: false, error: null, items: items));
        if (item != null) {
          try {
            await _speakerTalkSync.removeTalks(item);
          } catch (e) {
            // Speaker index cleanup must not surface as a failed delete; the
            // session itself is already gone.
            debugPrint('SpeakerTalkSync.removeTalks failed: $e');
          }
        }
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
        dayKey: dayKey,
        previous: previous,
        next: next,
      );
    } catch (e) {
      debugPrint('SpeakerTalkSync.syncTalks failed: $e');
    }
  }

  /// Mirrors the datasource ordering (`startTime`) so an in-place item update
  /// keeps the same order a fresh read would have returned.
  static List<AgendaItem> _sortedItems(List<AgendaItem> items) {
    final list = List<AgendaItem>.from(items)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  static AgendaItem? _findItem(List<AgendaItem> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
