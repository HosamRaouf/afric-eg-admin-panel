import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop_session.dart';
import 'package:equatable/equatable.dart';

class WorkshopState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<Workshop> workshops;
  final String? selectedWorkshopId;
  final List<WorkshopSession> sessions;
  final String? error;

  const WorkshopState({
    this.isLoading = false,
    this.isSaving = false,
    this.workshops = const [],
    this.selectedWorkshopId,
    this.sessions = const [],
    this.error,
  });

  WorkshopState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<Workshop>? workshops,
    String? selectedWorkshopId,
    List<WorkshopSession>? sessions,
    String? error,
  }) =>
      WorkshopState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        workshops: workshops ?? this.workshops,
        selectedWorkshopId: selectedWorkshopId ?? this.selectedWorkshopId,
        sessions: sessions ?? this.sessions,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [isLoading, isSaving, workshops, selectedWorkshopId, sessions, error];
}
