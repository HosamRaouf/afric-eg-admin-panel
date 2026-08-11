import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/hand_raise.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/question.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_room_admin_bloc.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_room_admin_event.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_room_admin_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LiveRoomAdminPage extends StatelessWidget {
  final String sessionId;
  final String? talkId;

  const LiveRoomAdminPage({super.key, required this.sessionId, this.talkId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveRoomAdminBloc(
        repository: sl(),
        sessionId: sessionId,
        talkId: talkId,
      )..add(const LoadLiveRoomAdminEvent()),
      child: _LiveRoomView(talkId: talkId),
    );
  }
}

/// Whether the scoped talk is live. With a `talkId` the live flag comes from
/// `talks[].status`; without one (legacy route) the session `isLive` flag is
/// used.
bool _talkIsLive(Map<String, dynamic>? session, String? talkId) {
  if (session == null) return false;
  if (talkId == null) return session['isLive'] == true;
  final talks = session['talks'];
  if (talks is List) {
    for (final t in talks) {
      if (t is Map && t['id'] == talkId) return t['status'] == 'live';
    }
  }
  return false;
}

/// Title of the scoped talk, or `null` when there is no talkId.
String? _talkTitle(Map<String, dynamic>? session, String? talkId) {
  if (session == null || talkId == null) return null;
  final talks = session['talks'];
  if (talks is List) {
    for (final t in talks) {
      if (t is Map && t['id'] == talkId) return t['title'] as String?;
    }
  }
  return null;
}

/// Formats a session `startTime`/`endTime` from the raw Firestore map, which
/// may be a `Timestamp` (new) or a legacy clock string like `'9:30'`.
String _formatSessionTime(dynamic value) {
  if (value is Timestamp) return DateFormat.jm().format(value.toDate());
  if (value is String && value.isNotEmpty) {
    final dt = DateTime.tryParse(value);
    if (dt != null) return DateFormat.jm().format(dt);
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match != null) {
      return DateFormat.jm().format(DateTime(
            2026,
            1,
            1,
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
          ));
    }
  }
  return '—';
}

class _LiveRoomView extends StatelessWidget {
  final String? talkId;

