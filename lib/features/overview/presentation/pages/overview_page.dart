import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/services/talk_scheduler.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:afric_eg_admin_panel/features/overview/domain/entities/overview_data.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/bloc/overview_bloc.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/bloc/overview_event.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/bloc/overview_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<OverviewBloc>(),
      child: const _OverviewView(),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OverviewBloc, OverviewState>(
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        if (state.error != null && state.data == null) {
          return EmptyState(message: state.error!);
        }
        final data = state.data ?? const OverviewData();
        final config = data.config;
        final totalDays = config?.totalDays ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Overview',
                subtitle: 'Live status of the AFRIC 2026 congress app',
                trailing: GlassButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onPressed: () => context.read<OverviewBloc>().add(
                    const LoadOverviewEvent(force: true),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const _SectionTitle(
                title: 'Congress',
                icon: Icons.account_balance_outlined,
                color: AppColors.highlight,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _StatCard(
                    label: 'Congress Day',
                    value: '${config?.currentDay ?? '—'} / $totalDays',
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.highlight,
                  ),
                  _StatCard(
                    label: 'Day / Hall Tracks',
                    value: '${data.agendaTrackCount}',
                    icon: Icons.dashboard_outlined,
                    color: AppColors.answeredGreen,
                  ),
                  _StatCard(
                    label: 'Agenda Items',
                    value: '${data.agendaItemCount}',
                    icon: Icons.event_note_outlined,
                    color: AppColors.pinnedGold,
                  ),
                  _StatCard(
                    label: 'Talks',
                    value: '${data.talkCount}',
                    icon: Icons.mic_external_on_outlined,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Speakers',
                    value: '${data.speakerCount}',
                    icon: Icons.record_voice_over_outlined,
                    color: AppColors.goldLight,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _CongressInfoCard(config: config),

              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Content',
                icon: Icons.layers_outlined,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _StatCard(
                    label: 'Announcements',
                    value: '${data.announcementCount}',
                    icon: Icons.campaign_outlined,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Sponsors',
                    value: '${data.sponsorCount}',
                    icon: Icons.handshake_outlined,
                    color: AppColors.goldLight,
                  ),
                  _StatCard(
                    label: 'Committee Members',
                    value: '${data.committeeCount}',
                    icon: Icons.badge_outlined,
                    color: AppColors.textWhite,
                  ),
                  _StatCard(
                    label: 'Committee Sections',
                    value: '${data.committeeCategoryCount}',
                    icon: Icons.account_tree_outlined,
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'Workshops',
                    value: '${data.workshopCount}',
                    icon: Icons.school_outlined,
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'Workshop Sessions',
                    value: '${data.workshopSessionCount}',
                    icon: Icons.event_seat_outlined,
                    color: AppColors.pointsGreen,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'People',
                icon: Icons.people_alt_outlined,
                color: AppColors.accent,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _StatCard(
                    label: 'Total Users',
                    value: '${data.userCount}',
                    icon: Icons.people_outline,
                    color: AppColors.textWhite,
                  ),
                  _StatCard(
                    label: 'Attendees',
                    value: '${data.attendeeCount}',
                    icon: Icons.group_outlined,
                    color: AppColors.textSecondary,
                  ),
                  _StatCard(
                    label: 'Speakers',
                    value: '${data.speakerUserCount}',
                    icon: Icons.mic_outlined,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Faculty',
                    value: '${data.facultyCount}',
                    icon: Icons.person_pin_outlined,
                    color: AppColors.answeredGreen,
                  ),
                  _StatCard(
                    label: 'Sponsor Accounts',
                    value: '${data.sponsorUserCount}',
                    icon: Icons.handshake_outlined,
                    color: AppColors.goldLight,
                  ),
                  _StatCard(
                    label: 'Admins',
                    value: '${data.adminCount}',
                    icon: Icons.shield_outlined,
                    color: AppColors.liveRedLight,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Live',
                icon: Icons.sensors_outlined,
                color: AppColors.liveRedLight,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _SchedulerLeaderCard(),
                  _StatCard(
                    label: 'Live Talks',
                    value: '${data.liveTalkCount}',
                    icon: Icons.radio_outlined,
                    color: AppColors.liveRedLight,
                  ),
                  _StatCard(
                    label: 'Live Questions',
                    value: '${data.liveQuestionCount}',
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.textWhite,
                  ),
                  _StatCard(
                    label: 'Raised Hands',
                    value: '${data.liveRaisedHands}',
                    icon: Icons.back_hand_outlined,
                    color: AppColors.liveRedLight,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _LiveNowCard(data: data),
            ],
          ),
        );
      },
    );
  }
}

class _LiveNowCard extends StatelessWidget {
  final OverviewData data;

  const _LiveNowCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sensors,
                size: 18,
                color: AppColors.liveRedLight,
              ),
              const SizedBox(width: 12),
              const Text(
                'LIVE NOW',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              if (data.liveTalkCount > 0)
                StatusBadge(
                  label: '${data.liveTalkCount} on air',
                  color: AppColors.liveRedLight,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.liveTalks.isEmpty) ...[
            const Text(
              'Nothing is live right now',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 6),
            if (data.liveRaisedHands > 0)
              StatusBadge(
                label: '${data.liveRaisedHands} hands raised',
                color: AppColors.liveRedLight,
              ),
          ] else
            ...data.liveTalks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.liveRedLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.talkTitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                  const SizedBox(height: 2),
                  Text(
                            [
                              if (t.sessionTitle.isNotEmpty) t.sessionTitle,
                              if (t.hall.isNotEmpty) 'Hall ${t.hall}',
                            ].join(' · '),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if (t.speakers.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              t.speakers.join(', '),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${DateFormat.Hm().format(t.startTime)} – '
                      '${DateFormat.Hm().format(t.endTime)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.18,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _CongressInfoCard extends StatelessWidget {
  final CongressConfig? config;

  const _CongressInfoCard({this.config});

  @override
  Widget build(BuildContext context) {
    if (config == null) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 14,
      child: Wrap(
        spacing: 28,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InfoItem(
            icon: Icons.event_outlined,
            label: 'Congress start',
            value: DateFormat.yMMMd().add_jm().format(config!.congressStart),
          ),
          if (config!.venue.name.isNotEmpty)
            _InfoItem(
              icon: Icons.location_on_outlined,
              label: 'Venue',
              value: config!.venue.name,
            ),
          _InfoItem(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Program at a Glance',
            value: config!.programGlanceUrl.isNotEmpty ? 'Uploaded' : 'Not set',
            valueColor: config!.programGlanceUrl.isNotEmpty
                ? AppColors.answeredGreen
                : AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live-updating card showing whether this device is the scheduler leader.
class _SchedulerLeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheduler = sl<TalkScheduler>();
    return ValueListenableBuilder<bool>(
      valueListenable: scheduler.isLeaderNotifier,
      builder: (context, isLeader, _) {
        return GlassCard(
          padding: const EdgeInsets.all(16),
          radius: 16,
          child: SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isLeader ? Icons.shield : Icons.shield_outlined,
                  size: 18,
                  color: isLeader
                      ? AppColors.answeredGreen
                      : AppColors.textDisabled,
                ),
                const SizedBox(height: 12),
                Text(
                  isLeader ? 'LEADER' : 'PASSIVE',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isLeader
                        ? AppColors.answeredGreen
                        : AppColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Scheduler',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
