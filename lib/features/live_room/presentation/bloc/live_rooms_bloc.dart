import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/room.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/repositories/live_room_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_event.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiveRoomsBloc extends Bloc<LiveRoomsEvent, LiveRoomsState> {
  final LiveRoomAdminRepository _repository;

  LiveRoomsBloc({required LiveRoomAdminRepository repository})
      : _repository = repository,
        super(const LiveRoomsState()) {
    on<LoadLiveRoomsEvent>(_onLoad);
    on<ToggleTalkLiveEvent>(_onToggleTalkLive);
  }

  Future<void> _onLoad(
      LoadLiveRoomsEvent event, Emitter<LiveRoomsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.getRooms();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (rooms) => emit(state.copyWith(isLoading: false, rooms: rooms)),
    );
  }

  Future<void> _onToggleTalkLive(
      ToggleTalkLiveEvent event, Emitter<LiveRoomsState> emit) async {
    emit(state.copyWith(
      rooms: state.rooms
          .map((r) =>
              r.id == event.room.id ? _withTalk(r, event.talk, event.isLive) : r)
          .toList(),
      error: null,
    ));
    final result = await _repository.setTalkLive(
      event.room.dayKey,
      event.room.id,
      event.talk.id,
      event.isLive,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        // Revert the optimistic flip so a talk can't get stuck showing live
        // when the write did not reach Firestore.
        rooms: state.rooms
            .map((r) =>
                r.id == event.room.id ? _withTalk(r, event.talk, !event.isLive) : r)
            .toList(),
        error: failure.message,
      )),
      (_) {},
    );
  }

  /// Replaces the room's talks with the target talk's live flag applied,
  /// mirroring the datasource rule: marking a talk live clears the others.
  Room _withTalk(Room room, Talk talk, bool isLive) => Room(
        id: room.id,
        dayKey: room.dayKey,
        day: room.day,
        hall: room.hall,
        title: room.title,
        startTime: room.startTime,
        endTime: room.endTime,
        talks: room.talks
            .map((t) => t.id == talk.id
                ? t.copyWith(status: isLive ? 'live' : 'upcoming')
                : (isLive && t.status == 'live'
                    ? t.copyWith(status: 'upcoming')
                    : t))
            .toList(),
      );
}
