import 'package:afric_eg_admin_panel/features/announcements/domain/entities/announcement.dart';
import 'package:equatable/equatable.dart';

class AnnouncementState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<Announcement> announcements;
  final String? error;

  const AnnouncementState({
    this.isLoading = false,
    this.isSaving = false,
    this.announcements = const [],
    this.error,
  });

  AnnouncementState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<Announcement>? announcements,
    String? error,
  }) =>
      AnnouncementState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        announcements: announcements ?? this.announcements,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [isLoading, isSaving, announcements, error];
}
