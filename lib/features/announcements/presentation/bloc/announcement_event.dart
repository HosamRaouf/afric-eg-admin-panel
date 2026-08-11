import 'package:afric_eg_admin_panel/features/announcements/domain/entities/announcement.dart';
import 'package:equatable/equatable.dart';

abstract class AnnouncementEvent extends Equatable {
  const AnnouncementEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnnouncementsEvent extends AnnouncementEvent {
  const LoadAnnouncementsEvent();
}

class SaveAnnouncementEvent extends AnnouncementEvent {
  final Announcement announcement;
  final bool isNew;
  const SaveAnnouncementEvent(this.announcement, {this.isNew = false});

  @override
  List<Object?> get props => [announcement, isNew];
}

class DeleteAnnouncementEvent extends AnnouncementEvent {
  final String id;
  const DeleteAnnouncementEvent(this.id);

  @override
  List<Object?> get props => [id];
}
