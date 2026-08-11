import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
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
    return BlocProvider(
      create: (_) =>
          OverviewBloc(repository: sl())..add(const LoadOverviewEvent()),
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
                  onPressed: () =>
                      context.read<OverviewBloc>().add(const LoadOverviewEvent()),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _StatCard(
                    label: 'Congress Day',
                    value: '${config?.currentDay ?? '—'}',
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.highlight,
                  ),
                  _StatCard(
                    label: 'Announcements',
                    value: '${data.announcementCount}',
                    icon: Icons.campaign_outlined,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Workshops',
                    value: '${data.workshopCount}',
                    icon: Icons.school_outlined,
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    label: 'Agenda Items',
                    value: '${data.agendaItemCount}',
                    icon: Icons.event_note_outlined,
                    color: AppColors.pinnedGold,
                  ),
                  _StatCard(
                    label: 'Agenda Tracks',
                    value: '${data.agendaDayCount}',
                    icon: Icons.dashboard_outlined,
                    color: AppColors.answeredGreen,
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
                          const Text(
                            'Current Live Session',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.liveSessionTitle?.isNotEmpty == true
                                ? data.liveSessionTitle!
                                : 'No live session configured',
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                          if (config != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Live session id: ${config.liveSessionId.isEmpty ? '—' : config.liveSessionId}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Congress start: ${DateFormat.yMMMd().add_jm().format(config.congressStart)}',
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
                    if (data.liveRaisedHands > 0)
                      StatusBadge(
                        label: '${data.liveRaisedHands} hands raised',
                        color: AppColors.liveRedLight,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
