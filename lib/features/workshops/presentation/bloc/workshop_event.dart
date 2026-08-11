import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop_session.dart';
import 'package:equatable/equatable.dart';

abstract class WorkshopEvent extends Equatable {
  const WorkshopEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkshopsEvent extends WorkshopEvent {
  const LoadWorkshopsEvent();
}

class SaveWorkshopEvent extends WorkshopEvent {
  final Workshop workshop;
  final bool isNew;
  const SaveWorkshopEvent(this.workshop, {this.isNew = false});

  @override
  List<Object?> get props => [workshop, isNew];
}

class DeleteWorkshopEvent extends WorkshopEvent {
  final String id;
  const DeleteWorkshopEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadWorkshopSessionsEvent extends WorkshopEvent {
  final String workshopId;
  const LoadWorkshopSessionsEvent(this.workshopId);

  @override
  List<Object?> get props => [workshopId];
}

class SaveWorkshopSessionEvent extends WorkshopEvent {
  final String workshopId;
  final WorkshopSession session;
  final bool isNew;
  const SaveWorkshopSessionEvent(this.workshopId, this.session,
      {this.isNew = false});

  @override
  List<Object?> get props => [workshopId, session, isNew];
}

class DeleteWorkshopSessionEvent extends WorkshopEvent {
  final String workshopId;
  final String id;
  const DeleteWorkshopSessionEvent(this.workshopId, this.id);

  @override
  List<Object?> get props => [workshopId, id];
}
