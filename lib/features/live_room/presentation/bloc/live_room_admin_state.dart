import 'package:afric_eg_admin_panel/features/live_room/domain/entities/hand_raise.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:equatable/equatable.dart';

class LiveRoomAdminState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final Map<String, dynamic>? session;
  final List<Question> questions;
  final List<HandRaise> handRaises;
  final String? error;

  const LiveRoomAdminState({
    this.isLoading = false,
    this.isSaving = false,
    this.session,
    this.questions = const [],
    this.handRaises = const [],
    this.error,
  });

  LiveRoomAdminState copyWith({
    bool? isLoading,
    bool? isSaving,
    Map<String, dynamic>? session,
    List<Question>? questions,
    List<HandRaise>? handRaises,
    String? error,
  }) =>
      LiveRoomAdminState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        session: session ?? this.session,
        questions: questions ?? this.questions,
        handRaises: handRaises ?? this.handRaises,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [isLoading, isSaving, session, questions, handRaises, error];
}
