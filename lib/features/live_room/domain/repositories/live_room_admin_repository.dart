import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/hand_raise.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/room.dart';

abstract class LiveRoomAdminRepository {
  FutureResult<List<Room>> getRooms();
  StreamResult<List<Room>> watchRooms();
  FutureResult<void> setTalkLive(
      String dayKey, String sessionId, String talkId, bool isLive);
  FutureResult<void> setTalkStatus(
      String dayKey, String sessionId, String talkId, String status);
  FutureResult<String?> findSessionPath(String sessionId);
  FutureResult<Map<String, dynamic>?> getSessionDetails(String path);
  StreamResult<List<Question>> watchQuestions(String path);
  StreamResult<List<HandRaise>> watchHandRaises(String path);
  FutureResult<void> updateQuestion(String path, Question question);
  FutureResult<void> deleteQuestion(String path, String id);
  FutureResult<void> lowerHand(String path, String uid);
  FutureResult<void> clearRaisedHands(String path);
}
