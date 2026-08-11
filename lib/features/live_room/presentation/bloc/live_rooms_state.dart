import 'package:afric_eg_admin_panel/features/live_room/domain/entities/room.dart';
import 'package:equatable/equatable.dart';

class LiveRoomsState extends Equatable {
  final bool isLoading;
  final List<Room> rooms;
  final String? error;

  const LiveRoomsState({
    this.isLoading = false,
    this.rooms = const [],
    this.error,
  });

  LiveRoomsState copyWith({
    bool? isLoading,
    List<Room>? rooms,
    String? error,
  }) =>
      LiveRoomsState(
        isLoading: isLoading ?? this.isLoading,
        rooms: rooms ?? this.rooms,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [isLoading, rooms, error];
}
