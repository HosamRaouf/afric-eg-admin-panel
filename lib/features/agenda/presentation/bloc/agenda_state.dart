import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:equatable/equatable.dart';

class AgendaState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<AgendaDay> days;
  final String? selectedDayKey;
  final List<AgendaItem> items;

  /// One date per congress day (`config/congress.eventDates`), used to show a
  /// calendar date on each day chip and to resolve session timestamps.
  final List<DateTime> eventDates;
  final String? error;

  const AgendaState({
    this.isLoading = false,
    this.isSaving = false,
    this.days = const [],
    this.selectedDayKey,
    this.items = const [],
    this.eventDates = const [],
    this.error,
  });

  AgendaState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<AgendaDay>? days,
    String? selectedDayKey,
    List<AgendaItem>? items,
    List<DateTime>? eventDates,
    String? error,
  }) => AgendaState(
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    days: days ?? this.days,
    selectedDayKey: selectedDayKey ?? this.selectedDayKey,
    items: items ?? this.items,
    eventDates: eventDates ?? this.eventDates,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    days,
    selectedDayKey,
    items,
    eventDates,
    error,
  ];
}
