import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/live_room/domain/entities/room.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_bloc.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_event.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/bloc/live_rooms_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LiveRoomsPage extends StatelessWidget {
  const LiveRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<LiveRoomsBloc>(),
      child: const _LiveRoomsView(),
    );
  }
}

class _LiveRoomsView extends StatelessWidget {
  const _LiveRoomsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveRoomsBloc, LiveRoomsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Live Rooms',
                subtitle:
                    'Moderate Q&A and the mic queue across every session room',
                trailing: GlassButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () => context.read<LiveRoomsBloc>().add(
                    const LoadLiveRoomsEvent(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (state.isLoading && state.rooms.isEmpty)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.rooms.isEmpty)
                Expanded(
                  child: EmptyState(
                    message: state.error ?? 'No session rooms found.',
                  ),
                )
              else
                Expanded(child: _DayColumns(rooms: state.rooms)),
              if (state.error != null && state.rooms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.liveRed,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Two (or more) independently scrollable columns, one per agenda day,
/// with each day's rooms sorted by start time.
class _DayColumns extends StatelessWidget {
  final List<Room> rooms;

  const _DayColumns({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final days = rooms.map((r) => r.day).toSet().toList()..sort();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, day) in days.indexed) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DayHeader(day: day),
                  const SizedBox(height: 12),
                  for (final room
                      in rooms.where((r) => r.day == day).toList()
                        ..sort((a, b) => a.startTime.compareTo(b.startTime)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RoomCard(room: room),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int day;

  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 14, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          'Day $day',
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textWhite,
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  room.isLive ? Icons.sensors : Icons.sensors_outlined,
                  size: 18,
                  color: room.isLive
                      ? AppColors.liveRedLight
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    room.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
                if (room.isLive)
                  const StatusBadge(
                    label: 'LIVE',
                    color: AppColors.liveRedLight,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Day ${room.day} · Hall ${room.hall} · '
              '${DateFormat.jm().format(room.startTime)} – ${DateFormat.jm().format(room.endTime)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            if (room.talks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'No talks in this session.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              )
            else
              ...room.talks.map((talk) => _TalkRow(room: room, talk: talk)),
          ],
        ),
      ),
    );
  }
}

class _TalkRow extends StatelessWidget {
  final Room room;
  final Talk talk;

  const _TalkRow({required this.room, required this.talk});

  @override
  Widget build(BuildContext context) {
    final isLive = talk.status == 'live';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.liveRed.withValues(alpha: 0.12)
            : AppColors.glassBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive
              ? AppColors.liveRedLight.withValues(alpha: 0.5)
              : AppColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  talk.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isLive)
                const StatusBadge(label: 'LIVE', color: AppColors.liveRedLight),
              if (talk.status == 'completed')
                const StatusBadge(label: 'COMPLETED', color: AppColors.answeredGreen),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat.jm().format(talk.startTime)} – '
            '${DateFormat.jm().format(talk.endTime)}'
            '${talk.speakers.isEmpty ? '' : ' · ${talk.speakers.join(', ')}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GlassButton(
                label: isLive ? 'Stop' : 'Go Live',
                icon: isLive ? Icons.stop_circle_outlined : Icons.sensors,
                onPressed: () => context.read<LiveRoomsBloc>().add(
                  ToggleTalkLiveEvent(room: room, talk: talk, isLive: !isLive),
                ),
              ),
              _TalkStatusDropdown(room: room, talk: talk),
              GlassButton(
                label: 'Open Live Room',
                icon: Icons.arrow_forward,
                onPressed: () =>
                    context.push('/live-room/${room.id}/${talk.id}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact Upcoming/Completed selector for a talk. Live is controlled by the
/// dedicated Go Live/Stop button, so while a talk is on air the dropdown is
/// replaced by a non-interactive Live badge instead of an empty control.
class _TalkStatusDropdown extends StatelessWidget {
  final Room room;
  final Talk talk;

  const _TalkStatusDropdown({required this.room, required this.talk});

  @override
  Widget build(BuildContext context) {
    final isLive = talk.status == 'live';
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.liveRed.withValues(alpha: 0.12)
            : AppColors.glassBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive
              ? AppColors.liveRedLight.withValues(alpha: 0.5)
              : AppColors.glassBorder,
        ),
      ),
      child: isLive
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, size: 14, color: AppColors.liveRedLight),
                SizedBox(width: 6),
                Text(
                  'Live',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.liveRedLight,
                  ),
                ),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: talk.status == 'completed' ? 'completed' : 'upcoming',
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: const Color(0xFF2a0f10),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textWhite,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'upcoming',
                    child: Text('Upcoming'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null || value == talk.status) return;
                  context.read<LiveRoomsBloc>().add(
                        SetTalkStatusEvent(
                          room: room,
                          talk: talk,
                          status: value,
                        ),
                      );
                },
              ),
            ),
    );
  }
}