  const _LiveRoomView({this.talkId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveRoomAdminBloc, LiveRoomAdminState>(
      builder: (context, state) {
        final session = state.session;
        final hands = state.handRaises;
        final roomLive = _talkIsLive(session, talkId);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: session?['title'] as String? ?? 'Live Room',
                subtitle: session == null
                    ? 'Loading room details…'
                    : 'ID: ${session['id']} · ${_formatSessionTime(session['startTime'])} – ${_formatSessionTime(session['endTime'])}'
                        '${_talkTitle(session, talkId) == null ? '' : ' · Talk: ${_talkTitle(session, talkId)}'}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GhostIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    GlassButton(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () => context
                          .read<LiveRoomAdminBloc>()
                          .add(const LoadLiveRoomAdminEvent()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.sensors,
                        size: 18, color: AppColors.liveRedLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session == null
                                ? 'Loading room…'
                                : (session['title'] as String? ?? 'Live session'),
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                          if (session != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${session['id']} · ${_formatSessionTime(session['startTime'])} – ${_formatSessionTime(session['endTime'])}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Live',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: roomLive
                                ? AppColors.liveRedLight
                                : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Switch(
                          value: roomLive,
                          activeTrackColor: AppColors.liveRedLight,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: session == null || talkId == null
                              ? null
                              : (value) => context
                                  .read<LiveRoomAdminBloc>()
                                  .add(ToggleRoomLiveEvent(isLive: value)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    StatusBadge(
                      label: '✋ ${hands.length} raised',
                      color: AppColors.liveRedLight,
                    ),
                    const SizedBox(width: 10),
                    GhostIconButton(
                      icon: Icons.cleaning_services_outlined,
                      color: AppColors.liveRedLight,
                      onPressed: hands.isEmpty
                          ? null
                          : () => _confirmClearHands(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Mic Queue (${hands.length})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'raised hands in order',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hands.isEmpty)
                const GlassCard(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No hands raised yet.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: List.generate(hands.length, (i) {
                      final hand = hands[i];
                      return _HandRow(index: i + 1, hand: hand);
                    }),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Questions',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 12),
              if (state.isLoading && state.questions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.questions.isEmpty)
                const EmptyState(message: 'No questions yet.')
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: state.questions
                      .map((q) => _QuestionCard(
                            question: q,
                            onPin: () => context
                                .read<LiveRoomAdminBloc>()
                                .add(PinQuestionEvent(q, !q.isPinned)),
                            onAnswer: () => _openAnswerDialog(context, q),
                            onRemoveAnswer: () => context
                                .read<LiveRoomAdminBloc>()
                                .add(RemoveAnswerQuestionEvent(q)),
                            onDelete: () => _confirmDelete(context, q),
                          ))
                      .toList(),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.liveRed),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearHands(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Clear all raised hands?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<LiveRoomAdminBloc>()
                  .add(const ClearRaisedHandsEvent());
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.liveRed)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Question q) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Delete question?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
        content: Text(
          q.text,
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<LiveRoomAdminBloc>()
                  .add(DeleteLiveQuestionEvent(q.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.liveRed)),
          ),
        ],
      ),
    );
  }

  void _openAnswerDialog(BuildContext context, Question q) {
    final controller = TextEditingController(text: q.answer ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Answer question',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q.text,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: AppColors.textWhite),
              ),
              const SizedBox(height: 14),
              GlassTextField(
                label: 'Answer',
                controller: controller,
                hint: 'The moderator\'s answer…',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Post Answer',
            icon: Icons.check,
            onPressed: () {
              final answer = controller.text.trim();
              if (answer.isEmpty) return;
              context
                  .read<LiveRoomAdminBloc>()
                  .add(AnswerQuestionEvent(q, answer));
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }
}

class _HandRow extends StatelessWidget {
  final int index;
  final HandRaise hand;

  const _HandRow({required this.index, required this.hand});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.highlight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.back_hand_outlined,
              size: 15, color: AppColors.liveRedLight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hand.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Raised at ${DateFormat.Hms().format(hand.raisedAt)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          GlassButton(
            label: 'Put down',
            icon: Icons.arrow_downward,
            onPressed: () => context
                .read<LiveRoomAdminBloc>()
                .add(LowerHandEvent(hand.uid)),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onPin;
  final VoidCallback onAnswer;
  final VoidCallback onRemoveAnswer;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onPin,
    required this.onAnswer,
    required this.onRemoveAnswer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Center(
                    child: Text(
                      '${question.votes}',
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.highlight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.author,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm()
                            .format(question.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (question.isPinned)
                  const StatusBadge(label: 'PINNED', color: AppColors.pinnedGold),
                const SizedBox(width: 6),
                if (question.isAnswered)
                  const StatusBadge(label: 'ANSWERED', color: AppColors.answeredGreen),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.4,
                color: AppColors.textWhite,
              ),
            ),
            if (question.answer != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.answeredGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.answeredGreen.withValues(alpha: 0.25)),
                ),
                child: Text(
                  question.answer!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                GlassButton(
                  label: question.isAnswered ? 'Re-answer' : 'Answer',
                  icon: Icons.reply_outlined,
                  onPressed: onAnswer,
                ),
                const Spacer(),
                if (question.answer != null) ...[
                  GhostIconButton(
                    icon: Icons.remove_circle_outline,
                    color: AppColors.answeredGreen,
                    onPressed: onRemoveAnswer,
                  ),
                  const SizedBox(width: 8),
                ],
                GhostIconButton(
                  icon: question.isPinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  color: question.isPinned ? AppColors.pinnedGold : null,
                  onPressed: onPin,
                ),
                const SizedBox(width: 8),
                GhostIconButton(
                  icon: Icons.delete_outline,
                  color: AppColors.liveRedLight,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
