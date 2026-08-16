import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/room.dart';
import 'package:equatable/equatable.dart';

abstract class LiveRoomsEvent extends Equatable {
  const LiveRoomsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLiveRoomsEvent extends LiveRoomsEvent {
  const LoadLiveRoomsEvent();
}

class ToggleTalkLiveEvent extends LiveRoomsEvent {
  final Room room;
  final Talk talk;
  final bool isLive;
  const ToggleTalkLiveEvent({
    required this.room,
    required this.talk,
    required this.isLive,
  });

  @override
  List<Object?> get props => [room, talk, isLive];
}

class SetTalkStatusEvent extends LiveRoomsEvent {
  final Room room;
  final Talk talk;
  final String status;
  const SetTalkStatusEvent({
    required this.room,
    required this.talk,
    required this.status,
  });

  @override
  List<Object?> get props => [room, talk, status];
}

