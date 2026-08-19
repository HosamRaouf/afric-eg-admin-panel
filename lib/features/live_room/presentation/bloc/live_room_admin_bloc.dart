import 'dart:async';

import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/repositories/live_room_admin_repository.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_room_admin_event.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_room_admin_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Moderates one room in real time. The room is scoped to a single talk of a
/// session: questions and raised hands are streamed live from the talk's
/// `live_room`/`hand_raises` subcollections and mutations update the UI
/// through those streams.
class LiveRoomAdminBloc
    extends Bloc<LiveRoomAdminEvent, LiveRoomAdminState> {
  final LiveRoomAdminRepository _repository;
  final String sessionId;
  final String? talkId;

  StreamSubscription? _questionsSub;
  StreamSubscription? _handsSub;
  String? _sessionPath;

  LiveRoomAdminBloc({
    required LiveRoomAdminRepository repository,
    required this.sessionId,
    this.talkId,
  })  : _repository = repository,
        super(const LiveRoomAdminState()) {
    on<LoadLiveRoomAdminEvent>(_onLoad);
    on<QuestionsUpdatedEvent>(_onQuestionsUpdated);
    on<HandRaisesUpdatedEvent>(_onHandRaisesUpdated);
    on<StreamErrorEvent>((event, emit) => emit(state.copyWith(error: event.message)));
    on<PinQuestionEvent>(_onPin);
    on<AnswerQuestionEvent>(_onAnswer);
    on<RemoveAnswerQuestionEvent>(_onRemoveAnswer);
    on<DeleteLiveQuestionEvent>(_onDelete);
    on<LowerHandEvent>(_onLowerHand);
    on<ClearRaisedHandsEvent>(_onClearHands);
    on<ToggleRoomLiveEvent>(_onToggleRoomLive);
  }

  /// Base path for Q&A and the mic queue. With a `talkId` this points at the
  /// talk's subcollections; without one (legacy route) it falls back to the
  /// session-level ones.
  String? get _roomPath => _sessionPath == null
      ? null
      : talkId == null
          ? _sessionPath
          : '$_sessionPath/talks/$talkId';

  Future<void> _onLoad(
      LoadLiveRoomAdminEvent event, Emitter<LiveRoomAdminState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    final pathResult = await _repository.findSessionPath(sessionId);
    if (isClosed) return;
    final path = pathResult.fold((_) => null, (value) => value);
    if (path == null) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Session "$sessionId" not found in the agenda.',
      ));
      return;
    }
    _sessionPath = path;

    final detailsResult = await _repository.getSessionDetails(path);
    if (isClosed) return;
    emit(state.copyWith(
      isLoading: false,
      session: detailsResult.fold((_) => state.session, (value) => value),
      error: detailsResult.fold((failure) => failure.message, (_) => null),
    ));

    final roomPath = _roomPath;
    if (roomPath == null) return;

    await _questionsSub?.cancel();
    _questionsSub = _repository.watchQuestions(roomPath).listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => add(StreamErrorEvent(failure.message)),
          (questions) => add(QuestionsUpdatedEvent(questions)),
        );
      },
    );

    await _handsSub?.cancel();
    _handsSub = _repository.watchHandRaises(roomPath).listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => add(StreamErrorEvent(failure.message)),
          (hands) => add(HandRaisesUpdatedEvent(hands)),
        );
      },
    );
  }

  void _onQuestionsUpdated(
      QuestionsUpdatedEvent event, Emitter<LiveRoomAdminState> emit) {
    emit(state.copyWith(questions: event.questions));
  }

  void _onHandRaisesUpdated(
      HandRaisesUpdatedEvent event, Emitter<LiveRoomAdminState> emit) {
    emit(state.copyWith(handRaises: event.handRaises));
  }

  Future<void> _onPin(
      PinQuestionEvent event, Emitter<LiveRoomAdminState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final path = _roomPath;
    if (path == null) return;
    final updated = event.question.copyWith(isPinned: event.pinned);
    final result = await _repository.updateQuestion(path, updated);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) => emit(state.copyWith(isSaving: false)),
    );
  }

  Future<void> _onAnswer(
      AnswerQuestionEvent event, Emitter<LiveRoomAdminState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final path = _roomPath;
    if (path == null) return;
    final updated = event.question.copyWith(
      isAnswered: true,
      answer: event.answer,
      answeredBy: 'Moderator',
    );
    final result = await _repository.updateQuestion(path, updated);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) => emit(state.copyWith(isSaving: false)),
    );
  }

  Future<void> _onRemoveAnswer(
      RemoveAnswerQuestionEvent event, Emitter<LiveRoomAdminState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final path = _roomPath;
    if (path == null) return;
    final q = event.question;
    final updated = Question(
      id: q.id,
      text: q.text,
      author: q.author,
      isAnonymous: q.isAnonymous,
      votes: q.votes,
      votedByUser: q.votedByUser,
      isPinned: q.isPinned,
      isAnswered: false,
      answer: null,
      answeredBy: null,
      createdAt: q.createdAt,
    );
    final result = await _repository.updateQuestion(path, updated);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) => emit(state.copyWith(isSaving: false)),
    );
  }

  Future<void> _onDelete(
      DeleteLiveQuestionEvent event, Emitter<LiveRoomAdminState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final path = _roomPath;
    if (path == null) return;
    final result = await _repository.deleteQuestion(path, event.id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) => emit(state.copyWith(isSaving: false)),
    );
  }

  Future<void> _onLowerHand(
      LowerHandEvent event, Emitter<LiveRoomAdminState> emit) async {
    final path = _roomPath;
    if (path == null) return;
    final result = await _repository.lowerHand(path, event.uid);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {},
    );
  }

  Future<void> _onClearHands(
      ClearRaisedHandsEvent event, Emitter<LiveRoomAdminState> emit) async {
    final path = _roomPath;
    if (path == null) return;
    final result = await _repository.clearRaisedHands(path);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {},
    );
  }

  Future<void> _onToggleRoomLive(
      ToggleRoomLiveEvent event, Emitter<LiveRoomAdminState> emit) async {
    final path = _sessionPath;
    final talkId = this.talkId;
    final current = state.session;
    if (path == null || current == null || talkId == null) return;

    // Reflect the new state immediately; the talks-array write follows.
    emit(state.copyWith(
      session: Map<String, dynamic>.from(current)
        ..['talks'] = _withTalkStatus(current['talks'], talkId, event.isLive),
    ));

    final roomId = current['id'] as String? ?? sessionId;
    final dayKey = path.split('/')[1];
    final result =
        await _repository.setTalkLive(dayKey, roomId, talkId, event.isLive,
            isManual: true);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        // Revert the optimistic live flag when the write failed so the
        // switch can't get stuck showing live while Firestore says off.
        session: current,
        error: failure.message,
      )),
      (_) {},
    );
  }

  /// Applies the live flag to one talk inside the session's talks array,
  /// mirroring the datasource rule: only the target talk's status changes, so
  /// the parallel talks in a session can each go live independently.
  static List<dynamic> _withTalkStatus(dynamic talks, String talkId, bool isLive) {
    final list = (talks as List?) ?? const [];
    return list.map((t) {
      final map = Map<String, dynamic>.from(t as Map);
      if (map['id'] == talkId) {
        map['status'] = isLive ? 'live' : 'completed';
      } else if (isLive && map['status'] == 'live') {
        map['status'] = 'completed';
      }
      return map;
    }).toList();
  }

  @override
  Future<void> close() {
    _questionsSub?.cancel();
    _handsSub?.cancel();
    return super.close();
  }
}
