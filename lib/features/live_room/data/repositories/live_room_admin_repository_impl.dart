import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/hand_raise.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/room.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/repositories/live_room_admin_repository.dart';
import 'package:dartz/dartz.dart';

class LiveRoomAdminRepositoryImpl implements LiveRoomAdminRepository {
  final AdminDataSource _dataSource;

  LiveRoomAdminRepositoryImpl(this._dataSource);

  @override
  FutureResult<List<Room>> getRooms() async {
    try {
      final blocks = await _dataSource.listSessionBlocks();
      return Right(_roomsFrom(blocks));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  StreamResult<List<Room>> watchRooms() async* {
    try {
      yield* _dataSource
          .watchSessionBlocks()
          .map((blocks) => Right(_roomsFrom(blocks)));
    } catch (e) {
      yield Left(ServerFailure(message: e.toString()));
    }
  }

  List<Room> _roomsFrom(List<(AgendaDay, AgendaItem)> blocks) {
    return blocks
        .map((b) => Room(
              id: b.$2.id,
              dayKey: b.$1.key,
              day: b.$1.day,
              hall: b.$1.hall,
              title: b.$2.title,
              startTime: b.$2.startTime,
              endTime: b.$2.endTime,
              talks: b.$2.talks,
            ))
        .toList();
  }

  @override
  FutureResult<void> setTalkLive(
      String dayKey, String sessionId, String talkId, bool isLive) async {
    try {
      await _dataSource.setTalkLive(dayKey, sessionId, talkId, isLive);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> setTalkStatus(
      String dayKey, String sessionId, String talkId, String status) async {
    try {
      await _dataSource.setTalkStatus(dayKey, sessionId, talkId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<String?> findSessionPath(String sessionId) async {
    try {
      return Right(await _dataSource.findSessionPath(sessionId));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<Map<String, dynamic>?> getSessionDetails(String path) async {
    try {
      return Right(await _dataSource.getSessionDetails(path));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  StreamResult<List<Question>> watchQuestions(String path) async* {
    try {
      yield* _dataSource.watchLiveQuestions(path).map((list) {
        final sorted = List<Question>.from(list)
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
            return b.votes.compareTo(a.votes);
          });
        return Right(sorted);
      });
    } catch (e) {
      yield Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  StreamResult<List<HandRaise>> watchHandRaises(String path) async* {
    try {
      yield* _dataSource.watchHandRaises(path).map(Right.new);
    } catch (e) {
      yield Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> updateQuestion(String path, Question question) async {
    try {
      await _dataSource.updateLiveQuestion(path, question);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> deleteQuestion(String path, String id) async {
    try {
      await _dataSource.deleteLiveQuestion(path, id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> lowerHand(String path, String uid) async {
    try {
      await _dataSource.lowerHand(path, uid);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureResult<void> clearRaisedHands(String path) async {
    try {
      await _dataSource.clearRaisedHands(path);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
