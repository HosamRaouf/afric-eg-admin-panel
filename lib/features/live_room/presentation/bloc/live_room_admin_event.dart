import 'package:afric_eg_admin_panel/features/live_room/domain/entities/hand_raise.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:equatable/equatable.dart';

abstract class LiveRoomAdminEvent extends Equatable {
  const LiveRoomAdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadLiveRoomAdminEvent extends LiveRoomAdminEvent {
  const LoadLiveRoomAdminEvent();
}

class QuestionsUpdatedEvent extends LiveRoomAdminEvent {
  final List<Question> questions;
  const QuestionsUpdatedEvent(this.questions);

  @override
  List<Object?> get props => [questions];
}

class HandRaisesUpdatedEvent extends LiveRoomAdminEvent {
  final List<HandRaise> handRaises;
  const HandRaisesUpdatedEvent(this.handRaises);

  @override
  List<Object?> get props => [handRaises];
}

class StreamErrorEvent extends LiveRoomAdminEvent {
  final String message;
  const StreamErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class PinQuestionEvent extends LiveRoomAdminEvent {
  final Question question;
  final bool pinned;
  const PinQuestionEvent(this.question, this.pinned);

  @override
  List<Object?> get props => [question, pinned];
}

class AnswerQuestionEvent extends LiveRoomAdminEvent {
  final Question question;
  final String answer;
  const AnswerQuestionEvent(this.question, this.answer);

  @override
  List<Object?> get props => [question, answer];
}

class RemoveAnswerQuestionEvent extends LiveRoomAdminEvent {
  final Question question;
  const RemoveAnswerQuestionEvent(this.question);

  @override
  List<Object?> get props => [question];
}

class DeleteLiveQuestionEvent extends LiveRoomAdminEvent {
  final String id;
  const DeleteLiveQuestionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LowerHandEvent extends LiveRoomAdminEvent {
  final String uid;
  const LowerHandEvent(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ClearRaisedHandsEvent extends LiveRoomAdminEvent {
  const ClearRaisedHandsEvent();
}

class ToggleRoomLiveEvent extends LiveRoomAdminEvent {
  final bool isLive;
  const ToggleRoomLiveEvent({required this.isLive});

  @override
  List<Object?> get props => [isLive];
}
