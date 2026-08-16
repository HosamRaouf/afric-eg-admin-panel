import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:equatable/equatable.dart';

abstract class AgendaEvent extends Equatable {
  const AgendaEvent();

  @override
  List<Object?> get props => [];
}

class LoadAgendaEvent extends AgendaEvent {
  /// When true, re-fetches the day list even if already loaded. Used after the
  /// congress config saves day changes so the agenda reflects them in place.
  final bool force;
  const LoadAgendaEvent({this.force = false});

  @override
  List<Object?> get props => [force];
}

class SelectDayEvent extends AgendaEvent {
  final String dayKey;
  const SelectDayEvent(this.dayKey);

  @override
  List<Object?> get props => [dayKey];
}

class LoadAgendaItemsEvent extends AgendaEvent {
  final String dayKey;
  const LoadAgendaItemsEvent(this.dayKey);

  @override
  List<Object?> get props => [dayKey];
}

class SaveAgendaItemEvent extends AgendaEvent {
  final String dayKey;
  final AgendaItem item;
  final bool isNew;
  const SaveAgendaItemEvent(this.dayKey, this.item, {this.isNew = false});

  @override
  List<Object?> get props => [dayKey, item, isNew];
}

class DeleteAgendaItemEvent extends AgendaEvent {
  final String dayKey;
  final String id;
  const DeleteAgendaItemEvent(this.dayKey, this.id);

  @override
  List<Object?> get props => [dayKey, id];
}
