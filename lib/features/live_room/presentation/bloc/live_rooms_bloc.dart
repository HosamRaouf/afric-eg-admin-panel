import 'dart:async';

import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/room.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/repositories/live_room_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_event.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_state.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiveRoomsBloc extends Bloc<LiveRoomsEvent, LiveRoomsState> {
  final LiveRoomAdminRepository _repository;

  LiveRoomsBloc({required LiveRoomAdminRepository repository})
      : _repository = repository,
        super(const LiveRoomsState()) {
    // `restartable` lets pull-to-refresh cancel the previous handler (and its
    // room stream) instead of stacking a second Firestore listener.
    on<LoadLiveRoomsEvent>(_onLoad, transformer: restartable());
    on<ToggleTalkLiveEvent>(_onToggleTalkLive);
    on<SetTalkStatusEvent>(_onSetTalkStatus);
  }

  Future<void> _onLoad(
      LoadLiveRoomsEvent event, Emitter<LiveRoomsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    // `emit.forEach` keeps the event handler pending for as long as the room
    // stream is active, so real-time emits are legal under bloc 8 (a plain
    // `listen` + `emit` after the handler returns asserts). The subscription
    // is cancelled automatically when a new LoadLiveRoomsEvent restarts the
    // handler or when the bloc is closed.
    await emit.forEach<Either<Failure, List<Room>>>(
      _repository.watchRooms(),
      onData: (result) => result.fold(
        (failure) =>
            state.copyWith(isLoading: false, error: failure.message),
        (rooms) => state.copyWith(isLoading: false, rooms: rooms),
      ),
      onError: (Object error, StackTrace stackTrace) =>
          state.copyWith(isLoading: false, error: error.toString()),
    );
  }

  Future<void> _onToggleTalkLive(
      ToggleTalkLiveEvent event, Emitter<LiveRoomsState> emit) async {
    final status = event.isLive ? 'live' : 'completed';
    emit(state.copyWith(
      rooms: state.rooms
          .map((r) =>
              r.id == event.room.id ? _withTalk(r, event.talk, status) : r)
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
            .map((r) => r.id == event.room.id
                ? _withTalk(r, event.talk, event.isLive ? 'completed' : 'live')
                : r)
            .toList(),
        error: failure.message,
      )),
      (_) {},
    );
  }

  Future<void> _onSetTalkStatus(
      SetTalkStatusEvent event, Emitter<LiveRoomsState> emit) async {
    emit(state.copyWith(
      rooms: state.rooms
          .map((r) =>
              r.id == event.room.id ? _withTalk(r, event.talk, event.status) : r)
          .toList(),
      error: null,
    ));
    final result = await _repository.setTalkStatus(
      event.room.dayKey,
      event.room.id,
      event.talk.id,
      event.status,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        // Revert the optimistic change if the write did not reach Firestore.
        rooms: state.rooms
            .map((r) => r.id == event.room.id
                ? _withTalk(r, event.talk, event.talk.status)
                : r)
            .toList(),
        error: failure.message,
      )),
      (_) {},
    );
  }

  /// Replaces the room's talks with the target talk's [status] applied,
  /// mirroring the datasource rule: only the target talk's status changes, so
  /// the parallel talks in a session can each hold their own state.
  Room _withTalk(Room room, Talk talk, String status) => Room(
        id: room.id,
        dayKey: room.dayKey,
        day: room.day,
        hall: room.hall,
        title: room.title,
        startTime: room.startTime,
        endTime: room.endTime,
        talks: room.talks
            .map((t) => t.id == talk.id ? t.copyWith(status: status) : t)
            .toList(),
      );
}
